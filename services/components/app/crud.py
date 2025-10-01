from sqlalchemy.orm import Session
from . import models

def create_component(db: Session, component: schemas.ComponentCreate):
    db_component = models.Component(**component.dict())
    db.add(db_component)
    db.commit()
    db.refresh(db_component)
    return db_component

def get_component(db: Session, component_id: int):
    return db.query(models.Component).filter(models.Component.id == component_id).first()

def get_components(
    db: Session, 
    category: str = None,
    manufacturer: str = None,
    skip: int = 0, 
    limit: int = 100
):
    query = db.query(models.Component)
    
    if category:
        query = query.filter(models.Component.category == category)
    if manufacturer:
        query = query.filter(models.Component.manufacturer == manufacturer)
    
    return query.offset(skip).limit(limit).all()

def get_categories(db: Session):
    return [category.value for category in models.ComponentCategory]

def get_manufacturers(db: Session, category: str = None):
    query = db.query(models.Component.manufacturer).distinct()
    if category:
        query = query.filter(models.Component.category == category)
    return [result[0] for result in query.all()]