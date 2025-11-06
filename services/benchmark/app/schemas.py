# app/schemas.py
from pydantic import BaseModel
from typing import List, Dict, Any, Optional, Literal

class ComponentResult(BaseModel):
    id: int
    type: str            # "cpu" | "gpu"
    model: str
    score: Optional[float] = None
    source: Optional[str] = None   # "csv" | "seed" | "gemini" | "unknown"

class CompareRequest(BaseModel):
    build_ids: List[int]
    scenario: Optional[str] = None

class EstimateRequest(BaseModel):
    component_ids: Optional[List[int]] = None
    build_id: Optional[int] = None
    cpu_model: Optional[str] = None
    gpu_model: Optional[str] = None
    scenario: Optional[str] = None
    hints: Optional[Dict[str, Any]] = None   # usado por main.py

class EstimateResponse(BaseModel):
    method: Literal["interpolation","tier","fallback"] = "interpolation"
    components: List[ComponentResult]
    scores_used: Dict[str, str]      # MUST be strings like "csv", not ints
    scenario: Optional[str] = None
    classification: Dict[str, Any]
    gemini_reco: Optional[str] = None