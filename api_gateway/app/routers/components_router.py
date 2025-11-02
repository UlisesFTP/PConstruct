from fastapi import APIRouter, Query
from typing import Optional, Dict, Any
from app.utils.http_forward import forward_json
from app.config import COMPONENT_SERVICE_URL

router = APIRouter(prefix="/components", tags=["components"])

@router.get("")
async def list_components(
    q: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    params: Dict[str, Any] = {
        "limit": limit,
        "offset": offset,
    }
    if q is not None:
        params["q"] = q
    if category is not None:
        params["category"] = category

    return await forward_json(
        "GET",
        f"{COMPONENT_SERVICE_URL}/components/",
        params=params,
    )

@router.get("/{component_id}")
async def get_component(component_id: int):
    return await forward_json(
        "GET",
        f"{COMPONENT_SERVICE_URL}/components/{component_id}",
    )
