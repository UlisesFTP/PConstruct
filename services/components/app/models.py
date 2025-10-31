from sqlalchemy import (
    Column,
    Integer,
    String,
    JSON,
    ForeignKey,
    Numeric,
    DateTime,
    MetaData,
)
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func
import enum

# Todas las tablas viven en el esquema "hardware"
SCHEMA_NAME = "hardware"
metadata_obj = MetaData(schema=SCHEMA_NAME)
Base = declarative_base(metadata=metadata_obj)

# Este Enum sigue siendo útil para las respuestas Pydantic (schemas.py)
class ComponentCategory(str, enum.Enum):
    CPU = "CPU"
    GPU = "GPU"
    Motherboard = "Motherboard"
    RAM = "RAM"
    Storage = "Storage"
    PSU = "Power Supply"
    Case = "Case"
    Cooler = "Cooler"
    Other = "Other"

class Manufacturer(Base):
    __tablename__ = "manufacturers"

    manufacturer_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)

    # Estas columnas sí existen en tu SQL:
    #   website character varying(255),
    #   country character varying(50),
    website = Column(String(255))
    country = Column(String(50))

    components = relationship("Component", back_populates="manufacturer")

class Component(Base):
    __tablename__ = "components"

    component_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    model = Column(String(100), unique=True, nullable=False)

    # 🔥 Cambio importante:
    # Antes: category = Column(Enum(ComponentCategory), nullable=False)
    # Ahora lo tratamos como texto normal.
    #
    # Postgres internamente sigue teniendo ENUM hardware.component_category,
    # y seguirá validando que el valor exista.
    # Pero del lado de Python se lee como string crudo ("Power Supply", "GPU", etc.)
    # y así evitamos el LookupError.
    category = Column(String(50), nullable=False)

    manufacturer_id = Column(
        Integer,
        ForeignKey(f"{SCHEMA_NAME}.manufacturers.manufacturer_id"),
        nullable=False,
    )
    manufacturer = relationship("Manufacturer", back_populates="components")

    release_year = Column(Integer)
    msrp = Column(Numeric(10, 2))
    image_url = Column(String(300))
    specs = Column(JSON, nullable=False)

    created_at = Column(DateTime(timezone=False), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=False),
        server_default=func.now(),
        onupdate=func.now()
    )
