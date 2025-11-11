from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.db.session import Base

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(Text, nullable=False)
    
    # IDs de usuarios
    user_id = Column(String(255), nullable=False)
    user_username = Column(String(100)) # Denormalizado

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # --- Clave Foránea (FK) ---
    review_id = Column(
        Integer, 
        ForeignKey("reviews.id", ondelete="CASCADE"), 
        nullable=False
    )
    
    # --- Relación ---
    # Un 'Comment' pertenece a una 'Review'
    review = relationship("Review", back_populates="comments")