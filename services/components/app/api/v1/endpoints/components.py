from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
import json # <-- ¡Añadir import!

from app.db.session import get_db
from app.schemas.component import ComponentCard, ComponentDetail
from app.schemas.common import PaginatedResponse
from app.crud import crud_component
# --- ¡Nuevas importaciones de caché! ---
from app.services.cache_service import get_cache, set_cache

router = APIRouter()

@router.get(
    "/",
    response_model=PaginatedResponse[ComponentCard],
    summary="Obtener lista de componentes con filtros"
)
async def get_component_list(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1, description="Número de página"),
    page_size: int = Query(20, ge=1, le=100, description="Tamaño de página"),
    category: Optional[str] = Query(None, description="Filtrar por categoría (ej: CPU)"),
    brand: Optional[str] = Query(None, description="Filtrar por marca (ej: Intel)"),
    max_price: Optional[float] = Query(None, ge=0, description="Precio máximo"),
    search: Optional[str] = Query(None, description="Término de búsqueda (ej: Core i5)"),
    sort_by: Optional[str] = Query("price_asc", description="Orden (price_asc o price_desc)")
):
    """
    Endpoint para `components_page.dart`.
    Devuelve una lista paginada de componentes con filtros.
    (AHORA CON CACHÉ)
    """
    
    # --- Lógica de Caché (Lectura) ---
    cache_key = f"components:page={page}:size={page_size}:cat={category}:brand={brand}:max_p={max_price}:search={search}:sort={sort_by}"
    cached_data = await get_cache(cache_key)
    if cached_data:
        # Si está en caché, lo devolvemos (Pydantic lo re-validará)
        return PaginatedResponse[ComponentCard](**cached_data)

    # --- Lógica de Negocio (Si no está en caché) ---
    paginated_result = crud_component.get_components_paginated(
        db=db,
        page=page,
        page_size=page_size,
        category=category,
        brand=brand,
        max_price=max_price,
        search=search,
        sort_by=sort_by
    )
    
    # --- Lógica de Caché (Escritura) ---
    if paginated_result.items:
        # Guardamos en caché por 1 hora (3600 seg)
        await set_cache(cache_key, paginated_result, expiration_seconds=3600) 

    return paginated_result


@router.get(
    "/{component_id}",
    response_model=ComponentDetail,
    summary="Obtener detalle de un componente"
)
async def get_component_detail(
    component_id: int,
    db: Session = Depends(get_db)
):
    """
    Endpoint para `component_detail.dart`.
    Devuelve la información completa de un solo componente.
    (AHORA CON CACHÉ)
    """
    
    # --- Lógica de Caché (Lectura) ---
    cache_key = f"component_detail:{component_id}"
    cached_data = await get_cache(cache_key)
    if cached_data:
        # Si está en caché, lo devolvemos (Pydantic lo re-validará)
        return ComponentDetail(**cached_data)

    # --- Lógica de Negocio (Si no está en caché) ---
    component = crud_component.get_component_by_id(db=db, component_id=component_id)
    
    if not component:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Componente no encontrado"
        )
    
    # --- Lógica de Caché (Escritura) ---
    # Guardamos en caché por 1 hora (3600 seg)
    await set_cache(cache_key, component, expiration_seconds=3600)

    return component