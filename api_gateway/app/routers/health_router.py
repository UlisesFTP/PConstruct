from fastapi import APIRouter
from datetime import datetime
from app.config import SERVICE_CONFIG
import httpx

router = APIRouter(tags=["health"])

@router.get("/")
async def root():
    return {"message": "PC Builder API Gateway", "version": "1.0.0"}

@router.get("/health")
async def health_check():
    results = {}
    async with httpx.AsyncClient() as client:
        for service_name, service_url in SERVICE_CONFIG.items():
            try:
                resp = await client.get(f"{service_url}/health", timeout=2.0)
                results[service_name] = {
                    "status": "up" if resp.status_code == 200 else "down",
                    "details": resp.json() if resp.status_code == 200 else None
                }
            except Exception as e:
                results[service_name] = {"status": "down", "error": str(e)}
    
    overall_status = all(r["status"] == "up" for r in results.values())
    return {
        "timestamp": datetime.now().isoformat(),
        "status": "healthy" if overall_status else "degraded",
        "services": results
    }
