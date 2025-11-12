# services/builds/app/crud.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from . import models, schemas
import uuid
from typing import List, Optional

# --- Helper para mapear a BuildSummary ---
def _map_to_summary(build: models.Build) -> schemas.BuildSummary:
    cpu_name = next((c.name for c in build.components if c.category == 'cpu'), None)
    gpu_name = next((c.name for c in build.components if c.category == 'gpu'), None)
    ram_name = next((c.name for c in build.components if c.category == 'ram'), None)
    
    return schemas.BuildSummary(
        id=build.id,
        name=build.name,
        image_url=build.image_url,
        user_name=build.user_name,
        total_price=build.total_price,
        created_at=build.created_at,
        is_public=build.is_public,
        cpu_name=cpu_name,
        gpu_name=gpu_name,
        ram_name=ram_name,
    )

# --- Funciones CRUD Asíncronas ---

async def create_build(db: AsyncSession, build: schemas.BuildCreate, user_id: str, user_name: str) -> models.Build:
    total_price = sum(comp.price_at_build_time for comp in build.components)

    db_build = models.Build(
        name=build.name,
        description=build.description,
        use_type=build.use_type,
        image_url=build.image_url,
        is_public=build.is_public,
        total_price=total_price,
        user_id=user_id,
        user_name=user_name
    )
    
    db.add(db_build)
    await db.flush() # await

    for comp in build.components:
        db_comp = models.BuildComponent(
            build_id=db_build.id,
            component_id=comp.component_id,
            category=comp.category,
            name=comp.name,
            image_url=comp.image_url,
            price_at_build_time=comp.price_at_build_time
        )
        db.add(db_comp)
    
    await db.commit() # await
    await db.refresh(db_build) # await
    
    # Recargar componentes para la respuesta
    await db.refresh(db_build, attribute_names=['components'])
    
    return db_build

async def get_build_by_id(db: AsyncSession, build_id: uuid.UUID) -> Optional[models.Build]:
    query = (
        select(models.Build)
        .where(models.Build.id == build_id)
        .options(joinedload(models.Build.components)) # Carga ansiosa de componentes
    )
    result = await db.execute(query)
    return result.scalars().first()

async def get_user_builds(db: AsyncSession, user_id: str) -> List[schemas.BuildSummary]:
    query = (
        select(models.Build)
        .where(models.Build.user_id == user_id)
        .order_by(models.Build.created_at.desc())
        .options(joinedload(models.Build.components))
    )
    result = await db.execute(query)
    builds = result.scalars().unique().all()
    
    # Mapear a la respuesta de resumen
    return [_map_to_summary(b) for b in builds]

async def get_community_builds(db: AsyncSession, skip: int = 0, limit: int = 20) -> List[schemas.BuildSummary]:
    query = (
        select(models.Build)
        .where(models.Build.is_public == True)
        .order_by(models.Build.created_at.desc())
        .offset(skip)
        .limit(limit)
        .options(joinedload(models.Build.components))
    )
    result = await db.execute(query)
    builds = result.scalars().unique().all()

    # Mapear a la respuesta de resumen
    return [_map_to_summary(b) for b in builds]

async def delete_build(db: AsyncSession, build_id: uuid.UUID, user_id: str) -> Optional[models.Build]:
    db_build = await get_build_by_id(db, build_id) # Reutiliza la función
    if not db_build:
        return None
    
    # Comprobar propiedad
    if db_build.user_id != user_id:
        return None # O lanzar HTTPException 403 (Forbidden)

    await db.delete(db_build)
    await db.commit()
    return db_build