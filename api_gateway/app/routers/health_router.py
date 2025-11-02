from fastapi import APIRouter
from datetime import datetime, timezone
import asyncio
import httpx
from app.config import (
    USER_SERVICE_URL,
    POSTS_SERVICE_URL,
    COMPONENT_SERVICE_URL,
    BUILDS_SERVICE_URL,
    PRICING_SERVICE_URL,
    BENCHMARK_SERVICE_URL,
)

router = APIRouter(tags=["health"])

async def _ping(name: str, url: str) -> dict:
    started = datetime.now(timezone.utc)
    status_code = None
    body = None
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(f"{url}/health")
        status_code = resp.status_code
        try:
            body = resp.json()
        except Exception:
            body = resp.text
    except Exception as e:
        status_code = 503
        body = {"error": str(e)}
    elapsed = (datetime.now(timezone.utc) - started).total_seconds()
    return {
        "service": name,
        "status": "ok" if status_code == 200 else "unavailable",
        "http": status_code,
        "elapsed_s": elapsed,
        "body": body,
    }

@router.get("/health")
async def health():
    results = await asyncio.gather(
        _ping("user-service", USER_SERVICE_URL),
        _ping("posts-service", POSTS_SERVICE_URL),
        _ping("component-service", COMPONENT_SERVICE_URL),
        _ping("builds-service", BUILDS_SERVICE_URL),
        _ping("pricing-service", PRICING_SERVICE_URL),
        _ping("benchmark-service", BENCHMARK_SERVICE_URL),
        return_exceptions=False,
    )
    overall_ok = all(r["status"] == "ok" for r in results)
    return {
        "status": "ok" if overall_ok else "degraded",
        "services": {r["service"]: r for r in results},
    }
