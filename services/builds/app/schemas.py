# services/builds/app/schemas.py
from pydantic import BaseModel, ConfigDict
import uuid
import datetime
from typing import List, Optional, Dict
from .models import UseTypeEnum # Importamos el Enum

# --- Schemas de Componentes (sin cambios) ---
class BuildComponentCreate(BaseModel):
    component_id: int 
    category: str
    name: str
    image_url: Optional[str] = None
    price_at_build_time: float

class BuildComponentRead(BuildComponentCreate):
    id: uuid.UUID
    
    class Config:
        from_attributes = True

# --- NUEVO: Schemas de Comentarios de Build ---
class BuildCommentBase(BaseModel):
    content: str

class BuildCommentCreate(BuildCommentBase):
    pass

class BuildCommentRead(BuildCommentBase):
    id: uuid.UUID
    user_id: str
    user_name: str
    build_id: uuid.UUID
    created_at: datetime.datetime

    class Config:
        from_attributes = True
# --- FIN DE SCHEMAS DE COMENTARIOS ---


# --- Schemas de Build (ACTUALIZADOS) ---
class BuildCreate(BaseModel):
    name: str
    description: Optional[str] = None
    use_type: UseTypeEnum 
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
    
    # --- CAMPOS AÑADIDOS ---
    likes_count: int = 0
    comments_count: int = 0
    is_liked_by_user: bool = False
    user_avatar_url: Optional[str] = None

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
    
    cpu_name: Optional[str] = None
    gpu_name: Optional[str] = None
    ram_name: Optional[str] = None

    # --- CAMPOS AÑADIDOS ---
    likes_count: int = 0
    comments_count: int = 0
    is_liked_by_user: bool = False
    
    user_avatar_url: Optional[str] = None

    class Config:
        from_attributes = True
        
        
class CompatibilityRequest(BaseModel):
    components: Dict[str, Optional[str]]

class CompatibilityResponse(BaseModel):
    compatible: bool
    reason: str