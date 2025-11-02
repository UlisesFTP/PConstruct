from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import logger
from app.routers.health_router import router as health_router
from app.routers.auth_router import router as auth_router
from app.routers.users_router import router as users_router
from app.routers.posts_router import router as posts_router
from app.routers.components_router import router as components_router
from app.routers.builds_router import router as builds_router
from app.routers.pricing_router import router as pricing_router
from app.routers.benchmark_router import router as benchmark_router
from app.routers.search_router import router as search_router

app = FastAPI(
    title="PC Builder API Gateway",
    description="API Gateway para el sistema distribuido de PC Builder",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # en prod lo cierras
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Montamos todos los routers con las mismas rutas externas que ya usaba Flutter
app.include_router(health_router)
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(posts_router)
app.include_router(components_router)
app.include_router(builds_router)
app.include_router(pricing_router)
app.include_router(benchmark_router)
app.include_router(search_router)

# Opcional: error handlers globales, si quieres conservarlos puedes recrearlos aquí
from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": True,
            "message": exc.detail,
            "status_code": exc.status_code,
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
            "status_code": 500,
        },
    )
