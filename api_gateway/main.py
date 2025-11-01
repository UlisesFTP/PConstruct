# main.py - API Gateway principal
import json
from fastapi import FastAPI, Depends, HTTPException, Request, status, Header, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Dict, List, Optional, Any
import httpx
import os
import time
import jwt
from datetime import datetime, timedelta
import logging
import asyncio
from jwt_utils import verify_token 
import schemas 
import cloudinary
import cloudinary.uploader
import cloudinary.api
from fastapi.responses import JSONResponse
from fastapi import APIRouter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("api_gateway")

app = FastAPI(
    title="PC Builder API Gateway",
    description="API Gateway para el sistema distribuido de PC Builder",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SERVICE_CONFIG = {
    "user": os.getenv("USER_SERVICE_URL", "http://user-service:8001"),
    "posts": os.getenv("POSTS_SERVICE_URL", "http://posts-service:8002"),
    "component": os.getenv("COMPONENT_SERVICE_URL", "http://component-service:8003"),
    "build": os.getenv("BUILD_SERVICE_URL", "http://build-service:8004"),
    "price": os.getenv("PRICE_SERVICE_URL", "http://price-service:8005"),
    "benchmark": os.getenv("BENCHMARK_SERVICE_URL", "http://benchmark-service:8006"),
}



cloudinary.config( 
    cloud_name = os.getenv("CLOUDINARY_CLOUD_NAME"), 
    api_key = os.getenv("CLOUDINARY_API_KEY"), 
    api_secret = os.getenv("CLOUDINARY_API_SECRET"),
    secure = True # Usa HTTPS
)


JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION = 60 * 24

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    logger.info(f"Request processed in {process_time:.4f} seconds")
    return response


@app.get("/")
async def root():
    return {"message": "PC Builder API Gateway", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    results = {}
    async with httpx.AsyncClient() as client:
        for service_name, service_url in SERVICE_CONFIG.items():
            try:
                resp = await client.get(f"{service_url}/health", timeout=2.0)
                results[service_name] = {
                    "status": "up" if resp.status_code == 200 else "down",
                    "details": resp.json() if resp.status_code == 200 else None
                }
            except Exception as e:
                results[service_name] = {"status": "down", "error": str(e)}
    
    overall_status = all(r["status"] == "up" for r in results.values())
    return {
        "timestamp": datetime.now().isoformat(),
        "status": "healthy" if overall_status else "degraded",
        "services": results
    }

# PConstruct/api_gateway/main.py

@app.post("/auth/login")
async def login(credentials: Dict[str, str]):
    """Autenticar usuario y generar token JWT"""
    async with httpx.AsyncClient() as client:
        try:
            # Esta llamada al user-service es exitosa (devuelve 200 OK)
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/login",
                json=credentials,
                timeout=30.0
            )
            
            # La respuesta del user-service tiene la forma: {"access_token": ..., "user": {...}}
            user_data_from_service = response.json()
            
            if response.status_code != 200:
                return JSONResponse(status_code=response.status_code, content=user_data_from_service)

            # --- CORRECCIÓN AQUÍ ---
            # Extraemos el perfil del usuario del objeto anidado
            user_profile = user_data_from_service["user"]
            
            # Generar el token JWT del Gateway usando los campos correctos
            expiration = datetime.utcnow() + timedelta(minutes=JWT_EXPIRATION)
            token_data = {
                "sub": str(user_profile["user_id"]), # <-- Usamos user_profile["user_id"]
                "email": user_profile["email"],
                "role": user_profile["role"],
                "exp": expiration
            }
            # ---------------------
            
            token = jwt.encode(token_data, JWT_SECRET, algorithm=JWT_ALGORITHM)
            
            return {
                "access_token": token,
                "token_type": "bearer",
                "expires_at": expiration.isoformat(),
                "user": user_profile # Reutilizamos el perfil que ya extrajimos
            }
        except Exception as e:
            logger.error(f"Login error: {e}") # Logueamos el error real ('id')
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable or response format error"
            )
            
@app.post("/auth/register")
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

@app.post("/auth/verify-email")
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

