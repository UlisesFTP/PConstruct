# services/builds/app/models.py
import uuid
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey, Enum, Text, UniqueConstraint
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
    
    # --- NUEVAS RELACIONES ---
    likes = relationship("BuildLike", back_populates="build", cascade="all, delete-orphan")
    comments = relationship("BuildComment", back_populates="build", cascade="all, delete-orphan")
    # --- FIN DE NUEVAS RELACIONES ---

class BuildComponent(Base):
    __tablename__ = "build_components"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    build_id = Column(UUID(as_uuid=True), ForeignKey("builds.id"), nullable=False)
    
    component_id = Column(Integer, nullable=False, index=True) 
    category = Column(String, nullable=False)
    name = Column(String, nullable=False)
    image_url = Column(String, nullable=True)
    price_at_build_time = Column(Float, nullable=False)

    build = relationship("Build", back_populates="components")

# --- NUEVO MODELO: BuildLike ---
class BuildLike(Base):
    __tablename__ = "build_likes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(String, nullable=False) # ID del usuario que da like
    build_id = Column(UUID(as_uuid=True), ForeignKey("builds.id"), nullable=False)

    build = relationship("Build", back_populates="likes")
    
    __table_args__ = (UniqueConstraint('user_id', 'build_id', name='_user_build_uc'),)

# --- NUEVO MODELO: BuildComment ---
class BuildComment(Base):
    __tablename__ = "build_comments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(String, nullable=False)
    user_name = Column(String, nullable=False) # Guardamos el nombre para eficiencia
    build_id = Column(UUID(as_uuid=True), ForeignKey("builds.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    build = relationship("Build", back_populates="comments")