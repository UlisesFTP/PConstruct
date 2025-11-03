import httpx
from typing import Dict, List, Tuple
from .config import COMPONENTS_SERVICE_URL
from .schemas import SoftwarePerformanceResult

# Esta función después:
# - llamará a component-service /components/{id}
# - extraerá performance_score de CPU y GPU
async def fetch_scores_for_components(component_ids: List[int]) -> Tuple[int, int]:
    """
    Regresa (cpu_score, gpu_score).
    Placeholder temporal: devuelve valores fijos para no romper nada.
    """
    # TODO: implementar llamada real al components-service
    cpu_score = 20000
    gpu_score = 30000
    return cpu_score, gpu_score


def classify_for_software(
    cpu_score: int,
    gpu_score: int,
    sw_row
) -> SoftwarePerformanceResult:
    # reglas básicas:
    #   recommended: cumple recomendados CPU y GPU
    #   playable: cumple mínimos
    #   unplayable: ni mínimos
    if cpu_score >= sw_row.rec_cpu_score and gpu_score >= sw_row.rec_gpu_score:
        tier = "recommended"
        notes = "Rendimiento alto / fluido según requisitos recomendados."
    elif cpu_score >= sw_row.min_cpu_score and gpu_score >= sw_row.min_gpu_score:
        tier = "playable"
        notes = "Debería ser jugable aceptable, quizá ajustes medios/bajos."
    else:
        tier = "unplayable"
        notes = "No cumple los requisitos mínimos estimados."

    return SoftwarePerformanceResult(
        software_name=sw_row.name,
        scenario=sw_row.scenario,
        tier=tier,
        notes=notes,
    )
