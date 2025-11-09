from fastapi import APIRouter, HTTPException, Request, Query, Response
import httpx
from app.config import SERVICE_CONFIG, logger

router = APIRouter(prefix="/pricing", tags=["pricing"])

@router.get("/{component_id}")
async def get_prices(component_id: int, request: Request, country_code: str = Query("MX")):
    client = getattr(request.app.state, "http", None)
    made_client = client is None
    if made_client:
        client = httpx.AsyncClient(timeout=15.0)

    try:
        redis = getattr(request.app.state, "redis", None)
        cache_key = f"price:{country_code}:{component_id}"

        if redis:
            cached = await redis.get(cache_key)
            if cached:
                return Response(content=cached, media_type="application/json", headers={"X-Cache": "HIT"})

        r = await client.get(
            f"{SERVICE_CONFIG['price']}/prices/{component_id}",
            params={"country_code": country_code},
        )
        r.raise_for_status()
        data = r.text  # mantener como texto para cache transparente

        if redis:
            await redis.set(cache_key, data, ex=86400)  # 24h

        return Response(content=data, media_type="application/json", headers={"X-Cache": "MISS"})

    except httpx.HTTPStatusError as e:
        detail = e.response.text
        logger.error(f"[pricing] {e.response.status_code} {detail}")
        raise HTTPException(status_code=e.response.status_code, detail=detail)
    except Exception:
        logger.exception("[pricing] unexpected error")
        raise HTTPException(status_code=503, detail="Pricing service unavailable")
    finally:
        if made_client:
            await client.aclose()

@router.post("/refresh", status_code=202)
async def refresh_prices(request: Request, body: dict):
    client = getattr(request.app.state, "http", None)
    made_client = client is None
    if made_client:
        client = httpx.AsyncClient(timeout=15.0)
    try:
        r = await client.post(f"{SERVICE_CONFIG['price']}/prices/refresh", json=body)
        r.raise_for_status()
        return r.json()
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
    finally:
        if made_client:
            await client.aclose()
