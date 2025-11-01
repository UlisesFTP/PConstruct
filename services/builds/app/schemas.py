from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime

class BuildComponentInput(BaseModel):
    slot: str
    component_id: int

class BuildCreate(BaseModel):
    name: str
    description: Optional[str] = None
    is_public: bool = False
    components: List[BuildComponentInput]

class BuildComponentOut(BaseModel):
    id: int
    slot: str
    component_id: int
    model_config = ConfigDict(from_attributes=True)

class BuildSummary(BaseModel):
    id: int
    user_id: int
    name: str
    description: Optional[str] = None
    is_public: bool
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

class BuildDetail(BaseModel):
    id: int
    user_id: int
    name: str
    description: Optional[str] = None
    is_public: bool
    created_at: datetime
    updated_at: datetime
    components: List[BuildComponentOut]
    model_config = ConfigDict(from_attributes=True)
