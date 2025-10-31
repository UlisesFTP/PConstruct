# PConstruct/services/components/app/crud.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, distinct
from sqlalchemy.orm import joinedload # <-- Importa joinedload
from . import models, schemas
from typing import List, Optional

async def create_component(db: AsyncSession, component: schemas.ComponentCreate):
    # Asume que ComponentCreate incluye manufacturer_id
    db_component = models.Component(**component.model_dump(exclude_unset=True))
    db.add(db_component)
    await db.commit()
    await db.refresh(db_component)
    return db_component

async def get_component(db: AsyncSession, component_id: int) -> Optional[models.Component]:
    # Cargar la relación 'manufacturer' al mismo tiempo
    stmt = select(models.Component).options(
        joinedload(models.Component.manufacturer)
    ).where(models.Component.component_id == component_id) # Filtra por component_id
    result = await db.execute(stmt)
    return result.scalars().first()

async def get_components(
    db: AsyncSession,
    category: str = None,
    manufacturer: str = None, # 'manufacturer' es ahora un nombre (string)
    skip: int = 0,
    limit: int = 100
) -> List[models.Component]:
    
    # Cargar siempre la relación 'manufacturer'
    stmt = select(models.Component).options(
        joinedload(models.Component.manufacturer)
    ).order_by(models.Component.component_id) # Usa component_id de tu modelo

    if category:
        try:
            category_enum = models.ComponentCategory(category) 
            stmt = stmt.where(models.Component.category == category_enum)
        except ValueError:
             return [] # Si la categoría no es un Enum válido, no devuelve nada
    
    # --- CORRECCIÓN DE FILTRO POR FABRICANTE ---
    if manufacturer:
        # Añadir un JOIN a la tabla manufacturers y filtrar por nombre
        stmt = stmt.join(models.Manufacturer).where(models.Manufacturer.name.ilike(f"%{manufacturer}%"))
    # -------------------------------------------

    stmt = stmt.offset(skip).limit(limit)

    result = await db.execute(stmt)
    # .unique() es importante cuando se usa joinedload para evitar duplicados
    return result.scalars().unique().all()

async def get_categories(db: AsyncSession) -> List[str]:
    stmt = select(models.Component.category).distinct().order_by(models.Component.category)
    result = await db.execute(stmt)
    # Convierte el Enum a su valor string para la respuesta JSON
    return [category.value for category, in result.all()]

async def get_manufacturers(db: AsyncSession, category: str = None) -> List[str]:
    # Ahora consultamos la tabla Manufacturers
    stmt = select(models.Manufacturer.name).distinct().order_by(models.Manufacturer.name)
    
    if category:
        try:
            category_enum = models.ComponentCategory(category)
            # Necesitamos hacer join con Component para filtrar por categoría
            stmt = stmt.join(models.Component).where(models.Component.category == category_enum)
        except ValueError:
            return [] # Categoría no válida
            
    result = await db.execute(stmt)
    return [name for name, in result.all()]