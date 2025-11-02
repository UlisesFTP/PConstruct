from fastapi import APIRouter
from app.schemas.pricing import PriceRefreshRequest
from app.utils.http_forward import forward_json
from app.config import PRICING_SERVICE_URL

router = APIRouter(prefix="/prices", tags=["prices"])

@router.get("/{component_id}")
async def get_prices(component_id: int):
    return await forward_json(
        "GET",
        f"{PRICING_SERVICE_URL}/prices/{component_id}",
    )

@router.post("/refresh", status_code=202)
async def refresh_prices(body: PriceRefreshRequest):
    return await forward_json(
        "POST",
        f"{PRICING_SERVICE_URL}/prices/refresh",
        json_body=body.model_dump(),
    )
