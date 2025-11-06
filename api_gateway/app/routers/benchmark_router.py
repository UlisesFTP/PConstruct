from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from typing import Dict, Any, List, Optional
import httpx
from app.config import SERVICE_CONFIG, logger
from pydantic import BaseModel

router = APIRouter(prefix="/benchmark", tags=["benchmark"])



class CompareRequest(BaseModel):
    build_ids: list[int]
    scenario: Optional[str] = None


@router.post("/estimate")
async def estimate_performance(build: dict):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                f"{SERVICE_CONFIG['benchmark']}/benchmark/estimate",
                json=build,
                timeout=30.0
            )
            # Evita ValueError cuando 500 devuelve texto/HTML
            try:
                payload = resp.json()
            except ValueError:
                payload = {"error": True, "message": resp.text or "No content"}

            return JSONResponse(status_code=resp.status_code, content=payload)
        except Exception as e:
            logger.error(f"Benchmark estimation error: {e}")
            raise HTTPException(status_code=503, detail="Benchmark service unavailable")

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


@router.post("/compare")
async def compare_builds_post(req: CompareRequest):
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{SERVICE_CONFIG['benchmark']}/benchmark/compare",
            json=req.model_dump(),
            timeout=30.0
        )
        return JSONResponse(status_code=r.status_code, content=r.json())