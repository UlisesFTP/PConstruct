from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://user:password@build-db:5432/builddb"
    COMPONENT_SERVICE_URL: str = "http://component-service:8002"
    PRICING_SERVICE_URL: str = "http://pricing-service:8004"
    BENCHMARK_SERVICE_URL: str = "http://benchmark-service:8005"
    RABBITMQ_URL: str = "amqp://rabbitmq"

settings = Settings()