from fastapi import APIRouter, HTTPException, Header, Request
from fastapi.responses import JSONResponse
from typing import Dict, Any, Optional, List
import httpx
from app.config import SERVICE_CONFIG, logger
from app.utils.security import extract_user_id_from_authorization, verify_token

router = APIRouter(prefix="/builds", tags=["builds"])

@router.post("", status_code=201)
async def create_build_proxy(
    request: Request,
    authorization: str | None = Header(None),
):
    user_id = extract_user_id_from_authorization(authorization)
    body = await request.json()

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{SERVICE_CONFIG['build']}/builds/",
            json=body,
            headers={"X-User-Id": str(user_id)},
            timeout=10.0,
        )

    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json(),
    )

@router.get("/community")
async def get_community_builds_proxy(
    skip: int = 0,
    limit: int = 20,
):
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{SERVICE_CONFIG['build']}/builds/community",
            params={"skip": skip, "limit": limit},
            timeout=10.0,
        )
    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json(),
    )

@router.get("/{build_id}")
async def get_build_detail_proxy(
    build_id: int,
    authorization: str | None = Header(None),
):
    headers = {}
    if authorization:
        try:
            uid = extract_user_id_from_authorization(authorization)
            headers["X-User-Id"] = str(uid)
        except HTTPException:
            # token inválido -> el microservicio igual permitirá si es pública
            pass

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{SERVICE_CONFIG['build']}/builds/{build_id}",
            headers=headers,
            timeout=10.0,
        )

    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json() if resp.content else None,
    )

@router.get("/mine")
async def get_my_builds_proxy(
    authorization: str | None = Header(None),
):
    user_id = extract_user_id_from_authorization(authorization)

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{SERVICE_CONFIG['build']}/builds/mine",
            headers={"X-User-Id": str(user_id)},
            timeout=10.0,
        )

    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json(),
    )

@router.post("/recommend")
async def recommend_build(
    requirements: Dict[str, Any],
    authorization: str | None = Header(None),
):
    headers = {}
    if authorization:
        token_data = verify_token(authorization)
        if token_data:
            headers["X-User-ID"] = token_data["sub"]

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['build']}/builds/recommend",
                json=requirements,
                headers=headers,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Build recommendation error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail="Build service unavailable"
            )

@router.get("/saved")
async def get_saved_builds(
    authorization: str | None = Header(None),
):
    token_data = verify_token(authorization)
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['build']}/builds/user/{token_data['sub']}",
                headers={"X-User-ID": token_data["sub"]},
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get saved builds error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail="Build service unavailable"
            )
