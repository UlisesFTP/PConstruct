from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from .database import get_db, init_db
from . import crud, schemas
from .estimator import fetch_scores_for_components, classify_for_software

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

@app.post(
    "/benchmark/estimate",
    response_model=schemas.BenchmarkEstimateResponse,
    status_code=status.HTTP_200_OK,
)
async def estimate_performance(
    req: schemas.BenchmarkEstimateRequest,
    db: AsyncSession = Depends(get_db),
):
    if not req.component_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="component_ids no puede estar vacío"
        )

    cpu_score, gpu_score = await fetch_scores_for_components(req.component_ids)

    software_list = await crud.get_all_software_requirements(db)

    results = [
        classify_for_software(cpu_score, gpu_score, sw)
        for sw in software_list
    ]

    return schemas.BenchmarkEstimateResponse(results=results)
