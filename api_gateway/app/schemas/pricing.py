from typing import Optional, List
from pydantic import BaseModel

class PriceRefreshRequest(BaseModel):
    component_ids: Optional[List[int]] = None
    countries: Optional[List[str]] = None
