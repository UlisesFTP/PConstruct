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
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-pro") 
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
) -> Dict[str, Any]:
    if not enabled():
        logger.warning("Flujo de benchmark de Gemini deshabilitado.")
        return {
            "performance_fps": {},
            "recommendation_text": "El análisis de IA está desactivado."
        }
        
    if not scenario:
        return {
            "performance_fps": {},
            "recommendation_text": "Por favor, especifica un juego o programa."
        }

    # --- CAMBIO IMPORTANTE AQUÍ ---
    # Combinamos los inputs para que Gemini entienda el contexto global.
    # Esto arregla el caso donde el usuario escribe "RTX 3060" pero Flutter lo envió como CPU.
    raw_components = []
    if cpu_model: raw_components.append(cpu_model)
    if gpu_model: raw_components.append(gpu_model)
    
    hardware_string = ", ".join(raw_components)

    if not hardware_string:
         return {
            "performance_fps": {},
            "recommendation_text": "No se proporcionó hardware para analizar."
        }

    prompt = f"""
    Eres un experto analista de hardware de PC y rendimiento en videojuegos/software.
    
    ENTRADA DEL USUARIO:
    Hardware: {hardware_string}
    Escenario (Juego/Programa): {scenario}

    INSTRUCCIONES:
    1. Analiza el texto en 'Hardware'. El usuario puede haber escrito nombres parciales (ej: "4070" en vez de "RTX 4070") o haber puesto una GPU donde debería ir la CPU. Identifica los componentes reales (Intel, AMD, NVIDIA) implícitos en el texto.
    2. Estima el rendimiento (FPS promedio) para el escenario dado.
    
    RESPUESTA (JSON estricto):
    {{
      "performance_fps": {{
        "1080p": <int o null>,
        "1440p": <int o null>,
        "4K": <int o null>
      }},
      "recommendation_text": "Breve análisis del rendimiento de {hardware_string} en {scenario}. Si detectaste que el input era ambiguo, aclara qué componente asumiste."
    }}
    """
    
    try:
        model = _get_model()
        resp = await model.generate_content_async(prompt) 
        
        # Limpieza básica por si Gemini devuelve bloques de código markdown ```json ... ```
        clean_text = resp.text.replace("```json", "").replace("```", "").strip()
        
        response_data = json.loads(clean_text)
        
        if "performance_fps" in response_data and "recommendation_text" in response_data:
            return {
                "performance_fps": response_data.get("performance_fps") or {},
                "recommendation_text": response_data.get("recommendation_text") or "Sin recomendación."
            }
        else:
            # Fallback simple si el JSON no es perfecto
            return {
                 "performance_fps": {},
                 "recommendation_text": "Gemini no pudo estructurar la respuesta."
            }

    except Exception as e:
        logger.error(f"Fallo en get_gemini_benchmark_analysis: {e}")
        return {
            "performance_fps": {},
            "recommendation_text": f"Error de estimación IA: {e}"
        }