from sqlalchemy import Column, String, Float, DateTime, ForeignKey, JSON
from sqlalchemy.ext.declarative import declarative_base
import datetime

Base = declarative_base()

class ComponentPrice(Base):
    __tablename__ = "component_prices"
    
    id = Column(String, primary_key=True)  # UUID
    component_id = Column(String, index=True)
    retailer = Column(String)
    country_code = Column(String(2))
    price = Column(Float)
    currency = Column(String(3))
    stock = Column(String(20))
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    metadata = Column(JSON)  # Datos adicionales (oferta, envío, etc.)