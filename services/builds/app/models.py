from sqlalchemy import Column, Integer, String, JSON, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func
import datetime

Base = declarative_base()

class Build(Base):
    __tablename__ = "builds"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)  # 0 para builds públicas/genéricas
    name = Column(String(100))
    description = Column(String(500))
    components = Column(JSON, nullable=False)  # Lista de IDs de componentes
    total_price = Column(Float)
    currency = Column(String(3), default="USD")
    use_case = Column(String(50))  # gaming, editing, etc.
    country_code = Column(String(2))
    estimated_performance = Column(JSON)  # Resultados de benchmarks
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    is_public = Column(Boolean, default=True)
    is_custom = Column(Boolean, default=False)  # True para builds personalizadas
    likes = Column(Integer, default=0)