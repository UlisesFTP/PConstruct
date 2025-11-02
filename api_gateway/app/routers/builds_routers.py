from fastapi import APIRouter, Depends, Query
from typing import Optional, Dict, Any
from app.schemas.builds import BuildCreateRequest
from app.utils.security import get_user_id_required, get_user_id_optional
from app.utils.http_forward import forward_json
from app.config import BUILDS_SERVICE_URL

router = APIRouter(prefix="/builds", tags=["builds"])

@router.post("")
async def create_build(build_req: BuildCreateRequest, user_id: str = Depends(get_user_id_required)):
    headers = {"X-User-Id": user_id}
    return await forward_json(
        "POST",
        f"{BUILDS_SERVICE_URL}/builds",
        headers=headers,
        json_body=build_req.model_dump(),
    )

@router.get("/mine")
async def get_my_builds(user_id: str = Depends(get_user_id_required)):
    headers = {"X-User-Id": user_id}
    return await forward_json(
        "GET",
        f"{BUILDS_SERVICE_URL}/builds/mine",
        headers=headers,
    )

@router.get("/community")
async def get_community_builds(skip: int = Query(0, ge=0), limit: int = Query(20, ge=1, le=100)):
    params: Dict[str, Any] = {"skip": skip, "limit": limit}
    return await forward_json(
        "GET",
        f"{BUILDS_SERVICE_URL}/builds/community",
        params=params,
    )

@router.get("/{build_id}")
async def get_build_detail(build_id: int, user_id: Optional[str] = Depends(get_user_id_optional)):
    headers = {}
    if user_id:
        headers["X-User-Id"] = user_id
    return await forward_json(
        "GET",
        f"{BUILDS_SERVICE_URL}/builds/{build_id}",
        headers=headers,
    )
