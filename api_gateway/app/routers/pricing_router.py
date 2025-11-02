from fastapi import APIRouter, HTTPException, Request
import httpx
from fastapi.responses import JSONResponse
from typing import Dict, List, Any
from app.config import SERVICE_CONFIG, logger

router = APIRouter(prefix="/prices", tags=["pricing"])

@router.get("/{component_id}")
async def get_component_prices(
    component_id: int,
    request: Request
):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['price']}/prices/{component_id}",
                params=request.query_params,
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Get prices error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail="Price service unavailable"
            )

@router.post("/refresh", status_code=202)
async def trigger_price_refresh(
    request_body: Dict[str, List[Any]]
):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['price']}/prices/refresh",
                json=request_body,
                timeout=10.0
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Trigger price refresh error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail="Pricing service unavailable"
            )
