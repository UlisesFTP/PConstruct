from .base_estimator import BaseEstimator
from ..integrations import steam
import random

class GamingEstimator(BaseEstimator):
    """Estimador de rendimiento para juegos"""
    
    def estimate(self, components: list) -> dict:
        # Identificar componentes clave
        gpu = next((c for c in components if c["category"] == "GPU"), None)
        cpu = next((c for c in components if c["category"] == "CPU"), None)
        ram = next((c for c in components if c["category"] == "RAM"), None)
        
        if not gpu or not cpu:
            raise ValueError("Missing GPU or CPU for gaming estimation")
        
        # Calcular puntaje base basado en componentes
        gpu_score = self._gpu_score(gpu["model"])
        cpu_score = self._cpu_score(cpu["model"])
        ram_score = int(ram["specs"].get("size", 16)) / 16  # Normalizado a 16GB
        
        # Puntaje combinado (fórmula simplificada)
        total_score = (gpu_score * 0.7) + (cpu_score * 0.2) + (ram_score * 0.1)
        
        # Estimación de FPS en diferentes juegos
        games = self._estimate_game_performance(gpu_score, cpu_score)
        
        return {
            "fps": {
                "average": sum(games.values()) // len(games),
                "min": min(games.values()),
                "max": max(games.values())
            },
            "score": total_score,
            "details": games
        }
    
    def _estimate_game_performance(self, gpu_score: float, cpu_score: float) -> dict:
        """Estimar FPS para juegos populares"""
        # En una implementación real, usaríamos datos de Steam o benchmarks
        return {
            "Cyberpunk 2077": int(30 + (gpu_score * 0.7)),
            "Call of Duty: Warzone": int(60 + (gpu_score * 0.6) + (cpu_score * 0.4)),
            "Fortnite": int(120 + (gpu_score * 0.5) + (cpu_score * 0.3)),
            "Microsoft Flight Simulator": int(40 + (gpu_score * 0.8) + (cpu_score * 0.5)),
            "Red Dead Redemption 2": int(50 + (gpu_score * 0.75))
        }
    
    def _gpu_score(self, model: str) -> float:
        """Puntaje basado en modelo de GPU"""
        # En una implementación real, usaríamos una base de datos de benchmarks
        if "RTX 4090" in model: return 100
        if "RTX 4080" in model: return 90
        if "RTX 4070" in model: return 75
        if "RTX 3060" in model: return 60
        return 50  # Default
    
    def _cpu_score(self, model: str) -> float:
        """Puntaje basado en modelo de CPU"""
        if "i9-13900K" in model: return 100
        if "Ryzen 9 7950X" in model: return 98
        if "i7-13700K" in model: return 85
        if "Ryzen 7 7800X3D" in model: return 82
        return 60  # Default