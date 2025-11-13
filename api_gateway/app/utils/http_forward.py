# api_gateway/app/utils/http_forward.py
import httpx
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse, Response
import json
from app.config import logger # Asegúrate de que tu config.py tenga 'logger'

async def forward_request(
    request: Request, 
    target_url: str, 
    custom_headers: dict = {}
):
    """
    Reenvía una petición de FastAPI a otro microservicio.
    """
    # Obtenemos el cliente httpx global desde el estado de la app
    # (Tu main.py lo crea como app.state.http)
    http_client = request.app.state.http 
    
    url = httpx.URL(
        url=target_url, 
        query=request.url.query.encode("utf-8")
    )
    
    # Prepara los headers
    headers = {
        key: value for key, value in request.headers.items() 
        if key.lower() not in ('host', 'content-length', 'transfer-encoding', 'connection')
    }
    headers.update(custom_headers) # Añade nuestros headers (ej. X-User-ID)

    # Prepara el contenido (body)
    try:
        body_bytes = await request.body()
    except Exception:
        body_bytes = None
    
    timeout_str = custom_headers.get("X-Forward-Timeout") or request.headers.get("X-Forward-Timeout")
    try:
        _t = float(timeout_str) if timeout_str else 10.0
    except Exception:
        _t = 10.0

    response = await http_client.request(
        method=request.method,
        url=url,
        headers=headers,
        content=body_bytes,
        timeout=httpx.Timeout(_t, connect=5.0, read=_t, write=_t)
    )
    
    
    try:
        # Intenta hacer la petición al microservicio
        response = await http_client.request(
            method=request.method,
            url=url,
            headers=headers,
            content=body_bytes,
            timeout=10.0  # Timeout de 10 segundos
        )

        # Devuelve la respuesta del microservicio tal cual
        return Response(
            content=response.content,
            status_code=response.status_code,
            media_type=response.headers.get("content-type")
        )

    except httpx.ConnectError as e:
        # Error si el microservicio está caído
        logger.error(f"Error de conexión con el servicio: {target_url} - {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Error de conexión con el servicio: {target_url}"
        )
    except httpx.ReadTimeout as e:
        # Error si el microservicio tarda demasiado
        logger.error(f"Timeout con el servicio: {target_url} - {e}")
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail=f"El servicio tardó demasiado en responder: {target_url}"
        )
    except Exception as e:
        logger.error(f"Error interno del Gateway: {e}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": True, "message": f"Error interno del Gateway: {str(e)}"}
        )