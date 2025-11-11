from pydantic import BaseModel
from typing import List, TypeVar, Generic

# 'T' puede ser cualquier tipo (ej. ComponentCard)
T = TypeVar('T')




class PaginatedResponse(BaseModel, Generic[T]):
    """
    Schema genérico para respuestas paginadas,
    tal como se definió en los requerimientos.
    """
    total_items: int
    page: int
    page_size: int
    items: List[T]