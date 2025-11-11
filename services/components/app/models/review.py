from sqlalchemy import Column, Integer, String, Text, SmallInteger, ForeignKey, DateTime, func, CheckConstraint
from sqlalchemy.orm import relationship
from app.db.session import Base

class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    rating = Column(SmallInteger, nullable=False)
    title = Column(String(255))
    content = Column(Text, nullable=False)
    
    # IDs de usuarios (del microservicio de 'users')
    user_id = Column(String(255), nullable=False, index=True)
    user_username = Column(String(100)) # Denormalizado para eficiencia

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # --- Clave Foránea (FK) ---
    component_id = Column(
        Integer, 
        ForeignKey("components.id", ondelete="CASCADE"), 
        nullable=False
    )

    # --- Relaciones ---
    # Una 'Review' pertenece a un 'Component'
    component = relationship("Component", back_populates="reviews")
    
    # Una 'Review' tiene muchos 'Comments'
    comments = relationship(
        "Comment", 
        back_populates="review", 
        cascade="all, delete-orphan"
    )
    
    __table_args__ = (
        CheckConstraint('rating >= 1 AND rating <= 5', name='check_rating_range'),
    )