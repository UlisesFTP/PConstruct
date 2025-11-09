# app/worker.py
import asyncio
import json
import logging
from typing import Any, Dict, List, Optional

import aio_pika
from pydantic import BaseModel, Field, ValidationError

from app.config import settings  # must expose RABBITMQ_URL, DATABASE_URL
from app.queues import EXCHANGE_NAME, QUEUE_REFRESH, ROUTING_REFRESH
from app.database import AsyncSessionLocal  # async sessionmaker(engine)
from app.scraper import get_prices_for_component
from app import crud

logger = logging.getLogger("pricing.worker")
logging.basicConfig(level=logging.INFO)

class RefreshMessage(BaseModel):
    country: str = Field(..., alias="country")
    components: List[int] = Field(..., alias="components")
    retailers: Optional[List[str]] = None
    force: bool = False

async def _process_message(body: bytes) -> None:
    # 1) Parse
    try:
        payload = RefreshMessage.model_validate_json(body)
    except ValidationError as ve:
        logger.error("Invalid refresh message: %s", ve)
        return

    logger.info(
        "REFRESH received: country=%s components=%s retailers=%s force=%s",
        payload.country, payload.components, payload.retailers, payload.force
    )

    # 2) Scrape + 3) Save
    async with AsyncSessionLocal() as session:
        for comp_id in payload.components:
            try:
                offers = await get_prices_for_component(
                    component_id=comp_id,
                    country=payload.country,
                    retailers=payload.retailers,
                    force=payload.force,
                )
                count = len(offers or [])
                logger.info("[comp=%s] scraped %d offers", comp_id, count)

                if count:
                    saved = await crud.save_prices_for_component(
                        session=session,
                        component_id=comp_id,
                        country=payload.country,
                        offers=offers,
                    )
                    await session.commit()
                    logger.info("[comp=%s] saved %d offers", comp_id, saved)
                else:
                    logger.info("[comp=%s] nothing to save", comp_id)
            except Exception as e:
                # Don't explode on a single component; continue with others
                logger.exception("[comp=%s] scraping/saving failed: %s", comp_id, e)

async def main() -> None:
    logger.info("[worker] RABBITMQ_URL = %s", settings.RABBITMQ_URL)

    # 0) Connect and declare topology
    connection = await aio_pika.connect_robust(settings.RABBITMQ_URL, heartbeat=30, timeout=10)
    channel = await connection.channel()
    await channel.set_qos(prefetch_count=1)

    exchange = await channel.declare_exchange(EXCHANGE_NAME, aio_pika.ExchangeType.DIRECT, durable=True)
    queue = await channel.declare_queue(QUEUE_REFRESH, durable=True)
    await queue.bind(exchange, ROUTING_REFRESH)

    logger.info("[worker] Waiting for messages on %s/%s", EXCHANGE_NAME, QUEUE_REFRESH)

    async with queue.iterator() as queue_iter:
        async for message in queue_iter:
            async with message.process(requeue=False):
                try:
                    await _process_message(message.body)
                except Exception as e:
                    logger.exception("Handler crashed: %s", e)
                    # Let `requeue=False` drop this message; you can flip to True if you want retries.

if __name__ == "__main__":
    asyncio.run(main())
