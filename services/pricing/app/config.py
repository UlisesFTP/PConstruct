# PConstruct/services/pricing/app/config.py
import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv
from pathlib import Path
import logging # Añadir logging

logger = logging.getLogger(__name__)



class Settings(BaseSettings):
    RABBITMQ_URL: str
    COMPONENT_SERVICE_URL: str
    # PRICING_DATABASE_URL: Optional[str] = None # Ejemplo

settings = Settings()

# Verificación opcional después de cargar (ayuda a depurar)
logger.info(f"Pricing Service Settings Loaded:")
logger.info(f" - RABBITMQ_URL: {settings.RABBITMQ_URL}")
logger.info(f" - COMPONENT_SERVICE_URL: {settings.COMPONENT_SERVICE_URL}")