from sqlalchemy.orm import Session, joinedload, aliased
from sqlalchemy.sql import func
from sqlalchemy import case, literal_column
from typing import List, Optional, Tuple
import math

# Importamos Modelos y Schemas
from app.models.component import Component
from app.models.offer import Offer
from app.models.review import Review
from app.schemas.component import ComponentCard, ComponentDetail
from app.schemas.common import PaginatedResponse

def get_component_by_id(db: Session, component_id: int) -> Optional[ComponentDetail]:
    """
    Obtiene el detalle completo de un componente por su ID.
    (Para la vista component_detail.dart)
    """
    
    # 1. Subconsulta para calcular el rating promedio y el conteo de reseñas
    review_stats = (
        db.query(
            Review.component_id,
            func.avg(Review.rating).label("average_rating"),
            func.count(Review.id).label("review_count")
        )
        .filter(Review.component_id == component_id)
        .group_by(Review.component_id)
        .subquery()
    )

    # 2. Consulta principal
    component = (
        db.query(Component, review_stats.c.average_rating, review_stats.c.review_count)
        .outerjoin(review_stats, Component.id == review_stats.c.component_id)
        .filter(Component.id == component_id)
        # Cargamos eficientemente las relaciones (hijos)
        .options(
            joinedload(Component.offers), # Cargar ofertas
            joinedload(Component.reviews) # Cargar reseñas
                .joinedload(Review.comments) # Cargar comentarios de reseñas
        )
        .first()
    )

    if not component:
        return None

    # 3. Mapeo al Schema 'ComponentDetail'
    component_data, avg_rating, review_count = component
    
    # --- ¡INICIO DE CORRECCIÓN! ---
    # Pydantic v2 no acepta un 2do argumento.
    # Creamos el modelo usando el unpacking de Python.
    component_detail = ComponentDetail(
        **component_data.__dict__,  # Pasa todos los atributos de la DB
        average_rating=avg_rating,  # Sobrescribe/Añade el rating
        review_count=review_count or 0 # Sobrescribe/Añade el conteo
    )
    # --- FIN DE CORRECCIÓN! ---
    
    return component_detail


def get_components_paginated(
    db: Session,
    page: int = 1,
    page_size: int = 20,
    category: Optional[str] = None,
    brand: Optional[str] = None,
    max_price: Optional[float] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = "price_asc"
) -> PaginatedResponse[ComponentCard]:
    """
    Obtiene una lista paginada de componentes con filtros.
    (Para la vista components_page.dart)
    """
    best_offer_subq = (
        db.query(
            Offer,
            func.row_number().over(
                partition_by=Offer.component_id,
                order_by=Offer.price.asc()
            ).label("rn")
        )
        .subquery("best_offer_subq")
    )
    
    # Luego, creamos el alias para la entidad Offer referenciando la subconsulta
    BestOffer = aliased(Offer, best_offer_subq)
    # --- FIN DE CORRECCIÓN! ---
    
    # 2. Consulta base
    query = (
        db.query(
            Component.id,
            Component.name,
            Component.category,
            Component.brand,
            Component.image_url,
            BestOffer.price, # Esto sigue funcionando
            BestOffer.store, # Esto sigue funcionando
            BestOffer.link   # Esto sigue funcionando
        )
        # --- ¡CORRECCIÓN EN EL JOIN! ---
        .outerjoin(
            BestOffer, # Unimos con el alias
            # Comparamos el ID del componente y el 'rn' de la subconsulta
            (Component.id == BestOffer.component_id) & (best_offer_subq.c.rn == 1)
        )
    )
    # 3. Aplicar Filtros (¡La lógica clave!)
    if category:
        query = query.filter(Component.category == category)
    if brand:
        query = query.filter(Component.brand == brand)
    if search:
        # Usamos la búsqueda de texto completo de PostgreSQL
        query = query.filter(Component.name.ilike(f"%{search}%"))
    if max_price:
        # Filtramos por el precio de la mejor oferta
        query = query.filter(BestOffer.price <= max_price)

    # 4. Conteo total (antes de paginar)
    total_items = query.count()

    # 5. Aplicar Ordenamiento
    if sort_by == "price_desc":
        query = query.order_by(BestOffer.price.desc().nullslast())
    else:
        # Por defecto (price_asc)
        query = query.order_by(BestOffer.price.asc().nullsfirst())

    # 6. Aplicar Paginación
    offset = (page - 1) * page_size
    query = query.limit(page_size).offset(offset)

    # 7. Ejecutar consulta y mapear a 'ComponentCard'
    results = query.all()
    
    # Mapeamos los resultados (que son tuplas) al schema ComponentCard
    items = [
        ComponentCard(
            id=row[0],
            name=row[1],
            category=row[2],
            brand=row[3],
            image_url=row[4],
            price=row[5],
            store=row[6],
            link=row[7]
        ) for row in results
    ]

    # 8. Devolver respuesta paginada
    return PaginatedResponse(
        total_items=total_items,
        page=page,
        page_size=page_size,
        items=items
    )