from sqlalchemy.orm import Session
from . import models, schemas
from .scraper import get_scraper_for_retailer
import uuid
import asyncio

async def process_price_refresh(db: Session, component_ids: list[str], countries: list[str]):
    """Proceso asíncrono para actualizar precios"""
    retailers = ["amazon", "newegg"]  # Configurable
    
    tasks = []
    for component_id in component_ids:
        for country in countries:
            for retailer in retailers:
                tasks.append(
                    scrape_and_save_price(db, component_id, retailer, country)
                )
    
    await asyncio.gather(*tasks)

async def scrape_and_save_price(db: Session, component_id: str, retailer: str, country: str):
    scraper = get_scraper_for_retailer(retailer)
    price_data = await scraper.scrape(component_id, country)
    
    db_price = models.ComponentPrice(
        id=str(uuid.uuid4()),
        component_id=component_id,
        retailer=retailer,
        country_code=country,
        price=price_data["price"],
        currency=price_data["currency"],
        stock=price_data["stock"],
        metadata=price_data.get("metadata", {})
    )
    
    db.add(db_price)
    db.commit()