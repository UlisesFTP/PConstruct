from sqlalchemy.orm import Session
from . import models, schemas
import uuid
import json

def save_custom_build(db: Session, build: schemas.BuildCreate):
    # Convertir componentes a JSON
    components_json = [comp.dict() for comp in build.components]
    
    # Calcular precio total (se actualizará después con datos reales)
    total_price = sum(comp.get("price", 0) * comp["quantity"] for comp in components_json)
    
    db_build = models.Build(
        user_id=build.user_id,
        name=build.name,
        description=build.description,
        components=components_json,
        total_price=total_price,
        currency="USD",  # Temporal
        use_case=build.use_case,
        country_code=build.country_code,
        is_public=build.is_public,
        is_custom=True
    )
    
    db.add(db_build)
    db.commit()
    db.refresh(db_build)
    return db_build

def save_generated_build(db: Session, build_data: dict, user_id: int):
    """Guardar una build generada por el sistema"""
    db_build = models.Build(
        user_id=user_id,
        name=build_data.get("name", "Generated Build"),
        description=build_data.get("description", "Automatically generated build"),
        components=build_data["components"],
        total_price=build_data["total_price"],
        currency=build_data["currency"],
        use_case=build_data["use_case"],
        country_code=build_data["country_code"],
        estimated_performance=build_data.get("estimated_performance"),
        is_public=True,
        is_custom=False
    )
    
    db.add(db_build)
    db.commit()

def get_build(db: Session, build_id: int):
    return db.query(models.Build).filter(models.Build.id == build_id).first()

def get_user_builds(db: Session, user_id: int):
    return db.query(models.Build).filter(models.Build.user_id == user_id).all()