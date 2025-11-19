from http.client import responses
from fastapi import APIRouter, Request, HTTPException, status, Header, Response
from typing import Optional, Dict
import httpx # <-- Importar httpx
from app.config import SERVICE_CONFIG, logger # <-- Importar logger
from app.utils.http_forward import forward_request
from app.utils.security import verify_token
import uuid # <-- Importar uuid

router = APIRouter(prefix="/api/v1/builds", tags=["Builds"])

BUILD_SERVICE_URL = SERVICE_CONFIG.get("build")

if not BUILD_SERVICE_URL:
    raise RuntimeError("BUILD_SERVICE_URL no está configurado en SERVICE_CONFIG")

# --- Endpoints de Builds (Protegidos) ---

@router.post("/", status_code=status.HTTP_201_CREATED, response_model=None)
async def create_build(
    request: Request,
    authorization: str | None = Header(None)
):
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    username = token_data.get("username")
    if not user_id or not username:
        raise HTTPException(status_code=401, detail="Token inválido")

    auth_headers = {
        "X-User-ID": str(user_id),
        "X-User-Name": str(username)
    }
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/",
        custom_headers=auth_headers
    )

@router.get("/my-builds", response_model=None)
async def get_my_builds(
    request: Request,
    authorization: str | None = Header(None)
):
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    username = token_data.get("username")
    if not user_id or not username:
        raise HTTPException(status_code=401, detail="Token inválido")

    user_headers = {
        "X-User-ID": str(user_id),
        "X-User-Name": str(username)
    }
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/my-builds",
        custom_headers=user_headers
    )

@router.delete("/{build_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_build(
    build_id: uuid.UUID, # <-- VALIDACIÓN DE UUID
    request: Request,
    authorization: str | None = Header(None)
):
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido")

    user_headers = {"X-User-ID": str(user_id)}
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}",
        custom_headers=user_headers
    )

# --- RUTAS PÚBLICAS (MODIFICADAS para 'is_liked') ---

def _get_optional_user_id(authorization: str | None) -> Optional[str]:
    """Valida un token si existe, pero no falla si no está."""
    if not authorization:
        return None
    try:
        token_data = verify_token(authorization)
        return str(token_data.get("sub"))
    except HTTPException:
        return None # Token inválido o expirado, tratar como anónimo

@router.get("/community", response_model=None)
async def get_community_builds(
    request: Request,
    authorization: str | None = Header(None)
):
    """Obtiene builds, pasando User-ID si está logueado."""
    user_id = _get_optional_user_id(authorization)
    headers = {}
    if user_id:
        headers["X-User-ID"] = user_id

    async with httpx.AsyncClient() as client:
        try:
            target_url = f"{BUILD_SERVICE_URL}/api/v1/builds/community"
            
            # --- CORRECCIÓN AQUÍ: Añadir timeout explicito ---
            response = await client.get(
                target_url,
                headers=headers,
                params=request.query_params,
                timeout=30.0  # <--- Aumentamos a 30 segundos (antes era default ~5s)
            )
            response.raise_for_status()
            return response.json()
        except httpx.TimeoutException:
            # Loguear error específico de tiempo
            logger.error("Timeout al obtener community builds (Gemini tardó demasiado)")
            raise HTTPException(status_code=504, detail="La búsqueda inteligente tardó demasiado.")
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Get community builds error: {str(e)}")
            raise HTTPException(status_code=503, detail="Builds service unavailable")

@router.get("/{build_id}", response_model=None)
async def get_build_detail(
    build_id: uuid.UUID, # <-- VALIDACIÓN DE UUID
    request: Request,
    authorization: str | None = Header(None)
):
    """Obtiene el detalle de una build, pasando User-ID si está logueado."""
    user_id = _get_optional_user_id(authorization)
    headers = {}
    if user_id:
        headers["X-User-ID"] = user_id

    async with httpx.AsyncClient() as client:
        try:
            target_url = f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}"
            response = await client.get(target_url, headers=headers)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Get build detail error: {str(e)}")
            raise HTTPException(status_code=503, detail="Builds service unavailable")

# --- NUEVAS RUTAS DE LIKES (Protegidas) ---
@router.post("/{build_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def like_build(
    build_id: uuid.UUID,
    authorization: str | None = Header(None)
):
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido")
    
    headers = {"X-User-ID": str(user_id)}
    # Usamos forward_request sin 'request' porque no hay body
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}/like",
                headers=headers
            )
            response.raise_for_status()
            return Response(status_code=response.status_code)
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())

@router.delete("/{build_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_build(
    build_id: uuid.UUID,
    authorization: str | None = Header(None)
):
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido")
    
    headers = {"X-User-ID": str(user_id)}
    async with httpx.AsyncClient() as client:
        try:
            response = await client.delete(
                f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}/like",
                headers=headers
            )
            response.raise_for_status()
            return Response(status_code=response.status_code)
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())

# --- NUEVAS RUTAS DE COMENTARIOS ---
@router.post("/{build_id}/comments", response_model=None)
async def create_build_comment(
    build_id: uuid.UUID,
    request: Request,
    authorization: str | None = Header(None)
):
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    username = token_data.get("username")
    if not user_id or not username:
        raise HTTPException(status_code=401, detail="Token inválido")
    
    headers = {
        "X-User-ID": str(user_id),
        "X-User-Name": str(username)
    }
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}/comments",
        custom_headers=headers
    )

@router.get("/{build_id}/comments", response_model=None)
async def get_build_comments(
    build_id: uuid.UUID,
    request: Request
):
    """Obtiene los comentarios de una build (ruta pública)."""
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}/comments"
    )

# --- RUTAS DE GEMINI (sin cambios) ---
@router.post("/check-compatibility", response_model=None)
async def check_compatibility(request: Request):
    # (Te recomiendo aplicar la misma lógica de timeout aquí)
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/check-compatibility"
    )
    
@router.post("/chat", response_model=None)
async def chat(request: Request):
    # Definimos un timeout largo, 30s es lo que espera tu app
    CHAT_TIMEOUT = 30.0

    try:
        data = await request.json()
    except Exception:
        data = {}

    # Usamos httpx.AsyncClient directamente
    async with httpx.AsyncClient() as client:
        try:
            target_url = f"{BUILD_SERVICE_URL}/api/v1/builds/chat"
            
            # Pasamos los headers originales de la app (auth, etc.)
            # Excluimos 'host' y 'content-length' que son manejados por httpx
            fwd_headers = {
                k: v for k, v in request.headers.items() 
                if k.lower() not in ('host', 'content-length', 'content-type')
            }
            # Aseguramos el content-type
            fwd_headers['Content-Type'] = 'application/json'

            response = await client.post(
                target_url,
                json=data,
                headers=fwd_headers,
                timeout=CHAT_TIMEOUT # <-- ¡Aquí está la corrección!
            )
            response.raise_for_status()
            
            # Devolvemos la respuesta del servicio de builds
            return response.json()

        except httpx.TimeoutException:
            logger.error(f"Timeout (>{CHAT_TIMEOUT}s) con el servicio de chat: {target_url}")
            raise HTTPException(status_code=504, detail="El servicio de chat tardó demasiado en responder.")
        except httpx.HTTPStatusError as e:
            logger.error(f"Error del servicio de builds (chat): {e.response.status_code} - {e.response.text}")
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Error inesperado en forward de chat: {str(e)}")
            raise HTTPException(status_code=503, detail="Servicio de chat no disponible")