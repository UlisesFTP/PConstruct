# app/estimator.py
import os, logging
import pandas as pd
import httpx
from .score_loader import get_store, find_score
from typing import Dict, Any, Optional, List, Tuple
from .schemas import ComponentResult, EstimateResponse



logger = logging.getLogger("benchmark-estimator")


SCORES: dict[str, float] = {}

# Demo map por si el componente ID no existe en component-service
DEMO_COMPONENT_MAP: dict[int, tuple[str,str]] = {
    1001: ("gpu", "GeForce RTX 4070"),
    2001: ("cpu", "Ryzen 5 5600"),
}

SEED_SCORES = {
    "geforce rtx 4090": 38550,
    "geforce rtx 4080": 34910,
    "geforce rtx 4070 ti": 28665,
    "geforce rtx 4070": 23200,
    "geforce rtx 3060": 17050,
    "ryzen 5 5600": 20000,
    "core i5-12400f": 19500,
}

def _norm(s: str) -> str:
    return (s or "").strip().lower()






def load_scores_once():
    global SCORES
    if SCORES:
        return

    # 1) CSV local (recomendado)
    local_csv = os.getenv("GPU_SCORES_CSV")  # p.ej. /data/gpu_scores.csv
    if local_csv and os.path.exists(local_csv):
        try:
            df = pd.read_csv(local_csv)
            # Espera columnas: model, passmark_score (ajústalo si tu CSV tiene otros nombres)
            for _, row in df.iterrows():
                name = _norm(str(row.get("model", "")))
                score = float(row.get("passmark_score", 0) or 0)
                if name and score:
                    SCORES[name] = score
            if SCORES:
                logger.info(f"Cargados {len(SCORES)} scores desde CSV local")
                return
        except Exception as e:
            logger.warning(f"Fallo cargando CSV local: {e}")

    # 2) Kaggle (opcional)
    kd = os.getenv("KAGGLE_DATASET")
    kfile = os.getenv("KAGGLE_DATA_FILE")
    if kd and kfile:
        try:
            import kagglehub
            from kagglehub import KaggleDatasetAdapter
            df = kagglehub.load_dataset(
                KaggleDatasetAdapter.PANDAS,
                kd,
                kfile,
            )
            for _, row in df.iterrows():
                name = _norm(str(row.get("model", "")))
                score = float(row.get("passmark_score", 0) or 0)
                if name and score:
                    SCORES[name] = score
            if SCORES:
                logger.info(f"Cargados {len(SCORES)} scores desde Kaggle")
                return
        except Exception as e:
            logger.warning(f"Fallo cargando Kaggle dataset: {e}")

    # 3) Seed mínimo de dev (no romper)
    logger.warning("No hay scores cargados. Agregando seed mínimo para dev.")
    for k, v in SEED_SCORES.items():
        SCORES[k] = v


COMPONENT_SERVICE_URL = os.getenv("COMPONENT_SERVICE_URL", "http://component-service:8003")

async def fetch_components_metadata(component_ids: list[int], hints: dict[int, dict] | None) -> list[dict]:
    out = []
    async with httpx.AsyncClient(timeout=5.0) as client:
        for cid in component_ids:
            meta = {"id": cid, "type": None, "model": None, "source": None}
            try:
                r = await client.get(f"{COMPONENT_SERVICE_URL}/components/{cid}")
                if r.status_code == 200:
                    j = r.json()
                    meta["type"] = _norm(j.get("type", ""))  # "cpu"|"gpu"
                    meta["model"] = j.get("model") or j.get("name") or j.get("title")
                    meta["source"] = "component-service"
                else:
                    # 404 u otro → intentar hints
                    raise RuntimeError(f"component {cid} http {r.status_code}")
            except Exception:
                if hints and cid in hints:
                    meta["type"] = _norm(hints[cid].get("type"))
                    meta["model"] = hints[cid].get("model")
                    meta["source"] = "hint"
                elif cid in DEMO_COMPONENT_MAP:
                    t, m = DEMO_COMPONENT_MAP[cid]
                    meta["type"] = t
                    meta["model"] = m
                    meta["source"] = "demo"
                else:
                    meta["type"] = "gpu"  # default razonable
                    meta["model"] = f"Unknown-{cid}"
                    meta["source"] = "fallback"
            out.append(meta)
    return out

