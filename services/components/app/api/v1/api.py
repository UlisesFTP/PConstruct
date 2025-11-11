from fastapi import APIRouter

# Importamos nuestros routers de endpoints
from app.api.v1.endpoints import components, reviews

api_router = APIRouter()

# Incluimos los routers en el router principal de la v1
api_router.include_router(
    components.router, 
    prefix="/components", # Prefijo de URL
    tags=["1. Components"] # Etiqueta para la documentación (Swagger)
)

api_router.include_router(
    reviews.router, 
    prefix="", # Sin prefijo (ya lo tienen en la definición)
    tags=["2. Reviews & Comments"] # Etiqueta para la documentación
)