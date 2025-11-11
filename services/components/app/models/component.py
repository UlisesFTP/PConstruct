from sqlalchemy import Column, Integer, String, Text, DateTime, func, Index
from sqlalchemy.orm import relationship
from app.db.session import Base

class Component(Base):
    __tablename__ = "components"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(500), nullable=False)
    category = Column(String(100), nullable=False, index=True)
    brand = Column(String(100), index=True)
    image_url = Column(Text)
    description = Column(Text)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # --- Relaciones (La magia de SQLAlchemy) ---
    
    # Un 'Component' tiene muchas 'Offers'
    offers = relationship(
        "Offer", 
        back_populates="component", 
        cascade="all, delete-orphan"
    )
    
    # Un 'Component' tiene muchas 'Reviews'
    reviews = relationship(
        "Review", 
        back_populates="component", 
        cascade="all, delete-orphan"
    )
    
    # --- Índices (copiados de nuestro SQL) ---
    __table_args__ = (
        Index('idx_components_name_search', 'name', postgresql_using='gin'),
    )