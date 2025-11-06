# app/main.py
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from .database import get_db, init_db
from . import crud, schemas
from .estimator import fetch_components_metadata, attach_scores, classify_for_software, personalized_reco
import os
from .score_loader import get_store
from . import schemas


BUILD_SERVICE_URL = os.getenv("BUILDS_SERVICE_URL", "http://build-service:8004")

app = FastAPI(title="Benchmark Service", version="0.1.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

@app.on_event("startup")
async def startup():
    await init_db()
    get_store()

@app.get("/health")
async def health():
    return {"status": "ok", "service": "benchmark-service"}

@app.get("/benchmark/compare")
async def compare_builds(build_ids: str, scenario: Optional[str] = None, db: AsyncSession = Depends(get_db)):
    ids = [int(x) for x in build_ids.split(",") if x.strip()]
    return await crud.compare_builds(db, ids, scenario)

@app.post("/benchmark/compare")
async def compare_builds_post(body: schemas.CompareRequest, db: AsyncSession = Depends(get_db)):
    return await crud.compare_builds(db, body.build_ids, body.scenario)

@app.post("/benchmark/estimate", response_model=schemas.EstimateResponse)
async def estimate_performance(req: schemas.EstimateRequest, db: AsyncSession = Depends(get_db)):
    if req.component_ids:
        meta = await fetch_components_metadata(req.component_ids, req.hints or {})
    elif req.build_id is not None:
        comp_ids = await crud.resolve_component_ids_from_build(req.build_id)
        if not comp_ids:
            raise HTTPException(status_code=404, detail="Build sin componentes o no encontrada")
        meta = await fetch_components_metadata(comp_ids, req.hints or {})
    else:
        raise HTTPException(status_code=422, detail="Debes enviar component_ids o build_id")

    meta, used = attach_scores(meta)
    classif = classify_for_software(meta, req.scenario)
    reco = await personalized_reco(classif)
 # Decide el método: si hay fps numérico => "interpolation"; si solo tier => "tier"; si no hubo datos y entraste a Gemini => "fallback".
    method = "interpolation" if isinstance(classif.get("estimated_fps"), (int, float)) else (
        "tier" if classif.get("tier") else "fallback"
    )

    return schemas.EstimateResponse(
        method=method,                      # <- ahora sí lo enviamos
        components=[schemas.ComponentResult(**{
            "id": m["id"],
            "type": m["type"],
            "model": m["model"],
            "score": m.get("score"),
            "source": m.get("score_source"),
        }) for m in meta],
        scores_used=used,
        scenario=req.scenario,
        classification=classif,
        gemini_reco=reco,
    )
