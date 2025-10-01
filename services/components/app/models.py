from sqlalchemy import Column, Integer, String, JSON, Enum
from sqlalchemy.ext.declarative import declarative_base
import enum

Base = declarative_base()

class ComponentCategory(enum.Enum):
    CPU = "CPU"
    GPU = "GPU"
    MOTHERBOARD = "Motherboard"
    RAM = "RAM"
    STORAGE = "Storage"
    PSU = "Power Supply"
    CASE = "Case"
    COOLER = "Cooler"
    OTHER = "Other"

class Component(Base):
    __tablename__ = "components"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    category = Column(Enum(ComponentCategory), nullable=False)
    manufacturer = Column(String(100), nullable=False)
    model = Column(String(100), unique=True, nullable=False)
    specs = Column(JSON, nullable=False)  # Almacena especificaciones técnicas
    image_url = Column(String(300))
    release_year = Column(Integer)