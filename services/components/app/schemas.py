# PConstruct/services/components/app/schemas.py
from pydantic import BaseModel, ConfigDict
from typing import List, Optional, Dict, Any
from .models import ComponentCategory # Importa el Enum

# --- Esquema para el Fabricante ---
class ManufacturerBase(BaseModel):
    name: str
    website: Optional[str] = None
    country: Optional[str] = None

class Manufacturer(ManufacturerBase):
    manufacturer_id: int
    model_config = ConfigDict(from_attributes=True) # Reemplaza orm_mode

# --- Esquema para Componente ---
class ComponentBase(BaseModel):
    name: str
    model: str
    category: ComponentCategory # Usa el Enum
    specs: Dict[str, Any]
    image_url: Optional[str] = None
    release_year: Optional[int] = None
    msrp: Optional[float] = None # Añadido para coincidir con la DB

class ComponentCreate(ComponentBase):
    # Al crear, pasamos el ID del fabricante
    manufacturer_id: int 

class Component(ComponentBase):
    component_id: int # Coincide con el modelo
    manufacturer: Manufacturer # <-- Muestra el objeto fabricante anidado

    model_config = ConfigDict(from_attributes=True) # Reemplaza orm_mode

# --- Esquemas de Compatibilidad (Sin cambios) ---
class CompatibilityCheckRequest(BaseModel):
    component_ids: List[int]

class CompatibilityIssue(BaseModel):
    component_id: int
    issue: str
    severity: str

class CompatibilityResult(BaseModel):
    compatible: bool
    issues: List[CompatibilityIssue]

class CompatibilityRule(BaseModel):
    rule_id: str
    description: str
    applies_to: List[str]
    condition: Dict[str, Any]