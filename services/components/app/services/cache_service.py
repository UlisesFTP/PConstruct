import redis.asyncio as redis
from redis.asyncio import Redis
from typing import Optional, Any
import json
from app.core.config import settings
from pydantic import BaseModel

_redis_client: Optional[Redis] = None

async def init_redis():
    """
    Inicializa la conexión global a Redis.
    """
    global _redis_client
    if _redis_client is None:
        try:
            _redis_client = await redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True # Decodifica respuestas de bytes a str
            )
            await _redis_client.ping()
            print("Conectado a Redis exitosamente.")
        except Exception as e:
            _redis_client = None
            print(f"Error al conectar con Redis: {e}")

async def close_redis():
    """
    Cierra la conexión a Redis.
    """
    if _redis_client:
        await _redis_client.close()
        print("Conexión a Redis cerrada.")

def get_redis_client() -> Redis:
    """
    Dependencia de FastAPI para obtener el cliente de Redis.
    (Alternativa a usarlo en los endpoints directamente)
    """
    if _redis_client is None:
        # Esto no debería pasar si init_redis() se llamó en startup
        raise RuntimeError("La conexión a Redis no ha sido inicializada.")
    return _redis_client

async def get_cache(key: str) -> Optional[Any]:
    """
    Obtiene un valor de la caché por su clave.
    Deserializa el JSON si encuentra datos.
    """
    if _redis_client is None: return None
    
    cached_data = await _redis_client.get(key)
    if cached_data:
        try:
            return json.loads(cached_data)
        except json.JSONDecodeError:
            # Si no es JSON, devuelve el texto plano
            return cached_data
    return None

async def set_cache(key: str, value: Any, expiration_seconds: int = 3600):
    """
    Establece un valor en la caché.
    Serializa a JSON si el valor es un modelo Pydantic o un dict/list.
    """
    if _redis_client is None: return
    
    if isinstance(value, BaseModel):
        value_to_cache = value.json()
    elif isinstance(value, (dict, list)):
        value_to_cache = json.dumps(value)
    else:
        value_to_cache = str(value)
        
    await _redis_client.setex(key, expiration_seconds, value_to_cache)

async def invalidate_cache(key_prefix: str):
    """
    Invalida (borra) claves de la caché que coincidan con un prefijo.
    Ej: 'components:*' borrará todas las listas paginadas.
    """
    if _redis_client is None: return
    
    if key_prefix.endswith('*'):
        # Borrar por prefijo
        keys_to_delete = []
        async for key in _redis_client.scan_iter(match=key_prefix):
            keys_to_delete.append(key)
        
        if keys_to_delete:
            await _redis_client.delete(*keys_to_delete)
            print(f"Caché invalidada para {len(keys_to_delete)} claves con prefijo '{key_prefix}'")
    else:
        # Borrar clave exacta
        await _redis_client.delete(key_prefix)
        print(f"Caché invalidada para la clave '{key_prefix}'")