# PConstruct/services/pricing/app/schemas.py

from pydantic import BaseModel, ConfigDict # Asegúrate de importar ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime

class RefreshPricesRequest(BaseModel):
    component_ids: List[int] # Asumiendo que los IDs de componente son enteros
    countries: List[str] = ['MX'] # Puedes dejar un default o quitarlo para hacerlo requerido

class PriceData(BaseModel):
    """Representa un punto de precio individual para mostrar"""
    id: str
    component_id: str
    retailer: str
    country_code: str
    price: Optional[float] = None
    currency: Optional[str] = None
    stock: Optional[str] = None
    url: Optional[str] = None
    timestamp: datetime
    additional_data: Optional[Dict[str, Any]] = None # Corregido de 'metadata'

    # Usa model_config para Pydantic V2
    model_config = ConfigDict(from_attributes=True)