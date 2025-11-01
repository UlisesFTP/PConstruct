from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    DATABASE_URL: str  # ejemplo: postgresql+asyncpg://user:pass@postgres:5432/pcbuilder

    class Config:
        env_file = ".env"
        extra = "ignore"

@lru_cache
def get_settings():
    return Settings()

settings = get_settings()
