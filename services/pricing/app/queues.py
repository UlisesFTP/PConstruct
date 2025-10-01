import aio_pika
from .config import settings
from . import crud

async def init_rabbitmq():
    connection = await aio_pika.connect(settings.RABBITMQ_URL)
    channel = await connection.channel()
    await channel.declare_exchange("price_updates", type="direct")
    await channel.declare_queue("price_requests")
    await channel.queue_bind("price_requests", "price_updates")

async def consume_price_requests(callback):
    connection = await aio_pika.connect(settings.RABBITMQ_URL)
    channel = await connection.channel()
    
    async for message in channel.queue("price_requests"):
        async with message.process():
            data = message.body.decode()
            await callback(data)