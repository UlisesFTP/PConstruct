# app/gemini_client.py
import os
import json
import logging
from typing import Dict, Optional, Tuple

logger = logging.getLogger("gemini")
logger.setLevel(logging.INFO)

def enabled() -> bool:
    return os.getenv("ENABLE_GEMINI_FALLBACK", "false").lower() == "true"

def _get_model():
    import google.generativeai as genai
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY no configurado")
    genai.configure(api_key=api_key)
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    return genai.GenerativeModel(model_name)

def estimate_score(model_name: str, known_scores: Dict[str,int]) -> Optional[Dict]:
    """
    Devuelve dict con {estimated_score:int, confidence:float, rationale:str} o None si falla.
    """
    if not enabled():
        return None
    try:
        model = _get_model()
        prompt = f"""
Eres un analista de hardware. Te paso una tabla de GPUs conocidas con un "score sintético" (escala tipo PassMark G3D).
Usa esa referencia para estimar el score para el modelo objetivo. Devuelve SOLO un JSON con:
{{
  "estimated_score": <int>,
  "confidence": <float entre 0 y 1>,
  "rationale": "<breve explicación>"
}}

Model objetivo: "{model_name}"
Scores conocidos (JSON): {json.dumps(known_scores) }
"""
        resp = model.generate_content(prompt)
        text = resp.text or ""
        text = text.strip().strip("`")
        # intenta extraer JSON
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1:
            js = json.loads(text[start:end+1])
            if "estimated_score" in js:
                js["estimated_score"] = int(js["estimated_score"])
                js["confidence"] = float(js.get("confidence", 0.5))
                js["rationale"] = js.get("rationale", "")
                return js
    except Exception as e:
        logger.warning("Gemini estimate_score fallo: %s", e)
    return None

def personalized_reco(component_scores: Dict[str,int], summary: Dict) -> Optional[str]:
    """
    Usa Gemini para redactar una recomendación resumida a partir de los scores y clasificación final.
    """
    if not enabled():
        return None
    try:
        model = _get_model()
        prompt = f"""
Eres asistente técnico. Genera una recomendación concisa y útil para el usuario final con base en:
- Scores por componente: {json.dumps(component_scores)}
- Resumen de software/clasificación: {json.dumps(summary)}

Formato:
- 3 a 5 viñetas máximas
- Lenguaje claro
- Termina con 1 sugerencia de mejora de hardware si aplica
"""
        resp = model.generate_content(prompt)
        return (resp.text or "").strip()
    except Exception as e:
        logger.warning("Gemini personalized_reco fallo: %s", e)
        return None
