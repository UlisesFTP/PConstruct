from fastapi import APIRouter, HTTPException, status, Request
from fastapi.responses import JSONResponse
import httpx, json
from app.config import SERVICE_CONFIG, logger

router = APIRouter(tags=["components"])

@router.get("/components")
async def get_components(request: Request):
    params = request.query_params
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['component']}/components/",
                params=params,
                timeout=30.0,
                follow_redirects=True
            )
            response.raise_for_status()
            return JSONResponse(
                status_code=response.status_code,
                content=response.json(),
            )
        except httpx.HTTPStatusError as e:
            try:
                detail = e.response.json()
            except json.JSONDecodeError:
                detail = e.response.text
            raise HTTPException(status_code=e.response.status_code, detail=detail)
        except (httpx.RequestError, json.JSONDecodeError) as e:
            logger.error(f"Get components error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable or returned invalid response"
            )

@router.get("/components/{component_id}")
async def get_component(component_id: int):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['component']}/components/{component_id}",
                timeout=30.0
            )
            if response.status_code == 404:
                raise HTTPException(status_code=404, detail="Component not found")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Get component error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable"
            )

@router.post("/compatibility/check")
async def check_compatibility(components: list[dict[str, str]]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['component']}/compatibility/check",
                json={"components": components},
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Compatibility check error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable"
            )
