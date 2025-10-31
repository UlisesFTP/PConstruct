# PConstruct/services/pricing/app/crud.py
from typing import Optional, Dict, List
from sqlalchemy.orm import Session # Probablemente no la necesites si todo es async
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from . import models, schemas
from .scraper import get_prices_for_component
import uuid
import asyncio
from datetime import datetime, timedelta
import httpx
import logging
from .config import settings
from .database import AsyncSessionLocal # <-- Importa AsyncSessionLocal
import json # <-- Asegúrate de importar json

logger = logging.getLogger(__name__)

# --- Función para obtener detalles del componente ---
async def get_component_details(component_id: int) -> Optional[Dict]:
    # ... (código existente) ...
    if not settings.COMPONENT_SERVICE_URL:
        logger.error("COMPONENT_SERVICE_URL no está configurado.")
        return None
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{settings.COMPONENT_SERVICE_URL}/components/{component_id}")
            response.raise_for_status()
            return response.json()
    except Exception as e:
        logger.error(f"Error fetching component details for ID {component_id}: {e}")
        return None

# --- Función que inicia el scraping ---
async def process_price_refresh(db: AsyncSession, component_ids: List[int], countries: List[str]):
    logger.info(f"Starting price refresh for components: {component_ids} in countries: {countries}")
    semaphore = asyncio.Semaphore(5) # Limita concurrencia
    tasks = []

    # Obtener detalles para todos los componentes necesarios primero
    component_details_map = {}
    details_tasks = [get_component_details(comp_id) for comp_id in component_ids]
    results = await asyncio.gather(*details_tasks)

    for i, details in enumerate(results):
        comp_id = component_ids[i]
        if details and 'name' in details:
            component_details_map[comp_id] = details['name']
        else:
            logger.warning(f"Could not get details or name for component ID {comp_id}. Skipping.")

    # Crear tareas de scraping solo para los componentes con nombre
    for component_id, component_name in component_details_map.items():
        for country in countries:
             tasks.append(
                 # Pasa db aquí si scrape_and_save_prices la necesita directamente,
                 # sino, puedes quitarla y obtenerla dentro de scrape_and_save_prices
                 scrape_and_save_prices(db, component_id, component_name, country, semaphore)
             )

    if tasks:
        await asyncio.gather(*tasks)
    logger.info(f"Finished price refresh for components: {component_ids}")


# ===> AÑADE ESTA FUNCIÓN <===
async def process_price_request(message_body: bytes):
    """
    Procesa un mensaje recibido de RabbitMQ para iniciar la actualización de precios.
    Parsea el mensaje, obtiene una sesión de DB y llama a process_price_refresh.
    """
    try:
        # Decodifica y parsea el mensaje JSON
        data = json.loads(message_body.decode('utf-8'))
        component_ids = data.get("component_ids")
        countries = data.get("countries", ["MX"]) # Default a MX si no se especifica

        if not component_ids or not isinstance(component_ids, list):
            logger.warning(f"Mensaje de RabbitMQ recibido sin 'component_ids' válidos o no es una lista. Ignorando. Data: {data}")
            return

        logger.info(f"Procesando solicitud de RabbitMQ para IDs: {component_ids}, Países: {countries}")

        # Obtener una nueva sesión de base de datos asíncrona para esta tarea
        async with AsyncSessionLocal() as db_session:
            # Llamar a la función que realmente hace el trabajo de scraping y guardado
            await process_price_refresh(db=db_session, component_ids=component_ids, countries=countries)
        logger.info(f"Solicitud de RabbitMQ completada para IDs: {component_ids}")

    except json.JSONDecodeError:
        logger.error(f"Error al decodificar mensaje JSON de RabbitMQ: {message_body.decode('utf-8', errors='ignore')}") # errors='ignore' por si acaso
    except Exception as e:
        logger.error(f"Error procesando mensaje de RabbitMQ: {e}", exc_info=True) # exc_info=True para traceback
# ===> FIN DE LA FUNCIÓN A AÑADIR <===


# --- Función de scraping y guardado individual ---
# (Asegúrate de tener SOLO UNA definición de esta función)
async def scrape_and_save_prices(db: AsyncSession, component_id: int, component_name: str, country: str, semaphore: asyncio.Semaphore):
    """Obtiene precios de todas las tiendas y los guarda."""
    async with semaphore:
        logger.info(f"Scraping prices for '{component_name}' (ID: {component_id}) in {country}...")
        try:
            all_prices = await get_prices_for_component(component_name) # Llama al scraper

            new_price_entries = []
            for store, products in all_prices.items():
                if not products:
                    # logger.info(f"No prices found for {component_name} at {store}.") # Opcional: puede ser muy verboso
                    continue

                # Lógica simple: tomar el primer resultado
                best_match = products[0]

                # Crear entrada en DB
                db_price = models.ComponentPrice(
                    id=str(uuid.uuid4()),
                    component_id=str(component_id),
                    retailer=store,
                    country_code=country, # Guardamos el país
                    price=best_match.get('price'),
                    currency=best_match.get('currency', 'MXN'),
                    stock=best_match.get('stock', 'unknown'),
                    url=best_match.get('link'),
                    timestamp=datetime.utcnow(),
                    additional_data={'scraped_name': best_match.get('name')}
                )
                new_price_entries.append(db_price)
                # logger.info(f"Found price for {component_name} at {store}: {db_price.price} {db_price.currency}") # Opcional

            if new_price_entries:
                db.add_all(new_price_entries)
                await db.commit()
                logger.info(f"Saved {len(new_price_entries)} price entries for component ID {component_id}.")

        except Exception as e:
            logger.error(f"Failed scraping/saving prices for component ID {component_id}, name '{component_name}': {e}", exc_info=True)
            await db.rollback() # Hacer rollback si algo falla al guardar


# --- Función para obtener precios de la DB ---
async def get_component_prices(
    db: AsyncSession,
    component_id: int,
    country_code: Optional[str] = None,
    timeframe_days: int = 7
):
    """Obtener precios históricos (recientes) de un componente."""
    # ... (código existente sin cambios) ...
    query = (
        select(models.ComponentPrice)
        .where(models.ComponentPrice.component_id == str(component_id))
        .where(models.ComponentPrice.timestamp >= datetime.utcnow() - timedelta(days=timeframe_days))
        .order_by(desc(models.ComponentPrice.timestamp))
    )
    if country_code:
        query = query.where(models.ComponentPrice.country_code == country_code)

    result = await db.execute(query)
    prices = result.scalars().all()
    return prices