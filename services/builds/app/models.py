# services/builds/app/models.py
import uuid
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .database import Base
import datetime
import enum

class UseTypeEnum(str, enum.Enum):
    Gaming = "Gaming"
    Oficina = "Oficina"
    Edicion = "Edición"
    Programacion = "Programación"
    Otro = "Otro"

class Build(Base):
    __tablename__ = "builds"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False, index=True)
    description = Column(String, nullable=True)
    
    use_type = Column(Enum(UseTypeEnum), nullable=True)
    image_url = Column(String, nullable=True)
    is_public = Column(Boolean, default=False, index=True)
    
    user_id = Column(String, nullable=False, index=True) 
    user_name = Column(String, nullable=False)
    
    total_price = Column(Float, nullable=False, default=0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    components = relationship("BuildComponent", back_populates="build", cascade="all, delete-orphan")

class BuildComponent(Base):
    __tablename__ = "build_components"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    build_id = Column(UUID(as_uuid=True), ForeignKey("builds.id"), nullable=False)
    
    # --- ¡CAMBIO CRÍTICO AQUÍ! ---
    # Debe ser Integer para coincidir con el ID de la tabla 'components'
    component_id = Column(Integer, nullable=False, index=True) 
    # --- FIN DEL CAMBIO ---
    category = Column(String, nullable=False)
    name = Column(String, nullable=False)
    image_url = Column(String, nullable=True)
    price_at_build_time = Column(Float, nullable=False)

    build = relationship("Build", back_populates="components")
    
    
