# app/gemini_client.py
import os
import json
import logging
from typing import Dict, Optional, Tuple, Any

logger = logging.getLogger("gemini")
logger.setLevel(logging.INFO)

def enabled() -> bool:
    return os.getenv("ENABLE_GEMINI_FALLBACK", "true").lower() == "true"

def _get_model():
    import google.generativeai as genai
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY no configurado")
    genai.configure(api_key=api_key)
    model_name = os.getenv("GEMINI_MODEL", "gemini-1.5-flash") 
    return genai.GenerativeModel(
        model_name,
        generation_config={"response_mime_type": "application/json"}
    )

def estimate_score(model_name: str, known_scores: Dict[str,int]) -> Optional[Dict]:
    # ... (congelada)
    logger.info("estimate_score no se usa en el flujo 'gemini-céntrico'")
    return None

def personalized_reco(component_scores: Dict[str,int], summary: Dict) -> Optional[str]:
    # ... (congelada)
    logger.info("personalized_reco no se usa en el flujo 'gemini-céntrico'")
    return None

# --- FUNCIÓN MAESTRA MODIFICADA ---

# 1. Cambiar 'def' por 'async def'
async def get_gemini_benchmark_analysis(
    cpu_model: Optional[str], 
    gpu_model: Optional[str], 
    scenario: Optional[str]
) -> Dict[str, Any]: # La firma ahora es asíncrona
    """
    Realiza una única llamada a Gemini para obtener tanto la estimación
    de rendimiento (FPS) como una recomendación de texto.
    """
    if not enabled():
        logger.warning("Flujo de benchmark de Gemini deshabilitado. Faltan variables de entorno.")
        return {
            "performance_fps": {},
            "recommendation_text": "El análisis de IA está desactivado."
        }
        
    if not scenario:
        return {
            "performance_fps": {},
            "recommendation_text": "Por favor, especifica un juego o programa para analizar."
        }

    hardware_summary = []
    if cpu_model:
        hardware_summary.append(f"CPU: {cpu_model}")
    if gpu_model:
        hardware_summary.append(f"GPU: {gpu_model}")
    
    if not hardware_summary:
         return {
            "performance_fps": {},
            "recommendation_text": "No se proporcionó hardware (ni CPU ni GPU)."
        }

    prompt = f"""
    Eres un experto analista de hardware de PC.
    
    Hardware del usuario: {", ".join(hardware_summary)}
    Escenario (Juego/Programa): {scenario}

    Por favor, proporciona un análisis en formato JSON. El JSON debe tener dos claves:
    1.  `performance_fps`: Un objeto JSON que estima los FPS (fotogramas por segundo) promedio en este escenario para las resoluciones 1080p, 1440p y 4K. Si una resolución no aplica (ej. un juego 2D) o no se puede estimar, usa `null`.
    2.  `recommendation_text`: Un string de texto (no JSON) con una recomendación personalizada en 3-5 viñetas, explicando el rendimiento esperado y posibles mejoras.

    Ejemplo de respuesta:
    {{
      "performance_fps": {{
        "1080p": 145,
        "1440p": 90,
        "4K": 55
      }},
      "recommendation_text": "Basado en tu hardware para {scenario}:\n- Tu rendimiento en 1080p será excelente.\n- En 1440p, puedes esperar una experiencia muy fluida.\n- El 4K es jugable, pero podrías necesitar ajustar configuraciones.\n- Sugerencia: Esta es una configuración muy equilibrada."
    }}
    """
    
    try:
        model = _get_model()
        
        # 2. Cambiar '.generate_content' por 'await .generate_content_async'
        resp = await model.generate_content_async(prompt) 
        
        response_data = json.loads(resp.text)
        
        if "performance_fps" in response_data and "recommendation_text" in response_data:
            return {
                "performance_fps": response_data.get("performance_fps") or {},
                "recommendation_text": response_data.get("recommendation_text") or "No se pudo generar recomendación."
            }
        else:
            raise ValueError("La respuesta de Gemini no tiene la estructura JSON esperada.")

    except Exception as e:
        logger.error(f"Fallo en get_gemini_benchmark_analysis: {e}")
        return {
            "performance_fps": {},
            "recommendation_text": f"Error al analizar el rendimiento: {e}"
        }