@app.post("/auth/resend-verification")
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

@app.get("/users/me", dependencies=[Depends(verify_token)])
async def get_current_user(token_data: Dict = Depends(verify_token)):
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


        
@app.get("/posts/") # Ya no necesita 'dependencies' aquí si queremos permitir anónimos
async def get_posts(request: Request, token_data: Optional[Dict] = Depends(verify_token) if True else None):
    """
    Reenvía la petición para obtener el feed. 
    Si hay token, pasa el user_id al posts-service.
    """
    headers = {}
    if token_data and token_data.get("sub"):
        headers["X-User-ID"] = str(token_data["sub"]) # Pasamos el ID si está autenticado
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['posts']}/posts/",
                headers=headers, # Enviamos la cabecera X-User-ID (si existe)
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()
        
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Get posts error: {str(e)}")
            raise HTTPException(status_code=503, detail="Posts service unavailable")


# --- Endpoint para Crear Posts (YA CORREGIDO) ---
@app.post("/posts/")
async def create_post(
    post_data: schemas.PostCreate, 
    token_data: Dict = Depends(verify_token) 
):
    """Reenvía la creación de una publicación al posts-service, pasando el user_id."""
    user_id = token_data.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token: missing user ID")

    async with httpx.AsyncClient() as client:
        try:
            headers = {"X-User-ID": str(user_id)}
            response = await client.post(
                f"{SERVICE_CONFIG['posts']}/posts/",
                json=post_data.model_dump(),
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



@app.post("/posts/generate-upload-signature")
async def generate_upload_signature(token_data: Dict = Depends(verify_token)):
    """
    Genera una firma segura para que el cliente (Flutter) pueda
    subir una imagen directamente a Cloudinary.
    """
    try:
        timestamp = int(time.time())
        params_to_sign = {
            "timestamp": timestamp,
            "folder": "pconstruct_posts",
            "upload_preset": "ml_default" # <-- El preset que confirmaste
        }
        # ----------------------------------------
        
        signature = cloudinary.utils.api_sign_request(
            params_to_sign, 
            os.getenv("CLOUDINARY_API_SECRET")
        )
        
        # Devuelve al cliente todo lo que necesita para la subida
        return {
            "signature": signature,
            "timestamp": timestamp,
            "api_key": os.getenv("CLOUDINARY_API_KEY")
        }
    except Exception as e:
        logger.error(f"Error generating Cloudinary signature: {e}")
        raise HTTPException(status_code=500, detail="Could not generate upload signature")



@app.post("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def proxy_like_post(
    post_id: int,
    token_data: Dict = Depends(verify_token)
):
    """
    Proxy para añadir un like a un post. Protegido por token.
    """
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

            # --- CORRECTION HERE ---
            # Instead of returning response(), create an instance
            return Response(status_code=response.status_code)
            # --- END CORRECTION ---

        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Like post error: {str(e)}") # Log still helpful
            raise HTTPException(status_code=503, detail="Service unavailable")




@app.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def proxy_unlike_post(
    post_id: int, 
    token_data: Dict = Depends(verify_token)
):
    """Proxy para eliminar un like de un post. Protegido por token."""
    user_id = token_data.get("sub")
    headers = {"X-User-ID": str(user_id)}
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.delete( # <-- Usa client.delete
                f"{SERVICE_CONFIG['posts']}/posts/{post_id}/like",
                headers=headers,
                timeout=10.0
            )
            response.raise_for_status()
            return Response(status_code=response.status_code) # Devuelve 204

        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Unlike post error: {str(e)}")
            raise HTTPException(status_code=503, detail="Service unavailable")



@app.post("/posts/{post_id}/comments")
async def proxy_create_comment(
    post_id: int,
    request: Request, # Tomamos el request para pasar el body
    token_data: Dict = Depends(verify_token)
):
    """Proxy para crear un comentario. Protegido por token."""
    user_id = token_data.get("sub")
    headers = {"X-User-ID": str(user_id)}
    
    try:
        data = await request.json() # Leemos el body (ej. {"content": "..."})
        async with httpx.AsyncClient() as client:
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



@app.get("/posts/{post_id}/comments")
async def proxy_get_comments(post_id: int):
    """Proxy para obtener los comentarios de un post."""
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



@app.get("/components")
async def get_components(request: Request): # Cambia los parámetros a solo 'request'
    params = request.query_params # Obtén los query params desde el request
        
    async with httpx.AsyncClient() as client:
        try:
            # === CORRECCIÓN AQUÍ ===
            # 1. Añade la barra al final de la URL -> "/components/"
            # 2. Añade follow_redirects=True por robustez
            response = await client.get(
                f"{SERVICE_CONFIG['component']}/components/", # <-- AÑADIR BARRA AL FINAL
                params=params, # Pasar los query params
                timeout=30.0,
                follow_redirects=True # <-- AÑADIR ESTO
            )
            # =======================
            
            # Lanza un error si la respuesta del servicio fue 4xx o 5xx
            response.raise_for_status() 
            
            # Devuelve el JSON si todo salió bien
            # Usar JSONResponse asegura el tipo de contenido correcto
            return JSONResponse(status_code=response.status_code, content=response.json())

        except httpx.HTTPStatusError as e:
            # Si el servicio devuelve un error (ej. 404, 500), reenvíalo
            try:
                detail = e.response.json()
            except json.JSONDecodeError:
                detail = e.response.text # Fallback si el error no es JSON
            raise HTTPException(status_code=e.response.status_code, detail=detail)
        
        except (httpx.RequestError, json.JSONDecodeError) as e:
            # Capturar errores de conexión (ej. "All connection attempts failed")
            # o si la respuesta 200 no fue JSON (como el 307)
            logger.error(f"Get components error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable or returned invalid response"
            )
            
@app.get("/components/{component_id}")
async def get_component(component_id: int): # Usar int si el ID es numérico
    service_url = SERVICE_CONFIG['component']
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{service_url}/components/{component_id}",
                timeout=30.0
            )
            # Manejar 404 del servicio
            if response.status_code == 404:
                 raise HTTPException(status_code=404, detail="Component not found")
            response.raise_for_status() # Lanza excepción para otros errores >= 400
            return response.json()
        except Exception as e:
            logger.error(f"Get component error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable"
            )


