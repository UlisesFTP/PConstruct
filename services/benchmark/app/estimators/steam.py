import httpx
from ..config import settings
import logging

logger = logging.getLogger("steam-integration")

async def get_game_performance_data(game_id: int):
    """Obtener datos de rendimiento para un juego específico de Steam"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.steampowered.com/ISteamApps/GetAppList/v2/",
                params={"key": settings.STEAM_API_KEY}
            )
            # Este endpoint es solo para demostración
            # En realidad necesitaríamos un endpoint que proporcione datos de rendimiento
            
            # Simular datos de rendimiento
            return {
                "game_id": game_id,
                "average_fps": random.randint(60, 120),
                "min_fps": random.randint(45, 90),
                "max_fps": random.randint(90, 240)
            }
    except Exception as e:
        logger.error(f"Error fetching Steam data: {str(e)}")
        return None

def estimate_fps_for_game(gpu_model: str, cpu_model: str, game_id: int) -> int:
    """Estimar FPS basado en hardware y juego"""
    # En una implementación real, usaríamos datos históricos y modelos predictivos
    base_performance = {
        "RTX 4090": 120,
        "RTX 4080": 100,
        "RTX 4070": 85,
        "RTX 3060": 70
    }
    
    gpu_perf = base_performance.get(gpu_model, 60)
    
    # Ajustar según CPU
    if "i9" in cpu_model or "Ryzen 9" in cpu_model:
        gpu_perf *= 1.1
    elif "i7" in cpu_model or "Ryzen 7" in cpu_model:
        gpu_perf *= 1.0
    else:
        gpu_perf *= 0.9
    
    # Ajustar según juego
    demanding_games = [730, 578080]  # CS2, PUBG
    if game_id in demanding_games:
        gpu_perf *= 0.8
    
    return int(gpu_perf)