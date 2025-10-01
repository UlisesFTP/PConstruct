from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas, crud
from .database import SessionLocal, engine
from .estimators import gaming, engineering, ai
from .integrations import steam, blender, benchmark_sites
from .config import settings
import logging
import httpx

app = FastAPI(
    title="Benchmark Service",
    description="Microservicio para estimación y comparación de rendimiento de hardware",
    version="1.0.0"
)
logger = logging.getLogger("benchmark-service")

# Middleware CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Crear tablas al iniciar
@app.on_event("startup")
def startup():
    models.Base.metadata.create_all(bind=engine)
    logger.info("Database tables created")

# Dependencia de base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Endpoints
@app.post("/benchmark/estimate", response_model=schemas.BenchmarkResult)
async def estimate_performance(
    request: schemas.EstimateRequest,
    db: Session = Depends(get_db)
):
    """Estimar rendimiento para una configuración específica"""
    # Obtener detalles de los componentes
    component_details = await crud.get_component_details(
        request.component_ids, 
        settings.COMPONENT_SERVICE_URL
    )
    
    # Seleccionar estimador basado en el caso de uso
    estimator = _select_estimator(request.use_case)
    
    # Realizar la estimación
    result = estimator.estimate(component_details)
    
    # Guardar resultado en DB (opcional)
    crud.save_benchmark_result(db, request, result)
    
    return result

@app.get("/benchmark/compare", response_model=schemas.ComparisonResult)
async def compare_builds(
    build_ids: str,  # Lista de IDs separados por comas
    scenario: str,
    db: Session = Depends(get_db)
):
    """Comparar múltiples builds en un escenario específico"""
    build_id_list = [int(id) for id in build_ids.split(",")]
    
    results = []
    for build_id in build_id_list:
        # Obtener build del servicio de builds
        build = await crud.get_build_details(
            build_id, 
            settings.BUILD_SERVICE_URL
        )
        
        # Estimar rendimiento para el escenario
        estimator = _select_estimator(scenario)
        component_details = await crud.get_component_details(
            [comp["component_id"] for comp in build["components"]],
            settings.COMPONENT_SERVICE_URL
        )
        result = estimator.estimate(component_details)
        
        results.append({
            "build_id": build_id,
            "result": result
        })
    
    # Guardar comparación (opcional)
    crud.save_comparison_result(db, build_id_list, scenario, results)
    
    return {"scenario": scenario, "results": results}

@app.get("/benchmark/history/{build_id}", response_model=list[schemas.BenchmarkHistory])
def get_benchmark_history(build_id: int, db: Session = Depends(get_db)):
    """Obtener historial de benchmarks para una build"""
    return crud.get_benchmark_history(db, build_id)

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Helper functions
def _select_estimator(use_case: str):
    """Selecciona el módulo de estimación adecuado"""
    if use_case in ["gaming", "streaming"]:
        return gaming.GamingEstimator()
    elif use_case in ["engineering", "rendering"]:
        return engineering.EngineeringEstimator()
    elif use_case in ["ai", "machine_learning"]:
        return ai.AIEstimator()
    else:
        raise HTTPException(
            status_code=400, 
            detail=f"No estimator available for use case: {use_case}"
        )