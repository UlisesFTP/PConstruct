# app/worker.py
import asyncio, json, logging
import os
import aio_pika
import socket
from app.config import settings
from app.queues import EXCHANGE, QUEUE_NAME
import time

logger = logging.getLogger("pricing.worker")
logging.basicConfig(level=logging.INFO)

async def wait_for_rabbitmq(max_retries=30, retry_interval=5):
    """Wait for RabbitMQ to be ready"""
    host = settings.RABBITMQ_URL.split("@",1)[-1].split(":",1)[0].replace("/","")
    
    for attempt in range(max_retries):
        try:
            # Test DNS resolution first
            ip = socket.gethostbyname(host)
            logger.info(f"Attempt {attempt + 1}/{max_retries}: Host '{host}' resolves to {ip}")
            
            # Test TCP connection
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(host, 5672), 
                timeout=5.0
            )
            writer.close()
            await writer.wait_closed()
            logger.info("RabbitMQ is ready!")
            return True
            
        except (socket.gaierror, ConnectionRefusedError, asyncio.TimeoutError) as e:
            logger.warning(f"RabbitMQ not ready (attempt {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                logger.info(f"Retrying in {retry_interval} seconds...")
                await asyncio.sleep(retry_interval)
            else:
                logger.error(f"RabbitMQ failed to become ready after {max_retries} attempts")
                return False

async def handle_refresh(body: bytes):
    try:
        payload = json.loads(body.decode("utf-8"))
        country = payload.get("country_code", "MX")
        component_ids = payload.get("component_ids") or []
        logger.info("REFRESH payload received: country=%s components=%s", country, component_ids)

        # TODO: aquí llamas a tu lógica real de scraping/ETL (scraper.py)
        # await scrape_and_persist(country=country, component_ids=component_ids)

    except Exception as e:
        logger.exception("Error handling refresh payload: %s", e)

async def main():
    # Wait for RabbitMQ to be ready
    if not await wait_for_rabbitmq():
        logger.error("Failed to connect to RabbitMQ. Exiting.")
        return

    # Now connect with retry logic
    for attempt in range(10):
        try:
            conn = await aio_pika.connect_robust(
                settings.RABBITMQ_URL, 
                heartbeat=30, 
                timeout=10
            )
            break
        except Exception as e:
            logger.warning(f"Connection attempt {attempt + 1}/10 failed: {e}")
            if attempt < 9:
                await asyncio.sleep(5)
            else:
                logger.error("All connection attempts failed")
                return

    async with conn:
        channel = await conn.channel()
        await channel.set_qos(prefetch_count=8)

        # Asegura la cola/binding (idempotente)
        exchange = await channel.declare_exchange(EXCHANGE, aio_pika.ExchangeType.DIRECT, durable=True)
        queue = await channel.declare_queue(QUEUE_NAME, durable=True)
        await queue.bind(exchange, routing_key=os.getenv("PRICING_ROUTING_KEY_REFRESH", "pricing.refresh"))

        logger.info("Worker consuming from queue=%s ...", QUEUE_NAME)
        async with queue.iterator() as qiter:
            async for message in qiter:
                async with message.process():
                    await handle_refresh(message.body)

if __name__ == "__main__":
    asyncio.run(main())