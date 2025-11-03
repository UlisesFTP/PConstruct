from pydantic import BaseModel
from typing import List, Literal

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


class BenchmarkEstimateRequest(BaseModel):
    # por ahora asumimos que el gateway nos manda ids de componentes (los de components-service)
    component_ids: List[int]


class SoftwarePerformanceResult(BaseModel):
    software_name: str
    scenario: str
    tier: Literal["unplayable", "playable", "recommended"]
    notes: str


class BenchmarkEstimateResponse(BaseModel):
    results: List[SoftwarePerformanceResult]
