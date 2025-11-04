from typing_extensions import Literal
from pydantic import BaseModel, Field, model_validator
from typing import List, Optional
class SoftwareRequirementOut(BaseModel):
    id: int
    name: str
    scenario: str
    type: Literal["game", "software"]
    min_cpu_score: int
    min_gpu_score: int
    rec_cpu_score: int
    rec_gpu_score: int

    class Config:
        from_attributes = True  # pydantic v2 equivalente a orm_mode=True

class ScenarioIn(BaseModel):
    software_name: str
    scenario: str


class EstimateRequest(BaseModel):
    component_ids: Optional[List[int]] = None
    build_id: Optional[int] = None

    @model_validator(mode="after")
    def check_any(self):
        if not self.component_ids and self.build_id is None:
            raise ValueError("Debes enviar 'component_ids' o 'build_id'.")
        return self

class SoftwarePerformanceResult(BaseModel):
    software_name: str
    scenario: str
    tier: Literal["unplayable", "playable", "recommended"]
    notes: str


class BenchmarkEstimateResponse(BaseModel):
    results: List[SoftwarePerformanceResult]
