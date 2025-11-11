from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.db.session import init_db
from app.api.v1.api import api_router 
from app.services.cache_service import init_redis, close_redis

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# --- Configuración de CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Eventos de Ciclo de Vida ---
@app.on_event("startup")
async def startup_event():
    print("Iniciando servicio...")
    init_db() 
    await init_redis() 
    print("¡Servicio listo!")

@app.on_event("shutdown")
async def shutdown_event():
    print("Cerrando servicio...")
    await close_redis() 
    print("¡Servicio cerrado!")

# --- ¡ROUTER PRINCIPAL! ---
# Aquí conectamos todos nuestros endpoints (components y reviews)
# bajo el prefijo /api/v1
app.include_router(api_router, prefix=settings.API_V1_STR)


# --- Endpoint de Verificación ---
@app.get("/", tags=["Health Check"])
async def read_root():
    return {"status": "ok", "service": "components-service"}

@app.get("/health", tags=["Health Check"])
async def health_check():
    return {"status": "ok"}