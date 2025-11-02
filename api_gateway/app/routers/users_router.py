from fastapi import APIRouter, HTTPException, status, Header
from fastapi.responses import JSONResponse
from typing import Dict
import httpx
from app.config import SERVICE_CONFIG, logger
from app.utils.security import verify_token

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/me")
async def get_current_user(authorization: str | None = Header(None)):
    token_data: Dict = verify_token(authorization)
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['user']}/users/{token_data['sub']}",
                headers={"X-User-ID": token_data["sub"]},
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get user error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )
