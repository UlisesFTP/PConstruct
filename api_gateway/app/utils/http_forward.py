import httpx
from fastapi import HTTPException, status
from typing import Any, Dict, Optional
import json
from app.config import logger

async def forward_get(url: str, headers: Dict[str, str] | None = None,
                      params: Dict[str, Any] | None = None):
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.get(url, headers=headers, params=params)
            resp.raise_for_status()
            return resp
        except httpx.HTTPStatusError as e:
            # Propaga el status code y el json de error real del microservicio
            try:
                detail = e.response.json()
            except json.JSONDecodeError:
                detail = e.response.text
            raise HTTPException(status_code=e.response.status_code, detail=detail)
        except Exception as e:
            logger.error(f"forward_get error: {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Downstream service unavailable",
            )

async def forward_post_json(url: str,
                            body: Dict[str, Any],
                            headers: Dict[str, str] | None = None,
                            timeout: float = 30.0):
    async with httpx.AsyncClient(timeout=timeout) as client:
        try:
            resp = await client.post(url, json=body, headers=headers)
            resp.raise_for_status()
            return resp
        except httpx.HTTPStatusError as e:
            try:
                detail = e.response.json()
            except json.JSONDecodeError:
                detail = e.response.text
            raise HTTPException(status_code=e.response.status_code, detail=detail)
        except Exception as e:
            logger.error(f"forward_post_json error: {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Downstream service unavailable",
            )
