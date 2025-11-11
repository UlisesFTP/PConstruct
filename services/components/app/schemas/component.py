from pydantic import BaseModel, HttpUrl
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from .offer import OfferRead
from .review import ReviewRead

# --- Schema Base ---
class ComponentBase(BaseModel):
    name: str
    category: str
    brand: Optional[str] = None
    image_url: Optional[HttpUrl] = None

# --- Schema de Creación (para el Scraper) ---
class ComponentCreate(ComponentBase):
    pass

# --- Schema para la "Card" de Componente (Flutter) ---
# Este es el schema para la lista principal (GET /components)
# Es optimizado: solo muestra el PRECIO MÁS BAJO.
class ComponentCard(ComponentBase):
    id: int
    
    # Datos de la mejor oferta (denormalizados)
    # Esto evita que Flutter tenga que procesar una lista de ofertas
    price: Optional[Decimal] = None
    store: Optional[str] = None
    link: Optional[HttpUrl] = None

    class Config:
        from_attributes = True

# --- Schema para el "Detalle" del Componente (Flutter) ---
# Este es el schema para (GET /components/{id})
# Devuelve TODA la información:
class ComponentDetail(ComponentBase):
    id: int
    description: Optional[str] = None
    
    # Información agregada (calculada)
    average_rating: Optional[float] = None
    review_count: int = 0
    
    # --- ¡INICIO DE CORRECCIÓN! ---
    # Exponemos las relaciones de la base de datos directamente
    # Pydantic las convertirá a schemas gracias a from_attributes=True
    offers: List[OfferRead] = []
    reviews: List[ReviewRead] = []
    # --- FIN DE CORRECCIÓN! ---

    class Config:
        from_attributes = True