import httpx
from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta, timezone
from app.schemas.auth import LoginRequest
from app.config import USER_SERVICE_URL, JWT_EXP_MINUTES
import jwt_utils

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/login")
async def login(req: LoginRequest):
    async with httpx.AsyncClient(timeout=10.0) as client:
        upstream = await client.post(
            f"{USER_SERVICE_URL}/auth/login",
            json={"email": req.email, "password": req.password},
        )

    if upstream.status_code != 200:
        try:
            detail = upstream.json()
        except Exception:
            detail = {"detail": upstream.text}
        raise HTTPException(status_code=upstream.status_code, detail=detail)

    user_payload = upstream.json()
    user_id = user_payload.get("user_id") or user_payload.get("id") or user_payload.get("sub")
    email = user_payload.get("email", req.email)
    role = user_payload.get("role", "user")

    if not user_id:
        raise HTTPException(status_code=500, detail="Upstream auth did not return user_id")

    expires_at = datetime.now(timezone.utc) + timedelta(minutes=JWT_EXP_MINUTES)
    token_data = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "exp": expires_at,
    }
    access_token = jwt_utils.create_access_token(token_data, expires_minutes=JWT_EXP_MINUTES)

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_at": expires_at.isoformat(),
        "user": {
            "user_id": user_id,
            "email": email,
            "role": role,
        },
    }
