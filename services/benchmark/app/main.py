# app/main.py
from fastapi import FastAPI, Depends, HTTPException, status, Query, Body
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from pydantic import BaseModel
import os

from .database import get_db, init_db
from . import crud, schemas
from .estimator import fetch_scores_for_components, classify_for_software

BUILD_SERVICE_URL = os.getenv("BUILDS_SERVICE_URL", "http://build-service:8004")

app = FastAPI(
    title="Benchmark Service",
    description="Servicio de estimación de rendimiento para builds",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # ajusta en prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    await init_db()

@app.get("/health")
async def health():
    return {"status": "ok", "service": "benchmark-service"}

# -----------------------
# Compare endpoints (GET/POST)
# -----------------------

class CompareRequest(BaseModel):
    build_ids: List[int]
    scenario: Optional[str] = None

def _parse_ids(build_ids_list: Optional[List[int]], build_ids_csv: Optional[str]) -> List[int]:
    if build_ids_list:
        return build_ids_list
    if build_ids_csv:
        return [int(x) for x in build_ids_csv.split(",") if x.strip()]
    return []

@app.get("/benchmark/compare")
async def compare_builds_get(
    build_ids: Optional[List[int]] = Query(None),                 # /benchmark/compare?build_ids=1&build_ids=2
    build_ids_csv: Optional[str] = Query(None, alias="build_ids"),# /benchmark/compare?build_ids=1,2
    scenario: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    ids = _parse_ids(build_ids, build_ids_csv)
    if not ids:
        raise HTTPException(status_code=422, detail="Proporciona build_ids en query (lista o CSV)")
    return await crud.compare_builds(db, ids, scenario)

@app.post("/benchmark/compare")
async def compare_builds_post(
    body: CompareRequest = Body(...),
    db: AsyncSession = Depends(get_db),
):
    if not body.build_ids:
        raise HTTPException(status_code=422, detail="build_ids requerido en el body")
    return await crud.compare_builds(db, body.build_ids, body.scenario)

# -----------------------
# Estimate endpoint
# -----------------------

@app.post("/benchmark/estimate", response_model=schemas.EstimateRequest)
async def estimate_performance(
    req: schemas.EstimateRequest,
    db: AsyncSession = Depends(get_db),
):
    # 1) Resolver component_ids
    if req.component_ids:
        component_ids = req.component_ids
    elif req.build_id is not None:
        component_ids = await crud.resolve_component_ids_from_build(req.build_id)
        if not component_ids:
            raise HTTPException(status_code=404, detail="Build sin componentes o no encontrada")
    else:
        raise HTTPException(status_code=422, detail="Debes enviar component_ids o build_id")

    # 2) Obtener scores por componente (CSV/Kaggle y fallback Gemini si lo habilitaste)
    component_scores = await fetch_scores_for_components(component_ids)

    # 3) Cargar requerimientos de software y clasificar
    software_list = await crud.get_all_software_requirements(db)
    summary = classify_for_software(component_scores, software_list)

    # 4) Responder
    return schemas.EstimateResponse(
        component_scores=component_scores,
        software_summary=summary
    )
