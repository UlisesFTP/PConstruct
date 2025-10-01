from sqlalchemy import Column, Integer, String, JSON, Float, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base
from sqlalchemy.sql import func
import datetime

Base = declarative_base()

class BenchmarkResult(Base):
    __tablename__ = "benchmark_results"
    
    id = Column(Integer, primary_key=True, index=True)
    build_id = Column(Integer, index=True)  # Referencia a build en servicio de builds
    use_case = Column(String(50))
    results = Column(JSON)  # Almacena los resultados de la estimación
    created_at = Column(DateTime, default=func.now())

class ComparisonResult(Base):
    __tablename__ = "comparison_results"
    
    id = Column(Integer, primary_key=True, index=True)
    build_ids = Column(JSON)  # Lista de IDs de builds
    scenario = Column(String(50))
    results = Column(JSON)  # Resultados completos de la comparación
    created_at = Column(DateTime, default=func.now())