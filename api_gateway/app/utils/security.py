from typing import Optional
from fastapi import Header, HTTPException, status
import jwt_utils

def _extract_user_id_from_authorization(authorization: Optional[str]) -> str:
    if not authorization:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Authorization")
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid auth header")
    token = authorization.split(" ", 1)[1].strip()
    try:
        payload = jwt_utils.verify_token(token)
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    user_id = payload.get("sub") or payload.get("user_id") or payload.get("id")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token missing user id")
    return str(user_id)

async def get_user_id_required(authorization: Optional[str] = Header(None)) -> str:
    return _extract_user_id_from_authorization(authorization)

async def get_user_id_optional(authorization: Optional[str] = Header(None)) -> Optional[str]:
    try:
        return _extract_user_id_from_authorization(authorization)
    except HTTPException:
        return None
