from pydantic import BaseModel, HttpUrl
from datetime import datetime
from decimal import Decimal

# --- Schema Base ---
# Atributos que son comunes a la lectura y creación
class OfferBase(BaseModel):
    store: str
    price: Decimal
    link: HttpUrl # Pydantic validará que esto sea una URL válida

# --- Schema de Creación (para el Scraper) ---
# Datos necesarios para crear una oferta en la DB
class OfferCreate(OfferBase):
    pass

# --- Schema de Lectura (para la API) ---
# Datos que enviaremos a Flutter
class OfferRead(OfferBase):
    id: int
    last_updated: datetime

    class Config:
        from_attributes = True