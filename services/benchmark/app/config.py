import os
from dotenv import load_dotenv
from pathlib import Path

# Cargamos el mismo .env global que usan los otros servicios
env_path = (
    Path(__file__)
    .parent          # app/
    .parent          # benchmark/
    .parent          # services/
    .parent          # PConstruct/
    / "infra"
    / "docker"
    / ".env"
)

load_dotenv(dotenv_path=env_path)

BENCHMARKS_DATABASE_URL = os.getenv("BENCHMARKS_DATABASE_URL")
COMPONENTS_SERVICE_URL = os.getenv("COMPONENTS_SERVICE_URL", "http://component-service:8003")

if not BENCHMARKS_DATABASE_URL:
    raise ValueError("BENCHMARKS_DATABASE_URL no está definida en .env")
