from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://user:password@benchmark-db:5432/benchmarkdb"
    COMPONENT_SERVICE_URL: str = "http://component-service:8002"
    BUILD_SERVICE_URL: str = "http://build-service:8003"
    STEAM_API_KEY: str = ""
    BLENDER_BENCHMARK_API: str = "https://opendata.blender.org/api/benchmark/"

settings = Settings()