# app/estimator.py
import os
import httpx
from typing import Dict, List, Tuple
from .score_loader import get_store
from . import gemini_client

COMPONENT_SERVICE_URL = os.getenv("COMPONENT_SERVICE_URL", "http://component-service:8003")

async def resolve_component_models(component_ids: List[int]) -> Dict[int, str]:
    """
    Pide al component-service cada componente y devuelve {id: model_name}
    """
    out = {}
    async with httpx.AsyncClient(timeout=10.0) as client:
        for cid in component_ids:
            r = await client.get(f"{COMPONENT_SERVICE_URL}/components/{cid}")
            if r.status_code == 200:
                data = r.json()
                # asume que el service expone algo como {"id":.., "name":.., "model":.., "brand":..}
                model = data.get("model") or data.get("name") or data.get("title")
                if model:
                    out[cid] = str(model)
    return out

async def fetch_scores_for_components(component_ids: List[int]) -> Dict[str, int]:
    """
    Devuelve {str(component_id): score}, intentando:
      1) score directo desde CSV/Kaggle
      2) interpolación simple por vecinos (no implementada aquí: podrías usar vecinos por nombre)
      3) fallback a Gemini (opcional)
    """
    store = get_store()
    id_to_model = await resolve_component_models(component_ids)
    known_map = store.all_scores()

    result: Dict[str,int] = {}
    for cid, model in id_to_model.items():
        score = store.find_score(model)
        if score is None and gemini_client.enabled():
            # usa Gemini para estimación aproximada con base en known_map
            est = gemini_client.estimate_score(model, known_map)
            if est and est.get("estimated_score"):
                score = int(est["estimated_score"])
        # última defensa: 0
        result[str(cid)] = int(score or 0)
    return result

def classify_for_software(component_scores: Dict[str,int], software_list: List) -> Dict:
    """
    Clasifica por requerimientos min/recomendada; escoge score GPU máximo como referencia.
    """
    # Heurística simplificada: usa el máximo de los componentes como "score GPU efectivo"
    # (ajusta si quieres separar CPU/GPU; aquí usamos un solo score para el MVP)
    effective = max(component_scores.values()) if component_scores else 0

    items = []
    for s in software_list:
        meets_min = effective >= s.min_gpu_score
        meets_rec = effective >= s.rec_gpu_score
        status = "OK (recomendado)" if meets_rec else ("Jugable con ajustes" if meets_min else "No recomendado")
        items.append({
            "name": s.name,
            "scenario": s.scenario,
            "type": s.type,
            "min_gpu_score": s.min_gpu_score,
            "rec_gpu_score": s.rec_gpu_score,
            "effective_score": effective,
            "status": status,
        })

    summary = {
        "effective_score": effective,
        "software": items,
    }

    # Recomendación personalizada con Gemini (si está habilitado)
    reco = gemini_client.personalized_reco(component_scores, summary) if gemini_client.enabled() else None
    if reco:
        summary["personalized_advice"] = reco

    return summary