def _origin_for(model: Optional[str], score: Optional[int]) -> str:
    # If you later add Gemini or Kaggle, set accordingly.
    # For now assume "csv" when found, else "seed" if it came from the minimal seed.
    if not model or score is None:
        return "unknown"
    # Heuristic: if your seed models are those three hardcoded ones, tag them as seed.
    seed_keys = {"geforce rtx 4070", "ryzen 5 5600", "threadripper 3990x"}
    return "seed" if (model.lower() in seed_keys) else "csv"

def fetch_scores_for_components(component_models: Dict[str, Optional[str]]) -> Tuple[Dict[str, Optional[int]], Dict[str, str]]:
    """
    component_models like {"cpu_model": "...", "gpu_model": "..."}
    returns (scores, scores_used)
      scores -> {"cpu_score": int|None, "gpu_score": int|None}
      scores_used -> { "<cpu_model>": "csv|seed|gemini|unknown", "<gpu_model>": "..." }
    """
    cpu_name = component_models.get("cpu_model")
    gpu_name = component_models.get("gpu_model")

    cpu_score = find_score(cpu_name) if cpu_name else None
    gpu_score = find_score(gpu_name) if gpu_name else None

    scores_used: Dict[str, str] = {}
    if cpu_name:
        scores_used[cpu_name.lower()] = _origin_for(cpu_name, cpu_score)
    if gpu_name:
        scores_used[gpu_name.lower()] = _origin_for(gpu_name, gpu_score)

    return {"cpu_score": cpu_score, "gpu_score": gpu_score}, scores_used

def attach_scores(component_models: Dict[str, Optional[str]]) -> List[ComponentResult]:
    """
    Builds the components array required by EstimateResponse.
    """
    scores, _ = fetch_scores_for_components(component_models)

    items: List[ComponentResult] = []
    if component_models.get("cpu_model"):
        items.append(
            ComponentResult(
                id=0,  # optional if you don’t have a real ID here
                type="cpu",
                model=component_models["cpu_model"],
                score=scores["cpu_score"],
                source=_origin_for(component_models["cpu_model"], scores["cpu_score"]),
            )
        )
    if component_models.get("gpu_model"):
        items.append(
            ComponentResult(
                id=0,
                type="gpu",
                model=component_models["gpu_model"],
                score=scores["gpu_score"],
                source=_origin_for(component_models["gpu_model"], scores["gpu_score"]),
            )
        )
    return items

def classify_for_software(cpu_score: Optional[int], gpu_score: Optional[int], scenario: Optional[str]) -> Dict[str, Any]:
    """
    Tiny, conservative tiering. Adjust thresholds later.
    """
    def tier(v: Optional[int]) -> str:
        if v is None:
            return "unknown"
        if v >= 30000: return "ultra"
        if v >= 20000: return "high"
        if v >= 12000: return "medium"
        return "low"

    return {
        "scenario": scenario,
        "cpu_tier": tier(cpu_score),
        "gpu_tier": tier(gpu_score),
        "bottleneck": "gpu" if (gpu_score or 0) < (cpu_score or 0) else "cpu"
    }

async def personalized_reco(classif: dict) -> str | None:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        logger.warning("Gemini personalized_reco fallo: GEMINI_API_KEY no configurado")
        return None
    # Aquí iría tu llamada real a Gemini (omitida). Devuelvo un texto ejemplo.
    tier = classif.get("tier")
    if tier == "elite": return "Excelente para 1440p Ultra con RT. Puedes priorizar monitores 144Hz."
    if tier == "high": return "Muy fluido en 1440p; considera DLSS/FSR para RT alto."
    if tier == "mid": return "Jugable en 1080p/1440p con settings equilibrados."
    return "Recomendación básica: baja calidad o resolución para mantener fluidez."