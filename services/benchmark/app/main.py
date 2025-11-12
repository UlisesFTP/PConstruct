# app/main.py
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from .database import get_db, init_db
from . import crud, schemas
import os
# Eliminamos imports que ya no usamos para la estimación
from .score_loader import get_store 
from . import schemas
# Importamos la nueva función de gemini_client
from .estimator import fetch_components_metadata # Todavía la usamos para resolver builds
from .gemini_client import get_gemini_benchmark_analysis # ¡NUEVO!


BUILD_SERVICE_URL = os.getenv("BUILDS_SERVICE_URL", "http://build-service:8004")

app = FastAPI(title="Benchmark Service", version="0.1.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

@app.on_event("startup")
async def startup():
    await init_db()
    # Mantenemos get_store() por si la ruta /compare u otras la usan
    # O si queremos reactivarla en el futuro.
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


# --- RUTA /estimate MODIFICADA ---
@app.post("/benchmark/estimate", response_model=schemas.EstimateResponse)
async def estimate_performance(req: schemas.EstimateRequest, db: AsyncSession = Depends(get_db)):
    cpu_model = req.cpu_model
    gpu_model = req.gpu_model
    cpu_id = None
    gpu_id = None

    components_list = [] # Para la respuesta final

    if req.component_ids:
        meta = await fetch_components_metadata(req.component_ids, req.hints or {})
        for m in meta:
            t = (m.get("type") or "").lower()
            if t == "cpu" and not cpu_model:
                cpu_model, cpu_id = m.get("model"), m.get("id")
            elif t == "gpu" and not gpu_model:
                gpu_model, gpu_id = m.get("model"), m.get("id")
    elif req.build_id is not None:
        comp_ids = await crud.resolve_component_ids_from_build(req.build_id)
        if not comp_ids:
            raise HTTPException(status_code=404, detail="Build sin componentes o no encontrada")
        meta = await fetch_components_metadata(comp_ids, req.hints or {})
        for m in meta:
            t = (m.get("type") or "").lower()
            if t == "cpu" and not cpu_model:
                cpu_model, cpu_id = m.get("model"), m.get("id")
            elif t == "gpu" and not gpu_model:
                gpu_model, gpu_id = m.get("model"), m.get("id")
    elif not (cpu_model or gpu_model):
        raise HTTPException(status_code=422, detail="Debes enviar component_ids, build_id o cpu_model/gpu_model")

    # --- LÓGICA DE ESTIMACIÓN REEMPLAZADA ---
    # Ya no llamamos a fetch_scores_for_components, classify_for_software, etc.
    
    # 1. Llamamos a nuestra nueva función maestra de Gemini
    gemini_analysis = await get_gemini_benchmark_analysis(cpu_model, gpu_model, req.scenario)

    # 2. Construimos la lista de componentes para la respuesta
    # (aunque Gemini hizo el trabajo, es bueno devolver los componentes que se usaron)
    if cpu_model:
        components_list.append(schemas.ComponentResult(
            id=cpu_id or 0, 
            type="cpu", 
            model=cpu_model, 
            score=None, # Ya no tenemos score local
            source="gemini"
        ))
    if gpu_model:
        components_list.append(schemas.ComponentResult(
            id=gpu_id or 0, 
            type="gpu", 
            model=gpu_model, 
            score=None, # Ya no tenemos score local
            source="gemini"
        ))

    # 3. Devolvemos la respuesta
    return schemas.EstimateResponse(
        method="gemini", # ¡NUEVO!
        components=components_list,
        scores_used={}, # Ya no aplica
        scenario=req.scenario,
        classification=gemini_analysis.get("performance_fps", {}), # Datos para la gráfica
        gemini_reco=gemini_analysis.get("recommendation_text"),      # Texto de recomendación
    )