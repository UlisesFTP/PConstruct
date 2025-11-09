# app/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field
import logging

logger = logging.getLogger("pricing.config")

class Settings(BaseSettings):
    RABBITMQ_URL: str = Field(default="amqp://guest:guest@rabbitmq:5672/")
    COMPONENT_SERVICE_URL: str = Field(default="http://component-service:8003")
    LOG_LEVEL: str = Field(default="INFO")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

settings = Settings()
logger.info("Pricing Settings loaded. RABBITMQ_URL=%s COMPONENT_SERVICE_URL=%s",
            settings.RABBITMQ_URL, settings.COMPONENT_SERVICE_URL)
