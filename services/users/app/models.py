# services/users-service/app/models.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ARRAY, Numeric
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"
    
    # Coincide con tu esquema actual
    user_id = Column(Integer, primary_key=True, index=True)  # Cambió de 'id' a 'user_id'
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    name = Column(String(255))  # Nuevo campo en tu esquema
    hashed_password = Column(String(200), nullable=False)
    is_active = Column(Boolean, default=True)
    role = Column(String(20), default="user")
    is_verified = Column(Boolean, nullable=False, default=False)
    country_code = Column(String(2))  # Nuevo campo en tu esquema
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True))  # Nuevo campo en tu esquema