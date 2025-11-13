# services/builds/app/gemini_client.py

from asyncio import log
import logging
import google.generativeai as genai
import json
import os
from .config import GEMINI_API_KEY # Importamos la clave que configuramos
import re
import os, re, asyncio

# --- Configuración del Cliente Gemini ---
if not GEMINI_API_KEY:
    print("ADVERTENCIA: GEMINI_API_KEY_BUILDS no está configurada. La validación de compatibilidad se omitirá.")
else:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
    except Exception as e:
        print(f"Error al configurar la API de Gemini: {e}")

# --- El cerebro: El Prompt de Validación ---
PROMPT_TEMPLATE = """
Eres un asistente experto en ensamblaje de PC. Tu única tarea es verificar la compatibilidad de una lista de componentes.

Componentes:
{component_list}

Reglas de respuesta:
1. Analiza la compatibilidad (ej. socket de CPU vs motherboard, tipo de RAM vs motherboard, RAM vs CPU, etc.).
2. Si todos los componentes son compatibles:
   Responde SOLAMENTE con el siguiente JSON:
   {{"compatible": true, "reason": "Todos los componentes son compatibles."}}
3. Si encuentras una incompatibilidad:
   Responde SOLAMENTE con el siguiente JSON, explicando el problema específico en español:
   {{"compatible": false, "reason": "Incompatibilidad detectada: [Tu explicación del problema aquí]."}}
4. Si te falta información clave (como la CPU o la Motherboard) para determinar la compatibilidad:
   Responde SOLAMENTE con el siguiente JSON:
   {{"compatible": false, "reason": "Información insuficiente. Se requiere al menos una CPU y una Motherboard."}}
5. NO añadas ningún texto, explicación o formato (como ```json) antes o después del objeto JSON.
"""

# --- Función Asíncrona para la Validación ---
async def check_compatibility(components: dict) -> dict:
    """
    Verifica la compatibilidad de una lista de componentes usando la API de Gemini.
    
    Args:
        components (dict): Un diccionario como {"cpu": "Intel i9", "motherboard": "MSI B760"}
    
    Returns:
        dict: Un diccionario con {"compatible": bool, "reason": str}
    """
    
    # Si no hay API key, omitimos la validación (comportamiento seguro)
    if not GEMINI_API_KEY:
        return {"compatible": True, "reason": "Validación de compatibilidad omitida (API key no configurada)."}
        
    # Requerimos al menos CPU y Motherboard para una validación útil
    if not components.get("cpu") or not components.get("motherboard"):
        return {"compatible": False, "reason": "Se requiere CPU y Motherboard para la validación."}

    try:
        # 1. Iniciar el modelo (usamos 1.5-flash por velocidad)
        model = genai.GenerativeModel('gemini-2.5-flash')

        # 2. Construir la lista de componentes para el prompt
        component_list_str = "\n".join(
            f"- {key.capitalize()}: {value}"
            for key, value in components.items() if value
        )
        
        prompt = PROMPT_TEMPLATE.format(component_list=component_list_str)

        # 3. Llamar a la API de Gemini de forma asíncrona
        response = await model.generate_content_async(prompt)
        
        # 4. Limpiar y parsear la respuesta JSON
        # Gemini a veces envuelve la respuesta en ```json ... ```
        cleaned_text = response.text.strip().replace("```json", "").replace("```", "").strip()

        result = json.loads(cleaned_text)
        return result

    except json.JSONDecodeError:
        # El modelo no devolvió un JSON válido
        return {"compatible": False, "reason": "La API de validación devolvió una respuesta inesperada."}
    except Exception as e:
        # Cualquier otro error (API, permisos, etc.)
        print(f"Error en Gemini Client: {e}")
        return {"compatible": False, "reason": f"Error en el servicio de validación: {str(e)}"}
    
logger = logging.getLogger("yarbis")
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

SYSTEM_PROMPT = (
    "Eres Yarbis, asesor de PConstruct. Solo hablas de PCs, componentes, programas y videojuegos "
    "enfocados en requisitos, rendimiento, compatibilidad, temperaturas, consumo y recomendaciones. "
    "Haz preguntas de aclaración (resolución, preset, FPS objetivo, CPU/GPU/RAM/almacenamiento) "
    "cuando falte contexto. Responde breve, directo y conversacional."
)

_ALLOWED = re.compile(
    r"(pc|computadora|laptop|notebook|component(e|es)|gpu|cpu|ram|memoria|ssd|hdd|psu|fuente|motherboard|placa|cooler|gabinete|case|monitor|hz|"
    r"resoluci[oó]n|ajustes|preset|settings|bottleneck|cuello|temperatura|overclock|driver|controlador|benchmark|fps|frames?|latencia|rendimiento|"
    r"requirements?|requisitos|compatibilidad|dlss|fsr|xess|ray ?tracing|path ?tracing|juego|jugar|gaming|steam|epic|battle\.net|programa|software|"
    r"vram|rtx|gtx|nvidia|amd|radeon|ryzen|intel|i[3579]\b|cyberpunk|valorant|fortnite|gta|elden\s*ring|tarjeta(s)? (de )?video|gr[aá]fic(a|as))",
    re.IGNORECASE,
)

