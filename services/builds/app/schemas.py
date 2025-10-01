from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

class BuildComponent(BaseModel):
    component_id: int
    quantity: int = 1

class BuildRequest(BaseModel):
    budget: float
    currency: str = "USD"
    use_case: str  # Enum: gaming, streaming, engineering, programming, ai
    country_code: str
    user_id: Optional[int] = None
    existing_components: Optional[List[int]] = None
    preferred_brands: Optional[Dict[str, str]] = None  # {"CPU": "AMD", "GPU": "NVIDIA"}

class BuildCreate(BaseModel):
    user_id: int
    name: str
    description: Optional[str] = None
    components: List[BuildComponent]
    use_case: str
    country_code: str
    is_public: bool = True

class Build(BaseModel):
    id: int
    user_id: int
    name: str
    description: Optional[str]
    components: List[Dict]  # Detalles completos de componentes
    total_price: float
    currency: str
    use_case: str
    country_code: str
    estimated_performance: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
    is_public: bool
    likes: int

    class Config:
        orm_mode = True

class OptimizationRequest(BaseModel):
    build_id: int
    budget_change: float = 0  # Aumento o reducción de presupuesto
    performance_target: Optional[str] = None  # Ej: "60fps@4k"
    component_replacements: Optional[Dict[int, int]] = None  # {old_id: new_id}