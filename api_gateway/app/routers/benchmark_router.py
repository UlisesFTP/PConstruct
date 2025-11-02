from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from typing import Dict, Any, List, Optional
import httpx
from app.config import SERVICE_CONFIG, logger

router = APIRouter(prefix="/benchmark", tags=["benchmark"])

@router.post("/estimate")
async def estimate_performance(build: Dict[str, Any]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['benchmark']}/benchmark/estimate",
                json=build,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Benchmark estimation error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail="Benchmark service unavailable"
            )

@router.get("/compare")
async def compare_builds(
    build_ids: List[str],
    scenario: Optional[str] = None
):
    params = {"build_ids": ",".join(build_ids)}
    if scenario:
        params["scenario"] = scenario

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['benchmark']}/benchmark/compare",
                params=params,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Benchmark comparison error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail="Benchmark service unavailable"
            )
