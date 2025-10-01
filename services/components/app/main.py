from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas, crud, compatibility
from .database import SessionLocal, engine
from .config import settings
import logging

# Configuración inicial
app = FastAPI(
    title="Component Service",
    description="Microservicio para gestión de componentes y compatibilidad",
    version="1.0.0"
)
logger = logging.getLogger("component-service")

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
    
    # Cargar datos iniciales
    if settings.LOAD_INITIAL_DATA:
        from .data import initial_data
        db = SessionLocal()
        initial_data.load_initial_data(db)
        db.close()
        logger.info("Initial data loaded")

# Dependencia de base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Endpoints
@app.post("/components/", response_model=schemas.Component)
def create_component(component: schemas.ComponentCreate, db: Session = Depends(get_db)):
    return crud.create_component(db=db, component=component)

@app.get("/components/", response_model=list[schemas.Component])
def read_components(
    category: str = None,
    manufacturer: str = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    return crud.get_components(
        db, 
        category=category,
        manufacturer=manufacturer,
        skip=skip, 
        limit=limit
    )

@app.get("/components/{component_id}", response_model=schemas.Component)
def read_component(component_id: int, db: Session = Depends(get_db)):
    component = crud.get_component(db, component_id=component_id)
    if not component:
        raise HTTPException(status_code=404, detail="Component not found")
    return component

@app.get("/categories/", response_model=list[str])
def get_categories(db: Session = Depends(get_db)):
    return crud.get_categories(db)

@app.get("/manufacturers/", response_model=list[str])
def get_manufacturers(category: str = None, db: Session = Depends(get_db)):
    return crud.get_manufacturers(db, category=category)

@app.post("/compatibility/check", response_model=schemas.CompatibilityResult)
def check_compatibility(
    request: schemas.CompatibilityCheckRequest, 
    db: Session = Depends(get_db)
):
    components = []
    for comp_id in request.component_ids:
        component = crud.get_component(db, component_id=comp_id)
        if not component:
            raise HTTPException(status_code=404, detail=f"Component ID {comp_id} not found")
        components.append(component)
    
    return compatibility.check_compatibility(components)

@app.get("/compatibility/rules", response_model=list[schemas.CompatibilityRule])
def get_compatibility_rules():
    return compatibility.get_all_rules()

@app.get("/health")
def health_check():
    return {"status": "healthy"}