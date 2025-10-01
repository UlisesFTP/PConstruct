from pydantic import BaseModel
from typing import List, Optional, Dict, Any

class ComponentBase(BaseModel):
    name: str
    category: str
    manufacturer: str
    model: str
    specs: Dict[str, Any]
    image_url: Optional[str] = None
    release_year: Optional[int] = None

class ComponentCreate(ComponentBase):
    pass

class Component(ComponentBase):
    id: int

    class Config:
        orm_mode = True

class CompatibilityCheckRequest(BaseModel):
    component_ids: List[int]

class CompatibilityIssue(BaseModel):
    component_id: int
    issue: str
    severity: str  # error, warning

class CompatibilityResult(BaseModel):
    compatible: bool
    issues: List[CompatibilityIssue]

class CompatibilityRule(BaseModel):
    rule_id: str
    description: str
    applies_to: List[str]  # Categorías de componentes
    condition: Dict[str, Any]