from sqlalchemy.orm import Session
from sqlalchemy.dialects.postgresql import insert
from app.models.component import Component
from app.models.offer import Offer
from app.schemas.component import ComponentCreate
from app.schemas.offer import OfferCreate
from datetime import datetime

def upsert_component(db: Session, component_in: ComponentCreate) -> Component:
    """
    Inserta un componente si no existe (basado en 'name', 'brand', 'category').
    Si existe, no hace nada y devuelve el componente existente.
    """
    
    # --- ¡INICIO DE CORRECCIÓN! ---
    # Convertir HttpUrl a string ANTES de dárselo a SQLAlchemy
    values_to_insert = component_in.dict()
    if values_to_insert.get('image_url'):
        values_to_insert['image_url'] = str(values_to_insert['image_url'])
    # --- FIN DE CORRECCIÓN! ---

    stmt = (
        insert(Component)
        .values(**values_to_insert) # Usar el dict corregido
        .on_conflict_do_nothing(
            index_elements=['name', 'brand', 'category']
        )
        .returning(Component.id)
    )
    
    result = db.execute(stmt).fetchone()
    
    if result:
        # Se insertó un nuevo componente
        component_id = result.id
        db.commit()
        return db.query(Component).filter(Component.id == component_id).first()
    else:
        # El componente ya existía, lo buscamos
        db.rollback() # Revertimos la transacción fallida
        
        # --- ¡INICIO DE CORRECCIÓN! ---
        # Buscamos solo por las claves únicas, que es más eficiente
        return db.query(Component).filter_by(
            name=component_in.name,
            brand=component_in.brand,
            category=component_in.category
        ).first()
        # --- FIN DE CORRECCIÓN! ---

def upsert_offer(db: Session, component_id: int, offer_in: OfferCreate) -> Offer:
    """
    Inserta una oferta. Si ya existe (mismo component_id y store),
    actualiza el 'price', 'link' y 'last_updated'.
    """
    
    # --- ¡INICIO DE CORRECCIÓN! ---
    # Preparamos los datos para el 'upsert'
    offer_data = offer_in.dict()
    
    # Convertir HttpUrl a string
    link_str = str(offer_data.get('link')) 
    
    offer_data['component_id'] = component_id
    offer_data['last_updated'] = datetime.utcnow()
    offer_data['link'] = link_str # Reemplazar HttpUrl con str
    # --- FIN DE CORRECCIÓN! ---

    stmt = (
        insert(Offer)
        .values(**offer_data) # Ahora 'link' es un str
        .on_conflict_do_update(
            index_elements=['component_id', 'store'], # La constraint 'unique_offer_per_store'
            # Qué columnas actualizar si hay conflicto
            set_={
                "price": offer_data['price'],
                "link": link_str, # Usar el string aquí también
                "last_updated": offer_data['last_updated']
            }
        )
        .returning(Offer) # Devuelve el objeto Offer (nuevo o actualizado)
    )
    
    result = db.execute(stmt).fetchone()
    db.commit()
    
    return result