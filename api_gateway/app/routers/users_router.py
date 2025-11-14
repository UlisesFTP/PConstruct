from fastapi import APIRouter, HTTPException, status, Header
from fastapi.responses import JSONResponse
from typing import Dict
import httpx
from app.config import SERVICE_CONFIG, logger
from app.utils.security import verify_token
from app.config import (
    SERVICE_CONFIG, logger, 
    CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET, CLOUDINARY_CLOUD_NAME # <-- NUEVAS IMPORTACIONES
)
import cloudinary # <-- NUEVA IMPORTACIÓN
import cloudinary.api # <-- NUEVA IMPORTACIÓN
import cloudinary.uploader # <-- NUEVA IMPORTACIÓN
import time # <-- NUEVA IMPORTACIÓN

if not hasattr(cloudinary.config(), "api_key"):
    cloudinary.config(
        cloud_name=CLOUDINARY_CLOUD_NAME,
        api_key=CLOUDINARY_API_KEY,
        api_secret=CLOUDINARY_API_SECRET,
        secure=True,
    )


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


@router.post("/generate-upload-signature")
async def generate_upload_signature_users():
    """
    Firma para subir imágenes de perfil de usuario (avatares).
    """
    try:
        timestamp = int(time.time())
        params_to_sign = {
            "timestamp": timestamp,
            "folder": "pconstruct_avatars", # <-- Carpeta dedicada
            "upload_preset": "ml_default" 
        }

        signature = cloudinary.utils.api_sign_request(
            params_to_sign,
            CLOUDINARY_API_SECRET
        )

        return {
            "signature": signature,
            "timestamp": timestamp,
            "api_key": CLOUDINARY_API_KEY
        }
    except Exception as e:
        logger.error(f"Error generating Cloudinary signature for users: {e}")
        raise HTTPException(status_code=500, detail="Could not generate upload signature")