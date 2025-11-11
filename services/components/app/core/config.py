from pydantic import validator
from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    # Variables de entorno leídas desde docker-compose.dev.yml
    # (que a su vez las lee de .env)
    
    # Base de Datos PostgreSQL
    COMPONENTS_DATABASE_URL: str = os.getenv("COMPONENTS_DATABASE_URL", "")
    
    # Caché de Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://components-cache:6379")

    # Configuración de la API
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "PConstruct Components Service"

    # Validación (asegurarse de que la URL de la DB esté)
    @validator("COMPONENTS_DATABASE_URL", pre=True, always=True)
    def check_db_url(cls, v):
        if not v:
            raise ValueError("COMPONENTS_DATABASE_URL no está definida en las variables de entorno.")
        return v

    class Config:
        case_sensitive = True
        # Esto permite que lea de un archivo .env local
        # (aunque en producción lo tomará de docker-compose)
        env_file = ".env" 
        env_file_encoding = 'utf-8'

# Creamos una instancia única que usaremos en toda la app
settings = Settings()