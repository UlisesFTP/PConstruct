from __future__ import annotations

from asyncio.log import logger
import logging
import os
import re
from pathlib import Path
from typing import Dict, Tuple, Optional, List

import pandas as pd


LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)




# -------------------------------------------------------------------
# Config desde ENV con defaults sensatos
# -------------------------------------------------------------------
BENCH_SCORES_SOURCE = os.getenv("BENCH_SCORES_SOURCE", "csv")

CPU_BENCH_CSV_PATH = os.getenv("CPU_BENCH_CSV_PATH", "/code/data/CPU_BENCHMARK.csv")
GPU_BENCH_CSV_PATH = os.getenv("GPU_BENCH_CSV_PATH", "/code/data/GPU_BENCHMARK.csv")

CPU_NAME_COL  = os.getenv("CPU_NAME_COL", "auto")
CPU_SCORE_COL = os.getenv("CPU_SCORE_COL", "auto")
GPU_NAME_COL  = os.getenv("GPU_NAME_COL", "auto")
GPU_SCORE_COL = os.getenv("GPU_SCORE_COL", "auto")

# -------------------------------------------------------------------
# Normalización de nombres
# -------------------------------------------------------------------
def _norm(x: str) -> str:
    x = (x or "").strip().lower()
    x = re.sub(r"\(.*?\)", "", x)
    x = re.sub(r"[^a-z0-9\-\s\+\.]", " ", x)
    x = re.sub(r"\s+", " ", x).strip()
    return x

_VENDOR_PREFIX = re.compile(r"^(?:amd|intel|nvidia|asus|msi|gigabyte|evga|zotac)\s+", re.I)

def _novendor(x: str) -> str:
    return _VENDOR_PREFIX.sub("", _norm(x)).strip()

# -------------------------------------------------------------------
# Resolución robusta de rutas
# -------------------------------------------------------------------
def _resolve_path(p: Optional[str]) -> Optional[Path]:
    if not p:
        return None
    cand = Path(p)
    if cand.is_absolute() and cand.exists():
        return cand
    for base in (Path("/code"), Path("/code/app"), Path.cwd(), Path("/code/data")):
        test = (base / cand).resolve()
        if test.exists():
            return test
    # último intento: solo el nombre dentro de /code/data
    guess = Path("/code/data") / Path(p).name
    return guess if guess.exists() else None

# -------------------------------------------------------------------
# Detección simple de columnas (auto o especificadas)
# -------------------------------------------------------------------
def _autodetect_columns(df: pd.DataFrame, for_cpu: bool,
                        name_col_cfg: str, score_col_cfg: str) -> Tuple[str, str]:
    cols = [c for c in df.columns]
    low = {c.lower(): c for c in cols}

    def pick_name(candidates: List[str]) -> Optional[str]:
        for cand in candidates:
            for lc, real in low.items():
                if lc == cand or cand in lc:
                    return real
        return None

    def pick_score(candidates: List[str]) -> Optional[str]:
        for cand in candidates:
            for lc, real in low.items():
                if lc == cand or cand in lc:
                    return real
        # si no encontramos por nombre, tomar la primera numérica
        nums = [c for c in cols if pd.api.types.is_numeric_dtype(df[c])]
        if nums:
            if for_cpu:
                pref = [c for c in nums if "r23" in c.lower() or "cinebench" in c.lower()]
                return pref[0] if pref else nums[0]
            return nums[0]
        return None

    name_col = name_col_cfg if name_col_cfg != "auto" else pick_name(
        ["model", "cpu name", "cpu", "processor", "name", "gpu", "graphics card", "productname", "cpuname"]
    )
    if score_col_cfg != "auto":
        score_col = score_col_cfg
    else:
        score_col = pick_score(
            ["r23", "cinebench", "multi", "single", "score", "points", "passmark", "g3d", "mark", "timespy", "3dmark", "avg", "average", "fps"]
        )

    if not name_col or not score_col:
        raise ValueError("No se pudieron detectar columnas de nombre/puntaje")
    return name_col, score_col

# -------------------------------------------------------------------
# Store de puntajes
# -------------------------------------------------------------------
class ScoresStore:
    def __init__(self):
        self._scores: Dict[str, int] = {}
        self._loaded = False

    def load(self):
        self._scores = {}
        loaded_any = False

        if BENCH_SCORES_SOURCE == "csv":
            cpu_path = _resolve_path(CPU_BENCH_CSV_PATH)
            gpu_path = _resolve_path(GPU_BENCH_CSV_PATH)

            if cpu_path and cpu_path.exists():
                self._load_csv(cpu_path, for_cpu=True, name_col_cfg=CPU_NAME_COL, score_col_cfg=CPU_SCORE_COL)
                loaded_any = True
            else:
                logger.warning(f"CPU CSV no encontrado: {CPU_BENCH_CSV_PATH}")

            if gpu_path and gpu_path.exists():
                self._load_csv(gpu_path, for_cpu=False, name_col_cfg=GPU_NAME_COL, score_col_cfg=GPU_SCORE_COL)
                loaded_any = True
            else:
                logger.warning(f"GPU CSV no encontrado: {GPU_BENCH_CSV_PATH}")

        if not loaded_any:
            self._seed_minimal()

        self._loaded = True
        logger.info(f"Scores cargados: {len(self._scores)}")

    def _load_csv(self, path: Path, for_cpu: bool, name_col_cfg: str, score_col_cfg: str):
        df = pd.read_csv(path)
        name_col, score_col = _autodetect_columns(df, for_cpu, name_col_cfg, score_col_cfg)
        self._ingest_df(df[[name_col, score_col]].copy(), for_cpu, name_col, score_col)
        logger.info(f"Leído {path} -> columnas: name='{name_col}', score='{score_col}'")

    def _ingest_df(self, df: pd.DataFrame, for_cpu: bool, name_col_cfg: str, score_col_cfg: str):
        df = df.dropna()

        def to_int(v) -> Optional[int]:
            try:
                if pd.isna(v):
                    return None
                x = float(v)
                if x != x:
                    return None
                return int(round(x))
            except Exception:
                return None

        for _, row in df.iterrows():
            name = str(row.iloc[0]).strip()
            sc = to_int(row.iloc[1])
            if not name or sc is None:
                continue
            k1 = _norm(name)
            k2 = _novendor(name)
            old = self._scores.get(k1)
            if old is None or sc > old:
                self._scores[k1] = sc
            old2 = self._scores.get(k2)
            if old2 is None or sc > old2:
                self._scores[k2] = sc

    def _seed_minimal(self):
        logger.warning("No se cargaron CSV: usando seed mínima para mantener el servicio arriba.")
        # Semilla mínima para que las rutas funcionen en dev
        self._scores.update({
            _norm("GeForce RTX 4070"): 23200,
            _norm("Ryzen 5 5600"): 20000,
            _norm("Threadripper 3990X"): 1262,  # Ejemplo de tu CSV de muestra (singleScore de ejemplo)
        })

    # API simple
    def has_loaded(self) -> bool:
        return self._loaded

    def find_score(self, model_name: str) -> Optional[int]:
        if not model_name:
            return None
        k1 = _norm(model_name)
        k2 = _novendor(model_name)
        return self._scores.get(k1) or self._scores.get(k2)

# Singleton
_STORE: Optional[ScoresStore] = None

def get_store() -> ScoresStore:
    global _STORE
    if _STORE is None:
        _STORE = ScoresStore()
        _STORE.load()
    return _STORE

def find_score(model_name: str) -> Optional[int]:
    return get_store().find_score(model_name)
