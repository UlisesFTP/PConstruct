from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import os, httpx, redis.asyncio as redis

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

REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
CACHE_TTL_SECONDS = int(os.getenv("CACHE_TTL_SECONDS", "86400"))

@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http = httpx.AsyncClient(timeout=httpx.Timeout(15.0, connect=5.0))
    app.state.redis = redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    app.state.cache_ttl = CACHE_TTL_SECONDS
    yield
    await app.state.http.aclose()
    await app.state.redis.aclose()

app = FastAPI(title="PC Builder API Gateway", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(posts_router)
app.include_router(components_router)
app.include_router(builds_router)
app.include_router(pricing_router)
app.include_router(benchmark_router)
app.include_router(search_router)

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"error": True, "message": exc.detail, "status_code": exc.status_code})

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, content={"error": True, "message": "Internal server error", "status_code": 500})
