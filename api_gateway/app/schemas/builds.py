from typing import Optional, List, Dict
from pydantic import BaseModel

class BuildCreateRequest(BaseModel):
    name: str
    description: Optional[str] = None
    is_public: bool = True
    components: List[Dict]
