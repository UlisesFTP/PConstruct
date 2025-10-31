# PConstruct/services/components/app/main.py

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from contextlib import asynccontextmanager
from typing import List
from . import models, schemas, crud, compatibility
from .database import get_db, engine
from .config import settings # <-- ASEGÚRATE DE IMPORTAR SETTINGS
import logging

logger = logging.getLogger("component-service")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Código que se ejecuta ANTES de que la aplicación inicie (startup)
    logger.info("Service starting up...")
    logger.info("Connecting to database and creating tables...")
    try:
        async with engine.begin() as conn:
            # Crea las tablas (basado en models.py)
            await conn.run_sync(models.Base.metadata.create_all)
        logger.info("Database tables verified/created (if not exist).")

        # === CORRECCIÓN AQUÍ ===
        # Usar 'settings' importado de .config, no la función 'get_db'
        if settings.LOAD_INITIAL_DATA:
        # =======================
            logger.info("LOAD_INITIAL_DATA=true. (Carga de datos iniciales omitida por ahora, necesita adaptación async)")
            # from .data import initial_data
            # async with AsyncSessionLocal() as db_session:
            #     await initial_data.load_initial_data(db_session)
    
    except Exception as e:
        logger.error(f"FATAL: Error during startup lifespan (database connection or table creation): {e}", exc_info=True)
        raise # Si la DB falla, el servicio no debe arrancar

    yield # <-- La aplicación se ejecuta aquí

    # Código que se ejecuta DESPUÉS de que la aplicación termine (shutdown)
    logger.info("Service shutting down...")

# --- Configuración inicial de la app CON lifespan ---
app = FastAPI(
    title="Component Service",
    description="Microservicio para gestión de componentes y compatibilidad",
    version="1.0.0",
    lifespan=lifespan
)

# ... (Middleware CORS y todos tus Endpoints sin cambios) ...

# (Middleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# (Endpoints: /components/, /components/{id}, /categories/, /manufacturers/, /compatibility/check, /health)
# ... (Tu código de endpoints va aquí) ...

@app.post("/components/", response_model=schemas.Component)
async def create_component(
    component: schemas.ComponentCreate,
    db: AsyncSession = Depends(get_db)
):
    return await crud.create_component(db=db, component=component)

@app.get("/components/", response_model=List[schemas.Component])
async def read_components(
    category: str = None,
    manufacturer: str = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    return await crud.get_components(
        db,
        category=category,
        manufacturer=manufacturer,
        skip=skip,
        limit=limit
    )

@app.get("/components/{component_id}", response_model=schemas.Component)
async def read_component(
    component_id: int,
    db: AsyncSession = Depends(get_db)
):
    component = await crud.get_component(db, component_id=component_id)
    if not component:
        raise HTTPException(status_code=404, detail="Component not found")
    return component

@app.get("/categories/", response_model=List[str])
async def get_categories(db: AsyncSession = Depends(get_db)):
    return await crud.get_categories(db)

@app.get("/manufacturers/", response_model=List[str])
async def get_manufacturers(
    category: str = None,
    db: AsyncSession = Depends(get_db)
):
    return await crud.get_manufacturers(db, category=category)

@app.post("/compatibility/check", response_model=schemas.CompatibilityResult)
async def check_compatibility(
    request: schemas.CompatibilityCheckRequest,
    db: AsyncSession = Depends(get_db)
):
    components = []
    for comp_id in request.component_ids:
        component = await crud.get_component(db, component_id=comp_id)
        if not component:
            raise HTTPException(status_code=404, detail=f"Component ID {comp_id} not found")
        components.append(component)
    
    return compatibility.check_compatibility(components)

@app.get("/compatibility/rules", response_model=List[schemas.CompatibilityRule])
def get_compatibility_rules():
    return compatibility.get_all_rules()

@app.get("/health")
def health_check():
    return {"status": "healthy"}