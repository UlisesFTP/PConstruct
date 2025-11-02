from fastapi import APIRouter, HTTPException, status
from fastapi.responses import JSONResponse
from typing import Dict, Any
from datetime import datetime, timedelta
import jwt
import httpx
from app.config import SERVICE_CONFIG, JWT_SECRET, JWT_ALGORITHM, JWT_EXPIRATION_MINUTES, logger, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET, CLOUDINARY_CLOUD_NAME
import cloudinary
import cloudinary.api
import cloudinary.uploader

router = APIRouter(prefix="/auth", tags=["auth"])

# Configurar Cloudinary una sola vez aquí
cloudinary.config(
    cloud_name=CLOUDINARY_CLOUD_NAME,
    api_key=CLOUDINARY_API_KEY,
    api_secret=CLOUDINARY_API_SECRET,
    secure=True,
)

@router.post("/login")
async def login(credentials: Dict[str, str]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/login",
                json=credentials,
                timeout=30.0
            )
            data = response.json()

            if response.status_code != 200:
                return JSONResponse(status_code=response.status_code, content=data)

            user_profile = data["user"]

            expiration = datetime.utcnow() + timedelta(minutes=JWT_EXPIRATION_MINUTES)
            token_data = {
                "sub": str(user_profile["user_id"]),
                "email": user_profile["email"],
                "role": user_profile["role"],
                "exp": expiration
            }

            token = jwt.encode(token_data, JWT_SECRET, algorithm=JWT_ALGORITHM)

            return {
                "access_token": token,
                "token_type": "bearer",
                "expires_at": expiration.isoformat(),
                "user": user_profile
            }
        except Exception as e:
            logger.error(f"Login error: {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable or response format error"
            )

@router.post("/register")
async def register(user_data: Dict[str, Any]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/register",
                json=user_data,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Register error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )

@router.post("/verify-email")
async def verify_email(verification_data: Dict[str, Any]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/verify-email",
                json=verification_data,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Verify email error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )

@router.post("/resend-verification")
async def resend_verification(resend_data: Dict[str, Any]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/resend-verification",
                json=resend_data,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Resend verification error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )

@router.post("/request-password-reset")
async def request_password_reset(request_data: Dict[str, Any]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/request-password-reset",
                json=request_data,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Request password reset error: {str(e)}")
            raise HTTPException(status_code=503, detail="User service unavailable")

@router.post("/reset-password")
async def reset_password(request_data: Dict[str, Any]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/reset-password",
                json=request_data,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Reset password error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )

@router.post("/generate-upload-signature")
async def generate_upload_signature():
    """
    Firma para subir imágenes directamente a Cloudinary desde Flutter.
    (equivale al /posts/generate-upload-signature que tenías, pero podemos
    dejarlo aquí o moverlo a posts_router si quieres mantener la ruta igual)
    """
    try:
        timestamp = int(time.time())
        params_to_sign = {
            "timestamp": timestamp,
            "folder": "pconstruct_posts",
            "upload_preset": "ml_default"
        }

        # firma
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
        logger.error(f"Error generating Cloudinary signature: {e}")
        raise HTTPException(status_code=500, detail="Could not generate upload signature")
