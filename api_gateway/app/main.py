import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers.auth_router import router as auth_router
from app.routers.builds_router import router as builds_router
from app.routers.components_router import router as components_router
from app.routers.prices_router import router as prices_router
from app.routers.health_router import router as health_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - api_gateway - %(levelname)s - %(message)s",
)
logger = logging.getLogger("api_gateway")

app = FastAPI(title="PConstruct API Gateway", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(builds_router)
app.include_router(components_router)
app.include_router(prices_router)
app.include_router(health_router)
