# app/score_loader.py
import os
import csv
import json
import math
import logging
from functools import lru_cache
from typing import Dict, Optional, Tuple, List

import pandas as pd

logger = logging.getLogger("score-loader")
logger.setLevel(logging.INFO)

# Carga perezosa de kagglehub solo si se usa
def _try_import_kagglehub():
    try:
        import kagglehub
        from kagglehub import KaggleDatasetAdapter
        return kagglehub, KaggleDatasetAdapter
    except Exception as e:
        logger.warning("kagglehub no disponible: %s", e)
        return None, None

def _norm(s: str) -> str:
    s = (s or "").lower().strip()
    # normalizaciones simples
    for p in ["nvidia ", "geforce ", "rtx ", "gtx ", "radeon ", "amd ", "rx "]:
        s = s.replace(p, " ")
    s = " ".join(s.split())  # colapsa espacios
    return s

class ScoresStore:
    def __init__(self):
        self._scores: Dict[str, int] = {}  # nombre normalizado -> score
        self.name_col = os.getenv("BENCH_NAME_COL", "model")
        self.score_col = os.getenv("BENCH_SCORE_COL", "score")

    def _put(self, name: str, score: int):
        if not name:
            return
        key = _norm(name)
        if key and score:
            self._scores[key] = int(score)

    def load(self):
        source = os.getenv("BENCH_SCORES_SOURCE", "none").lower()
        if source == "kaggle":
            self._load_from_kaggle()
        elif source == "csv":
            path = os.getenv("BENCH_SCORES_CSV_PATH")
            if not path or not os.path.exists(path):
                logger.warning("CSV no encontrado en BENCH_SCORES_CSV_PATH=%s", path)
            else:
                self._load_from_csv(path)
        else:
            logger.info("Sin fuente de puntajes (BENCH_SCORES_SOURCE=%s).", source)

        if not self._scores:
            logger.warning("No hay scores cargados. Agregando seed mínimo para dev.")
            # Seed mínimo para pruebas
            seed = {
                "geforce rtx 4090": 38550,
                "geforce rtx 4080": 34910,
                "geforce rtx 4070": 23200,
                "geforce rtx 3060": 17050,
                "radeon rx 7900 xt": 25458,
            }
            for k, v in seed.items():
                self._scores[_norm(k)] = v

        logger.info("Scores cargados: %d entradas", len(self._scores))

    def _load_from_csv(self, path: str):
        logger.info("Cargando CSV local: %s", path)
        try:
            df = pd.read_csv(path)
        except Exception:
            # fallback a CSV simple
            rows = []
            with open(path, newline="", encoding="utf-8") as f:
                r = csv.DictReader(f)
                rows = list(r)
            df = pd.DataFrame(rows)

        if self.name_col not in df.columns or self.score_col not in df.columns:
            logger.warning("Columnas esperadas no presentes: %s, %s", self.name_col, self.score_col)
            logger.warning("Columnas disponibles: %s", list(df.columns))
        for _, row in df.iterrows():
            name = str(row.get(self.name_col, "")).strip()
            score = row.get(self.score_col, None)
            if not name or pd.isna(score):
                continue
            try:
                score = int(float(score))
            except Exception:
                continue
            self._put(name, score)

    def _load_from_kaggle(self):
        slug = os.getenv("KAGGLE_DATASET_SLUG", "").strip()
        file_path = os.getenv("KAGGLE_FILE_PATH", "").strip()
        if not slug:
            logger.error("KAGGLE_DATASET_SLUG vacío")
            return
        kagglehub, Adapter = _try_import_kagglehub()
        if not kagglehub:
            return
        logger.info("Cargando dataset de Kaggle: %s (%s)", slug, file_path or "(auto)")
        try:
            df = kagglehub.load_dataset(
                Adapter.PANDAS,
                slug,
                file_path or None,
            )
        except Exception as e:
            logger.error("Fallo cargando Kaggle dataset: %s", e)
            return

        if self.name_col not in df.columns or self.score_col not in df.columns:
            logger.warning("Columnas esperadas no presentes: %s, %s", self.name_col, self.score_col)
            logger.warning("Columnas disponibles: %s", list(df.columns))
        for _, row in df.iterrows():
            name = str(row.get(self.name_col, "")).strip()
            score = row.get(self.score_col, None)
            if not name or pd.isna(score):
                continue
            try:
                score = int(float(score))
            except Exception:
                continue
            self._put(name, score)

    def find_score(self, model_name: str) -> Optional[int]:
        # match exact/normalizado + contención simple
        key = _norm(model_name)
        if key in self._scores:
            return self._scores[key]
        # búsqueda por contención
        for k, v in self._scores.items():
            if key in k or k in key:
                return v
        return None

    def neighbors(self, score: int) -> Tuple[Optional[Tuple[str,int]], Optional[Tuple[str,int]]]:
        # devuelve (lower_neighbor, upper_neighbor)
        if not self._scores:
            return None, None
        sorted_items = sorted(self._scores.items(), key=lambda kv: kv[1])
        lower = None
        upper = None
        for name, sc in sorted_items:
            if sc <= score:
                lower = (name, sc)
            if sc >= score and upper is None:
                upper = (name, sc)
                break
        return lower, upper

    def all_scores(self) -> Dict[str,int]:
        return dict(self._scores)

# Singleton
_STORE: Optional[ScoresStore] = None

def get_store() -> ScoresStore:
    global _STORE
    if _STORE is None:
        _STORE = ScoresStore()
        _STORE.load()
    return _STORE
