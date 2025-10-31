# PConstruct/services/components/app/config.py
import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

# Carga .env desde infra/docker/
env_path = Path(__file__).parent.parent.parent.parent / 'infra' / 'docker' / '.env'
load_dotenv(dotenv_path=env_path)

# --- DEBUG: Imprime las variables cargadas ---
# logger.info(f"Cargando settings desde: {env_path}")
# logger.info(f"COMPONENTS_DATABASE_URL (desde os): {os.getenv('COMPONENTS_DATABASE_URL')}")
# logger.info(f"LOAD_INITIAL_DATA (desde os): {os.getenv('LOAD_INITIAL_DATA')}")
# ---------------------------------------------

class Settings(BaseSettings):
    # Pydantic-settings leerá estas del entorno (cargadas por load_dotenv)
    
    # Variable para la URL de la base de datos de componentes
    COMPONENTS_DATABASE_URL: str
    
    # Variable para decidir si cargar datos iniciales
    LOAD_INITIAL_DATA: bool = True # Valor por defecto si no se encuentra

    # Configuración para pydantic-settings (opcional si ya usas load_dotenv)
    class Config:
        # Pydantic V2 ya no usa env_file de la misma manera,
        # pero como ya cargamos con load_dotenv, leerá las variables de os.getenv()
        case_sensitive = False

try:
    settings = Settings()
    # logger.info("Settings cargados exitosamente.")
    # logger.info(f"LOAD_INITIAL_DATA (en settings): {settings.LOAD_INITIAL_DATA}")
except Exception as e:
    logger.error(f"Error al cargar Settings para component-service: {e}")
    # Si las variables no están en .env, esto fallará. Asegúrate que estén.
    raise