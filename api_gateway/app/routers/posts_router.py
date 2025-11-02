from fastapi import APIRouter, HTTPException, Request, Header, status, Response
from fastapi.responses import JSONResponse
import httpx
from typing import Dict, Optional
from app.config import SERVICE_CONFIG, logger, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
import time
import cloudinary
import cloudinary.uploader
import cloudinary.api

router = APIRouter(prefix="/posts", tags=["posts"])

@router.get("/")
async def get_posts(authorization: str | None = Header(None)):
    headers = {}
    if authorization:
        # si hay token, extraemos user_id
        from app.utils.security import verify_token
        token_data = verify_token(authorization)
        if token_data and token_data.get("sub"):
            headers["X-User-ID"] = str(token_data["sub"])

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['posts']}/posts/",
                headers=headers,
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Get posts error: {str(e)}")
            raise HTTPException(status_code=503, detail="Posts service unavailable")

@router.post("/")
async def create_post(
    request: Request,
    authorization: str | None = Header(None),
):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing token")

    from app.utils.security import verify_token
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token: missing user ID")

    post_data = await request.json()

    async with httpx.AsyncClient() as client:
        try:
            headers = {"X-User-ID": str(user_id)}
            response = await client.post(
                f"{SERVICE_CONFIG['posts']}/posts/",
                json=post_data,
                headers=headers,
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Create post error: {str(e)}")
            raise HTTPException(status_code=503, detail="Posts service unavailable")

@router.post("/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def like_post(
    post_id: int,
    authorization: str | None = Header(None),
):
    from app.utils.security import verify_token
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    headers = {"X-User-ID": str(user_id)}

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['posts']}/posts/{post_id}/like",
                headers=headers,
                timeout=10.0
            )
            response.raise_for_status()
            return Response(status_code=response.status_code)
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Like post error: {str(e)}")
            raise HTTPException(status_code=503, detail="Service unavailable")

@router.delete("/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_post(
    post_id: int,
    authorization: str | None = Header(None),
):
    from app.utils.security import verify_token
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    headers = {"X-User-ID": str(user_id)}

    async with httpx.AsyncClient() as client:
        try:
            response = await client.delete(
                f"{SERVICE_CONFIG['posts']}/posts/{post_id}/like",
                headers=headers,
                timeout=10.0
            )
            response.raise_for_status()
            return Response(status_code=response.status_code)
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Unlike post error: {str(e)}")
            raise HTTPException(status_code=503, detail="Service unavailable")

@router.post("/{post_id}/comments")
async def create_comment(
    post_id: int,
    request: Request,
    authorization: str | None = Header(None),
):
    from app.utils.security import verify_token
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    headers = {"X-User-ID": str(user_id)}

    data = await request.json()
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['posts']}/posts/{post_id}/comments",
                json=data,
                headers=headers
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Create comment error: {str(e)}")
            raise HTTPException(status_code=503, detail="Service unavailable")

@router.get("/{post_id}/comments")
async def get_comments(post_id: int):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['posts']}/posts/{post_id}/comments"
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Get comments error: {str(e)}")
            raise HTTPException(status_code=503, detail="Service unavailable")

@router.post("/generate-upload-signature")
async def generate_upload_signature_posts():
    """
    Igual que antes: /posts/generate-upload-signature
    Necesario para Flutter.
    """
    try:
        timestamp = int(time.time())
        params_to_sign = {
            "timestamp": timestamp,
            "folder": "pconstruct_posts",
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
        print(f"Error generating Cloudinary signature: {e}")
        raise HTTPException(status_code=500, detail="Could not generate upload signature")
