import datetime
from sqlalchemy import Column, String, Float, DateTime, JSON

from .database import Base

class ComponentPrice(Base):
    __tablename__ = "component_prices"

    id = Column(String, primary_key=True)
    component_id = Column(String, index=True)
    retailer = Column(String)
    country_code = Column(String(2))
    price = Column(Float)
    currency = Column(String(3))
    stock = Column(String(20))
    url = Column(String)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    additional_data = Column(JSON)
