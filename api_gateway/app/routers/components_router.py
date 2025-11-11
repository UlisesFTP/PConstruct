from fastapi import APIRouter, HTTPException, Request, Header, status
from fastapi.responses import JSONResponse
from typing import Dict, Any, Optional
import httpx

from app.config import SERVICE_CONFIG, logger
from app.utils.security import verify_token # Usamos tu validador de token

router = APIRouter(prefix="/components", tags=["3. Components"])

# Obtenemos la URL base del microservicio desde la configuración
SERVICE_URL = SERVICE_CONFIG.get("component")
if not SERVICE_URL:
    logger.error("COMPONENT_SERVICE_URL no está configurado")
    raise ImportError("COMPONENT_SERVICE_URL no está configurado")


@router.get(
    "/",
    summary="[Proxy] Obtener lista de componentes con filtros"
)
async def get_component_list(request: Request):
    """
    Reenvía la solicitud de lista de componentes al microservicio,
    incluyendo todos los query parameters (filtros, paginación, etc.).
    """
    async with httpx.AsyncClient() as client:
        try:
            # Reenviamos los query params tal como llegan
            params = request.query_params
            resp = await client.get(
                f"{SERVICE_URL}/api/v1/components/",
                params=params,
                timeout=10.0
            )
            return JSONResponse(status_code=resp.status_code, content=resp.json())
        except Exception as e:
            logger.error(f"Error reenviando a components-service (GET /): {e}")
            raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Servicio de componentes no disponible")


@router.get(
    "/{component_id}",
    summary="[Proxy] Obtener detalle de un componente"
)
async def get_component_detail(component_id: int):
    """
    Reenvía la solicitud de detalle de un componente.
    """
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(
                f"{SERVICE_URL}/api/v1/components/{component_id}",
                timeout=10.0
            )
            return JSONResponse(status_code=resp.status_code, content=resp.json())
        except Exception as e:
            logger.error(f"Error reenviando a components-service (GET /{component_id}): {e}")
            raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Servicio de componentes no disponible")


@router.post(
    "/{component_id}/reviews",
    status_code=status.HTTP_201_CREATED,
    summary="[Proxy] Crear una nueva reseña (Protegido)"
)
async def create_new_review(
    component_id: int,
    request: Request,
    authorization: str = Header(...)
):
    """
    (Protegido) Reenvía la creación de una reseña.
    Valida el token y añade el 'X-User-ID' para el microservicio.
    """
    # 1. Validar Token (Patrón existente en tu gateway)
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido, falta 'sub' (user_id)")
    
    # 2. Preparar reenvío
    headers = {"X-User-ID": str(user_id)}
    body = await request.json()
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                f"{SERVICE_URL}/api/v1/components/{component_id}/reviews",
                json=body,
                headers=headers,
                timeout=10.0
            )
            return JSONResponse(status_code=resp.status_code, content=resp.json())
        except Exception as e:
            logger.error(f"Error reenviando a components-service (POST .../reviews): {e}")
            raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Servicio de componentes no disponible")

@router.post(
    "/{component_id}/reviews/{review_id}/comments",
    status_code=status.HTTP_201_CREATED,
    summary="[Proxy] Crear un nuevo comentario (Protegido)"
)
async def create_new_comment(
    component_id: int,
    review_id: int,
    request: Request,
    authorization: str = Header(...)
):
    """
    (Protegido) Reenvía la creación de un comentario.
    Valida el token y añade el 'X-User-ID'.
    """
    # 1. Validar Token
    token_data: Dict = verify_token(authorization)
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido, falta 'sub' (user_id)")

    # 2. Preparar reenvío
    headers = {"X-User-ID": str(user_id)}
    body = await request.json()

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                f"{SERVICE_URL}/api/v1/components/{component_id}/reviews/{review_id}/comments",
                json=body,
                headers=headers,
                timeout=10.0
            )
            return JSONResponse(status_code=resp.status_code, content=resp.json())
        except Exception as e:
            logger.error(f"Error reenviando a components-service (POST .../comments): {e}")
            raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Servicio de componentes no disponible")