from sqlalchemy.orm import Session
from . import models, schemas
import httpx
import json

async def get_component_details(component_ids: List[int], service_url: str):
    """Obtener detalles de componentes desde el servicio de componentes"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{service_url}/components/details",
            json={"component_ids": component_ids}
        )
        return response.json()

async def get_build_details(build_id: int, service_url: str):
    """Obtener detalles de una build desde el servicio de builds"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{service_url}/builds/{build_id}")
        return response.json()

def save_benchmark_result(db: Session, request: schemas.EstimateRequest, result: schemas.BenchmarkResult):
    """Guardar resultado de benchmark en DB"""
    db_result = models.BenchmarkResult(
        build_id=0,  # En una implementación real, vendría de la request
        use_case=request.use_case,
        results=result.dict()
    )
    db.add(db_result)
    db.commit()
    db.refresh(db_result)
    return db_result

def save_comparison_result(db: Session, build_ids: List[int], scenario: str, results: list):
    """Guardar resultado de comparación en DB"""
    db_result = models.ComparisonResult(
        build_ids=build_ids,
        scenario=scenario,
        results=results
    )
    db.add(db_result)
    db.commit()
    db.refresh(db_result)
    return db_result

def get_benchmark_history(db: Session, build_id: int):
    """Obtener historial de benchmarks para una build"""
    return db.query(models.BenchmarkResult).filter(
        models.BenchmarkResult.build_id == build_id
    ).order_by(models.BenchmarkResult.created_at.desc()).all()