def _extract_text(resp) -> tuple[str, str]:
    # Devuelve (texto, razon) donde razon puede ser 'OK', 'SAFETY', 'NO_TEXT', etc.
    try:
        if getattr(resp, "text", None):
            return resp.text, "OK"

        cands = getattr(resp, "candidates", None) or []
        for c in cands:
            parts = getattr(getattr(c, "content", None), "parts", None) or []
            buf = []
            for p in parts:
                t = getattr(p, "text", None)
                if t:
                    buf.append(t)
            if buf:
                return "\n".join(buf), "OK"

        fb = getattr(resp, "prompt_feedback", None)
        if fb and getattr(fb, "block_reason", None):
            return "", "SAFETY"

        # finish_reason sin texto
        try:
            fr = getattr(getattr(cands[0], "finish_reason", None), "name", None) or str(getattr(cands[0], "finish_reason", ""))
            if fr:
                return "", f"FINISH_{fr}"
        except Exception:
            pass

    except Exception:
        pass
    return "", "NO_TEXT"


async def _gen_any(prompt: str, gen_cfg: dict, models: list[str], timeout_s: int) -> str:
    last_reason = "desconocido"
    for name in models:
        try:
            model = genai.GenerativeModel(name)
            has_async = hasattr(model, "generate_content_async")

            if has_async:
                resp = await asyncio.wait_for(
                    model.generate_content_async(prompt, generation_config=gen_cfg),
                    timeout=timeout_s,
                )
            else:
                resp = await asyncio.wait_for(
                    asyncio.to_thread(model.generate_content, prompt, generation_config=gen_cfg),
                    timeout=timeout_s,
                )

            text, reason = _extract_text(resp)
            if text.strip():
                return text.strip()

            last_reason = reason or "sin_texto"
            # Segundo intento rápido bajando temperatura si no hubo texto
            try:
                alt_cfg = dict(gen_cfg)
                alt_cfg["temperature"] = 0.3
                if has_async:
                    resp2 = await asyncio.wait_for(
                        model.generate_content_async(prompt, generation_config=alt_cfg),
                        timeout=min(12, timeout_s),
                    )
                else:
                    resp2 = await asyncio.wait_for(
                        asyncio.to_thread(model.generate_content, prompt, generation_config=alt_cfg),
                        timeout=min(12, timeout_s),
                    )
                text2, reason2 = _extract_text(resp2)
                if text2.strip():
                    return text2.strip()
                last_reason = reason2 or last_reason
            except Exception:
                pass

        except asyncio.TimeoutError:
            last_reason = "timeout"
        except Exception as e:
            last_reason = type(e).__name__

    # Fallback SIEMPRE (no se lanza excepción)
    if last_reason.upper().startswith("SAFETY"):
        return ("El modelo bloqueó el contenido. Reformula con datos técnicos: resolución, preset y FPS objetivo, "
                "y componentes (CPU/GPU/RAM/almacenamiento).")

    return ("No pude extraer texto del modelo (motivo: %s). Dime resolución, preset y FPS objetivo, y los "
            "componentes clave para darte una recomendación concreta." % last_reason)


async def chat_reply(history: list[dict], message: str, timeout_s: int = 25) -> str:
    scope = _ALLOWED.search(message) or any(_ALLOWED.search(t.get("content", "")) for t in (history or []))
    if not scope:
        return "Puedo ayudarte si lo enfocamos a hardware, requisitos o rendimiento. ¿Sobre qué juego/software o componente?"

    conv = [f"Sistema: {SYSTEM_PROMPT}"]
    for t in (history or []):
        role = "Usuario" if t.get("role") == "user" else "Asistente"
        conv.append(f"{role}: {t.get('content','')}")
    conv.append(f"Usuario: {message}")
    conv.append("Asistente:")

    gen_cfg = {"temperature": 0.7, "top_p": 0.9, "top_k": 40, "max_output_tokens": 512}
    models = [
        os.getenv("GEMINI_MODEL", "").strip() or "gemini-2.5-flash"
   
    ]

    try:
        return await _gen_any("\n".join(conv), gen_cfg, models, timeout_s)
    except Exception as e:
        # Ya casi no debería entrar aquí, pero por si acaso:
        return (f"[debug] {type(e).__name__}: {e}" if os.getenv("CHAT_DEBUG", "0") == "1"
                else "Hubo un error al responder.")
