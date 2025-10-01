# main.py - API Gateway principal
from fastapi import FastAPI, Depends, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Dict, List, Optional, Any
import httpx
import os
import time
import jwt
from datetime import datetime, timedelta
import logging  # ← AÑADIR ESTE IMPORT

# ← AÑADIR CONFIGURACIÓN DE LOGGING AQUÍ
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("api_gateway")

# Resto de tu código...


# Inicializar la aplicación FastAPI
app = FastAPI(
    title="PC Builder API Gateway",
    description="API Gateway para el sistema distribuido de PC Builder",
    version="1.0.0",
)

# Configuración CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar los orígenes permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración de servicios
SERVICE_CONFIG = {
    "user": os.getenv("USER_SERVICE_URL", "http://user-service:8001"),
    "component": os.getenv("COMPONENT_SERVICE_URL", "http://component-service:8002"),
    "build": os.getenv("BUILD_SERVICE_URL", "http://build-service:8003"),
    "price": os.getenv("PRICE_SERVICE_URL", "http://price-service:8004"),
    "benchmark": os.getenv("BENCHMARK_SERVICE_URL", "http://benchmark-service:8005"),
}

# Configuración JWT
JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION = 60 * 24  # 24 horas

# Middleware para medir tiempo de respuesta
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    logger.info(f"Request processed in {process_time:.4f} seconds")
    return response

# Función para verificar JWT
def verify_token(authorization: str = Depends(lambda x: x.headers.get("Authorization"))):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

# Rutas públicas (sin autenticación)
@app.get("/")
async def root():
    return {"message": "PC Builder API Gateway", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Verificar el estado de salud de todos los servicios"""
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

# Rutas de autenticación
@app.post("/auth/login")
async def login(credentials: Dict[str, str]):
    """Autenticar usuario y generar token JWT"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/login",
                json=credentials
            )
            user_data = response.json()
            
            if response.status_code != 200:
                return JSONResponse(status_code=response.status_code, content=user_data)
                
            # Generar token JWT
            expiration = datetime.utcnow() + timedelta(minutes=JWT_EXPIRATION)
            token_data = {
                "sub": str(user_data["id"]),
                "email": user_data["email"],
                "role": user_data["role"],
                "exp": expiration
            }
            token = jwt.encode(token_data, JWT_SECRET, algorithm=JWT_ALGORITHM)
            
            return {
                "access_token": token,
                "token_type": "bearer",
                "expires_at": expiration.isoformat(),
                "user": user_data
            }
        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )

@app.post("/auth/register")
async def register(user_data: Dict[str, Any]):
    """Registrar un nuevo usuario"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['user']}/auth/register",
                json=user_data
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Register error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )

# Rutas para el servicio de usuario
@app.get("/users/me", dependencies=[Depends(verify_token)])
async def get_current_user(token_data: Dict = Depends(verify_token)):
    """Obtener información del usuario actual"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['user']}/users/{token_data['sub']}",
                headers={"X-User-ID": token_data["sub"]}
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get user error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )

# Rutas para componentes
@app.get("/components")
async def get_components(
    category: Optional[str] = None,
    brand: Optional[str] = None,
    limit: int = 50,
    offset: int = 0
):
    """Obtener listado de componentes con filtros opcionales"""
    params = {"limit": limit, "offset": offset}
    if category:
        params["category"] = category
    if brand:
        params["brand"] = brand
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['component']}/components",
                params=params
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get components error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable"
            )

@app.get("/components/{component_id}")
async def get_component(component_id: str):
    """Obtener detalle de un componente específico"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['component']}/components/{component_id}"
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get component error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable"
            )

@app.post("/compatibility/check")
async def check_compatibility(components: List[Dict[str, str]]):
    """Verificar compatibilidad entre componentes"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['component']}/compatibility/check",
                json={"components": components}
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Compatibility check error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Component service unavailable"
            )

# Rutas para builds
@app.post("/builds/recommend")
async def recommend_build(
    requirements: Dict[str, Any],
    token_data: Optional[Dict] = Depends(lambda: None)
):
    """Recomendar una build según requerimientos y presupuesto"""
    # Agregar token de usuario si está autenticado
    headers = {}
    if token_data:
        headers["X-User-ID"] = token_data["sub"]
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['build']}/builds/recommend",
                json=requirements,
                headers=headers
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
    """Obtener builds guardadas del usuario"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['build']}/builds/user/{token_data['sub']}",
                headers={"X-User-ID": token_data["sub"]}
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get saved builds error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Build service unavailable"
            )

# Rutas para precios y benchmark
@app.get("/prices/{component_id}")
async def get_component_prices(
    component_id: str, 
    country: Optional[str] = None
):
    """Obtener precios actuales e históricos de un componente"""
    params = {}
    if country:
        params["country"] = country
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['price']}/prices/{component_id}",
                params=params
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Get prices error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Price service unavailable"
            )

@app.post("/benchmark/estimate")
async def estimate_performance(build: Dict[str, Any]):
    """Estimar rendimiento de una build para diferentes escenarios"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{SERVICE_CONFIG['benchmark']}/benchmark/estimate",
                json=build
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Benchmark estimation error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Benchmark service unavailable"
            )

@app.get("/benchmark/compare")
async def compare_builds(
    build_ids: List[str],
    scenario: Optional[str] = None
):
    """Comparar rendimiento entre diferentes builds"""
    params = {"build_ids": ",".join(build_ids)}
    if scenario:
        params["scenario"] = scenario
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{SERVICE_CONFIG['benchmark']}/benchmark/compare",
                params=params
            )
            return JSONResponse(status_code=response.status_code, content=response.json())
        except Exception as e:
            logger.error(f"Benchmark comparison error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Benchmark service unavailable"
            )

# Manejadores de errores personalizados
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)