from sqlalchemy import Column, Integer, String, Text, Numeric, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.db.session import Base

class Offer(Base):
    __tablename__ = "offers"

    id = Column(Integer, primary_key=True, index=True)
    store = Column(String(100), nullable=False)
    price = Column(Numeric(10, 2), nullable=False, index=True)
    link = Column(Text, nullable=False)
    last_updated = Column(DateTime(timezone=True), server_default=func.now())

    # --- Clave Foránea (FK) ---
    component_id = Column(
        Integer, 
        ForeignKey("components.id", ondelete="CASCADE"), 
        nullable=False
    )
    
    # --- Relación ---
    # Una 'Offer' pertenece a un 'Component'
    component = relationship("Component", back_populates="offers")