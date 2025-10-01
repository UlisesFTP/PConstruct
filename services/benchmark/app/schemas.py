from pydantic import BaseModel
from typing import List, Dict, Any

class EstimateRequest(BaseModel):
    component_ids: List[int]
    use_case: str  # gaming, engineering, etc.
    resolution: str = "1080p"  # 1080p, 1440p, 4K
    settings: str = "ultra"  # low, medium, high, ultra

class BenchmarkResult(BaseModel):
    fps: Dict[str, float]  # Ej: {"average": 120, "min": 90, "max": 150}
    score: float  # Puntaje general
    details: Dict[str, Any]  # Resultados específicos por juego/aplicación

class ComparisonResult(BaseModel):
    scenario: str
    results: List[Dict]  # Lista de resultados por build

class BenchmarkHistory(BaseModel):
    id: int
    build_id: int
    use_case: str
    results: Dict[str, Any]
    created_at: str

    class Config:
        orm_mode = True