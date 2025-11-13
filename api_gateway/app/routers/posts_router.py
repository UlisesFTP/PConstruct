from fastapi import APIRouter, HTTPException, Request, Header, status, Response
from fastapi.responses import JSONResponse
import httpx
from typing import Dict, Optional
from app.config import SERVICE_CONFIG, logger, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
import time
import cloudinary
import cloudinary.uploader
import cloudinary.api
from fastapi import WebSocket, WebSocketDisconnect
import websockets # Nueva dependencia necesaria
import asyncio



router = APIRouter(prefix="/posts", tags=["posts"])

@router.get("/")
async def get_posts(request: Request, authorization: str | None = Header(None)):
    headers = {}
    if authorization:
        # si hay token, extraemos user_id
        from app.utils.security import verify_token
        token_data = verify_token(authorization)
        if token_data and token_data.get("sub"):
            headers["X-User-ID"] = str(token_data["sub"])

    # --- Novedad: Leer query params ---
    # Obtenemos el parámetro 'sort_by' del request original
    sort_by = request.query_params.get("sort_by", "recent")
    params = {"sort_by": sort_by}
    # (También podríamos pasar 'skip' y 'limit' si quisiéramos paginar desde el gateway)
    # --- Fin Novedad ---

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['posts']}/posts/",
                headers=headers,
                params=params, # Reenviamos los parámetros al microservicio
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
        
        
        
@router.websocket("/ws/feed")
async def websocket_proxy(client_ws: WebSocket):
    """
    Proxy de WebSocket.
    - Tarea 1: Escucha al 'posts-service' y reenvía a 'client_ws'.
    - Tarea 2: Escucha al 'client_ws' (para pings) y descarta los mensajes.
    """
    await client_ws.accept()
    
    # Construye la URL interna del WebSocket
    service_url = f"{SERVICE_CONFIG['posts']}/ws/feed".replace("http", "ws")
    
    try:
        # Se conecta al WebSocket del microservicio
        async with websockets.connect(service_url) as server_ws:
            
            # Tarea 1: Reenviar mensajes del SERVIDOR al CLIENTE
            async def server_to_client():
                try:
                    while True:
                        data = await server_ws.recv()
                        await client_ws.send_text(data)
                except websockets.exceptions.ConnectionClosed:
                    print("Proxy: Conexión del servicio (servidor) cerrada.")
                except Exception as e:
                    print(f"Proxy: Error en server_to_client: {e}")

            # Tarea 2: Mantener viva la conexión del cliente (consumir pings)
            async def client_keep_alive():
                try:
                    while True:
                        # Solo leemos y descartamos.
                        await client_ws.receive_text()
                except WebSocketDisconnect:
                    print("Proxy: Conexión del cliente (Flutter) cerrada.")
                except Exception as e:
                    print(f"Proxy: Error en client_keep_alive: {e}")

            # Ejecuta ambas tareas concurrentemente
            await asyncio.gather(server_to_client(), client_keep_alive())
            
    except (WebSocketDisconnect, websockets.exceptions.ConnectionClosed) as e:
        print(f"WebSocket proxy disconnected: {type(e).__name__}")
    except Exception as e:
        # Esto captura errores al *conectar* (ej. si el posts-service está caído)
        print(f"WebSocket proxy error al conectar: {e}")
    finally:
        # Aseguramos que el cliente sea notificado si el proxy falla
        await client_ws.close()
        
        
        
         

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