@app.post("/compatibility/check")
async def check_compatibility(components: List[Dict[str, str]]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['component']}/compatibility/check",
                json={"components": components},
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Compatibility check error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable"
            )



def extract_user_id_from_authorization(authorization: str | None) -> int:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falta Authorization header",
        )
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Formato de Authorization inválido",
        )
    token = authorization.split(" ", 1)[1]
    payload = verify_token(token)
    user_id = payload.get("user_id") or payload.get("id") or payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sin user_id",
        )
    try:
        return int(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="user_id inválido en token",
        )





@app.post("/builds", status_code=201)
async def create_build_proxy(
    request: Request,
    authorization: str = Header(None),
):
    user_id = extract_user_id_from_authorization(authorization)
    body = await request.json()

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{SERVICE_CONFIG['build']}/builds/",
            json=body,
            headers={"X-User-Id": str(user_id)},
            timeout=10.0,
        )

    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json(),
    )


@app.get("/builds/community")
async def get_community_builds_proxy(
    skip: int = 0,
    limit: int = 20,
):
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{SERVICE_CONFIG['build']}/builds/community",
            params={"skip": skip, "limit": limit},
            timeout=10.0,
        )
    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json(),
    )




@app.get("/builds/{build_id}")
async def get_build_detail_proxy(
    build_id: int,
    authorization: str = Header(None),
):
    headers = {}
    if authorization:
        try:
            uid = extract_user_id_from_authorization(authorization)
            headers["X-User-Id"] = str(uid)
        except HTTPException:
            pass

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{SERVICE_CONFIG['build']}/builds/{build_id}",
            headers=headers,
            timeout=10.0,
        )

    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json() if resp.content else None,
    )


