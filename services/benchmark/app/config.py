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
BENCH_SCORES_SOURCE = os.getenv("BENCH_SCORES_SOURCE", "csv")

CPU_BENCH_CSV_PATH = os.getenv("CPU_BENCH_CSV_PATH", "/data/CPU_BENCHMARK.csv")
CPU_NAME_COL = os.getenv("CPU_NAME_COL", "auto")
CPU_SCORE_COL = os.getenv("CPU_SCORE_COL", "auto")

GPU_BENCH_CSV_PATH = os.getenv("GPU_BENCH_CSV_PATH", "/data/GPU_BENCHMARK.csv")
GPU_NAME_COL = os.getenv("GPU_NAME_COL", "auto")
GPU_SCORE_COL = os.getenv("GPU_SCORE_COL", "auto")

KAGGLE_DATASET = os.getenv("KAGGLE_DATASET", "alanjo/graphics-card-full-specs")
KAGGLE_FILE_PATH = os.getenv("KAGGLE_FILE_PATH", "")

if not BENCHMARKS_DATABASE_URL:
    raise ValueError("BENCHMARKS_DATABASE_URL no está definida en .env")
# No truene en import-time: habrá servicios que ni tocan DB.
if not BENCHMARKS_DATABASE_URL:
    # Loguea si quieres, pero no abortes el import.
    print("[config] BENCHMARKS_DATABASE_URL no definida; funciones con DB deben validarlo en runtime.")
    BENCHMARKS_DATABASE_URL = None
