from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas, crud, algorithms
from .database import SessionLocal, engine
from .dependencies import get_component_service, get_pricing_service, get_benchmark_service
from .config import settings
import logging
import httpx

# Configuración inicial
app = FastAPI(
    title="Build Service",
    description="Microservicio para gestión de builds y generación de recomendaciones",
    version="1.0.0"
)
logger = logging.getLogger("build-service")

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
@app.post("/builds/generate", response_model=schemas.Build)
async def generate_build(
    build_request: schemas.BuildRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    component_service: str = Depends(get_component_service),
    pricing_service: str = Depends(get_pricing_service),
    benchmark_service: str = Depends(get_benchmark_service)
):
    """Generar una nueva build recomendada"""
    # Generar la build usando el algoritmo
    build = await algorithms.build_generator.generate_build(
        db=db,
        build_request=build_request,
        component_service_url=component_service,
        pricing_service_url=pricing_service,
        benchmark_service_url=benchmark_service
    )
    
    # Guardar la build en segundo plano
    background_tasks.add_task(
        crud.save_generated_build,
        db=db,
        build_data=build.dict(),
        user_id=build_request.user_id
    )
    
    return build

@app.post("/builds/save", response_model=schemas.Build)
def save_build(
    build: schemas.BuildCreate,
    db: Session = Depends(get_db)
):
    """Guardar una build personalizada"""
    return crud.save_custom_build(db=db, build=build)

@app.get("/builds/user/{user_id}", response_model=list[schemas.Build])
def get_user_builds(user_id: int, db: Session = Depends(get_db)):
    """Obtener builds de un usuario"""
    return crud.get_user_builds(db, user_id=user_id)

@app.get("/builds/{build_id}", response_model=schemas.Build)
def get_build(build_id: int, db: Session = Depends(get_db)):
    """Obtener detalles de una build específica"""
    build = crud.get_build(db, build_id=build_id)
    if not build:
        raise HTTPException(status_code=404, detail="Build not found")
    return build

@app.post("/builds/optimize", response_model=schemas.Build)
async def optimize_build(
    optimization_request: schemas.OptimizationRequest,
    db: Session = Depends(get_db),
    component_service: str = Depends(get_component_service),
    pricing_service: str = Depends(get_pricing_service)
):
    """Optimizar una build existente"""
    return await algorithms.optimizer.optimize_build(
        db=db,
        optimization_request=optimization_request,
        component_service_url=component_service,
        pricing_service_url=pricing_service
    )

@app.get("/builds/recommendations", response_model=list[schemas.Build])
async def get_recommendations(
    user_id: int,
    db: Session = Depends(get_db),
    component_service: str = Depends(get_component_service)
):
    """Obtener builds recomendadas basadas en preferencias"""
    return await algorithms.build_generator.get_recommendations(
        db=db,
        user_id=user_id,
        component_service_url=component_service
    )

@app.get("/health")
def health_check():
    return {"status": "healthy"}