@app.get("/builds/mine")
async def get_my_builds_proxy(
    authorization: str = Header(None),
):
    user_id = extract_user_id_from_authorization(authorization)

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{SERVICE_CONFIG['build']}/builds/mine",
            headers={"X-User-Id": str(user_id)},
            timeout=10.0,
        )

    return JSONResponse(
        status_code=resp.status_code,
        content=resp.json(),
    )


@app.post("/builds/recommend")
async def recommend_build(requirements: Dict[str, Any], token_data: Optional[Dict] = Depends(lambda: None)):
    headers = {}
    if token_data:
        headers["X-User-ID"] = token_data["sub"]
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['build']}/builds/recommend",
                json=requirements,
                headers=headers,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Build recommendation error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Build service unavailable"
            )

@app.get("/builds/saved", dependencies=[Depends(verify_token)])
async def get_saved_builds(token_data: Dict = Depends(verify_token)):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['build']}/builds/user/{token_data['sub']}",
                headers={"X-User-ID": token_data["sub"]},
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get saved builds error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Build service unavailable"
            )
            
            
@app.get("/prices/{component_id}")
async def get_component_prices(component_id: int, request: Request): # Usar int, pasar request
    service_url = SERVICE_CONFIG['price']
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{service_url}/prices/{component_id}",
                params=request.query_params, # Reenvía query params (ej. country)
                timeout=30.0
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Get prices error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Price service unavailable"
            )
            
            
            
            
@app.post("/prices/refresh", status_code=202)
async def trigger_price_refresh(request_body: Dict[str, List[Any]]): # Espera {"component_ids": [...], "countries": [...]}
    service_url = SERVICE_CONFIG['price']
    async with httpx.AsyncClient() as client:
        try:
            # Reenvía el body al servicio de pricing
            response = await client.post(
                f"{service_url}/prices/refresh",
                json=request_body,
                timeout=10.0 # Timeout corto, es una tarea de fondo
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
             raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.error(f"Trigger price refresh error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Pricing service unavailable"
            )

@app.post("/benchmark/estimate")
async def estimate_performance(build: Dict[str, Any]):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['benchmark']}/benchmark/estimate",
                json=build,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Benchmark estimation error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Benchmark service unavailable"
            )

@app.get("/benchmark/compare")
async def compare_builds(build_ids: List[str], scenario: Optional[str] = None):
    params = {"build_ids": ",".join(build_ids)}
    if scenario:
        params["scenario"] = scenario
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['benchmark']}/benchmark/compare",
                params=params,
                timeout=30.0
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Benchmark comparison error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Benchmark service unavailable"
            )

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": True,
            "message": exc.detail,
            "status_code": exc.status_code
        },
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": True,
            "message": "Internal server error",
            "status_code": 500
        },
    )




@app.post("/auth/request-password-reset")
async def request_password_reset(request_data: Dict[str, Any]):
    """Reenvía la solicitud de reseteo de contraseña."""
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

@app.post("/auth/reset-password")
async def reset_password(request_data: Dict[str, Any]):
    """Reenvía la confirmación de reseteo de contraseña."""
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


@app.get("/search/")
async def search_all(q: str):
    """
    Busca en múltiples servicios (posts y usuarios) de forma concurrente
    y agrega los resultados.
    """
    async with httpx.AsyncClient(timeout=10.0) as client:
        # Preparamos las tareas para ejecutarlas en paralelo
        post_search_task = client.get(
            f"{SERVICE_CONFIG['posts']}/posts/search/", 
            params={'q': q}
        )
        user_search_task = client.get(
            f"{SERVICE_CONFIG['user']}/users/search/",
            params={'q': q}
        )

        # Ejecutamos las tareas concurrentemente
        results = await asyncio.gather(
            post_search_task,
            user_search_task,
            return_exceptions=True # Para que no falle todo si un servicio no responde
        )

        # Procesamos los resultados
        posts_response, users_response = results
        
        posts = []
        if isinstance(posts_response, httpx.Response) and posts_response.status_code == 200:
            posts = posts_response.json()

        users = []
        if isinstance(users_response, httpx.Response) and users_response.status_code == 200:
            users = users_response.json()

        return {"posts": posts, "users": users}
    

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)