
from fastapi import APIRouter, HTTPException, status, Header, Request
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
from app.utils.http_forward import forward_request

if not hasattr(cloudinary.config(), "api_key"):
    cloudinary.config(
        cloud_name=CLOUDINARY_CLOUD_NAME,
        api_key=CLOUDINARY_API_KEY,
        api_secret=CLOUDINARY_API_SECRET,
        secure=True,
    )


router = APIRouter(prefix="/users", tags=["users"])

@router.patch("/me", response_model=None)
async def update_current_user_profile(
    request: Request,
    authorization: str | None = Header(None)
):
    """
    Endpoint del Gateway para actualizar el perfil del usuario.
    Verifica el token y reenvía al microservicio de usuarios.
    """
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub") # 'sub' debería ser el user_id
    
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token, missing 'sub' (user_id)")

    # Preparamos la cabecera X-User-ID para el microservicio
    headers = {"X-User-ID": str(user_id)}

    # Reenviamos la solicitud (cuerpo JSON + cabecera) al microservicio
    return await forward_request(
        request=request,
        target_url=f"{SERVICE_CONFIG['user']}/users/me",
        custom_headers=headers
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