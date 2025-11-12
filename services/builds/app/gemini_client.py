# services/builds/app/gemini_client.py

import google.generativeai as genai
import json
import os
from .config import GEMINI_API_KEY # Importamos la clave que configuramos

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