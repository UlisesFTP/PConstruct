from fastapi import APIRouter, Request, HTTPException, status, Header
from typing import Optional, Dict

# Importamos tu forwarder y tu validador de token
from app.utils.http_forward import forward_request
from app.utils.security import verify_token
from app.config import SERVICE_CONFIG

router = APIRouter(prefix="/api/v1/builds", tags=["Builds"])

BUILD_SERVICE_URL = SERVICE_CONFIG.get("build")

if not BUILD_SERVICE_URL:
    raise RuntimeError("BUILD_SERVICE_URL no está configurado en SERVICE_CONFIG")

# --- ¡FUNCIÓN ELIMINADA! ---
# Ya no usamos _get_auth_headers, usaremos verify_token

# --- Endpoints de Builds (Corregidos) ---

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_build(
    request: Request,
    authorization: str | None = Header(None) # <-- ¡Como en tu posts_router!
):
    """
    Crea una nueva build. (Ruta protegida)
    """
    # 1. Validar token y obtener datos del usuario
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    username = token_data.get("username")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido, falta 'sub' (user_id)")

    # 2. Preparar headers para el microservicio
    auth_headers = {
        "X-User-ID": str(user_id),
        "X-User-Name": str(username)
    }

    # 3. Reenviar
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/",
        custom_headers=auth_headers
    )

@router.get("/my-builds")
async def get_my_builds(
    request: Request,
    authorization: str | None = Header(None) # <-- ¡Como en tu posts_router!
):
    """
    Obtiene las builds del usuario autenticado. (Ruta protegida)
    """
    # 1. Validar token y obtener user_id
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    username = token_data.get("username") # <-- Lo pide el builds-service
    if not user_id or not username:
        raise HTTPException(status_code=401, detail="Token inválido")

    # 2. Preparar headers
    user_headers = {
        "X-User-ID": str(user_id),
        "X-User-Name": str(username) # <-- Header que faltaba
    }

    # 3. Reenviar
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/my-builds",
        custom_headers=user_headers
    )

@router.delete("/{build_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_build(
    build_id: str, 
    request: Request,
    authorization: str | None = Header(None) # <-- ¡Como en tu posts_router!
):
    """
    Elimina una build (si eres el propietario). (Ruta protegida)
    """
    # 1. Validar token
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    username = token_data.get("username")
    if not user_id or not username:
        raise HTTPException(status_code=401, detail="Token inválido")

    # 2. Preparar headers
    user_headers = {
        "X-User-ID": str(user_id),
        "X-User-Name": str(username)
    }

    # 3. Reenviar
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}",
        custom_headers=user_headers
    )

# --- RUTAS PÚBLICAS (Sin cambios) ---

@router.get("/community")
async def get_community_builds(request: Request):
    """
    Obtiene las builds públicas de la comunidad. (Ruta pública)
    """
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/community"
    )

@router.get("/{build_id}")
async def get_build_detail(build_id: str, request: Request):
    """
    Obtiene el detalle de una build específica. (Ruta pública)
    """
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/{build_id}"
    )

@router.post("/check-compatibility")
async def check_compatibility(request: Request):
    """
    Verifica la compatibilidad de un conjunto de componentes. (Ruta pública)
    """
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/check-compatibility"
    )
    
@router.post("/chat")
async def chat(request: Request):
    return await forward_request(
        request=request,
        target_url=f"{BUILD_SERVICE_URL}/api/v1/builds/chat",
        custom_headers={"X-Forward-Timeout": "30"}  # 30s solo para /chat
    )
