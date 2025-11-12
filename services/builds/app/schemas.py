# services/builds/app/schemas.py
from pydantic import BaseModel, HttpUrl
import uuid
import datetime
from typing import List, Optional, Dict
from .models import UseTypeEnum # Importamos el Enum

# --- Schemas de Componentes ---
class BuildComponentCreate(BaseModel):
    component_id: int # Era str
    category: str
    name: str
    image_url: Optional[str] = None
    price_at_build_time: float

class BuildComponentRead(BuildComponentCreate):
    id: uuid.UUID
    
    class Config:
        from_attributes = True

# --- Schemas de Build ---
class BuildCreate(BaseModel):
    name: str
    description: Optional[str] = None
    use_type: UseTypeEnum # Usamos el Enum
    image_url: Optional[str] = None
    is_public: bool
    components: List[BuildComponentCreate]

class BuildRead(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str]
    use_type: UseTypeEnum
    image_url: Optional[str]
    is_public: bool
    user_id: str
    user_name: str
    total_price: float
    created_at: datetime.datetime
    components: List[BuildComponentRead]

    class Config:
        from_attributes = True

# Schema simple para listar builds (Mis Builds / Comunidad)
class BuildSummary(BaseModel):
    id: uuid.UUID
    name: str
    image_url: Optional[str]
    user_name: str
    total_price: float
    created_at: datetime.datetime
    is_public: bool
    
    # Podríamos añadir los 3 componentes clave si queremos
    cpu_name: Optional[str] = None
    gpu_name: Optional[str] = None
    ram_name: Optional[str] = None

    class Config:
        from_attributes = True
        
        
class CompatibilityRequest(BaseModel):
    """
    Lo que el frontend nos enviará: un diccionario de componentes seleccionados.
    Ej: {"cpu": "Intel i9", "motherboard": "MSI B760", "ram": "Corsair 32GB"}
    """
    components: Dict[str, Optional[str]]

class CompatibilityResponse(BaseModel):
    """
    Lo que el backend (Gemini) nos devolverá.
    """
    compatible: bool
    reason: str