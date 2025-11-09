# PConstruct/services/pricing/app/queues.py
import aio_pika, json, os
from .config import settings
import asyncio # <-- Importa asyncio
import logging # <-- Importa logging
from typing import Optional

from dataclasses import dataclass

EXCHANGE_NAME = "pricing"
QUEUE_REFRESH = "pricing.refresh"
ROUTING_REFRESH = "refresh"

@dataclass(frozen=True)
class Routing:
    exchange: str = EXCHANGE_NAME
    queue_refresh: str = QUEUE_REFRESH
    routing_refresh: str = ROUTING_REFRESH


logger = logging.getLogger("pricing.amqp") # <-- Configura logger



RABBIT_URL = os.getenv("RABBITMQ_URL", "amqp://guest:guest@rabbitmq:5672/")
EXCHANGE = os.getenv("PRICING_EXCHANGE", "pricing")
ROUTING_KEY = os.getenv("PRICING_ROUTING_KEY", "fetch")
QUEUE_NAME = os.getenv("PRICING_QUEUE", "pricing.jobs")
ROUTING_KEY_REFRESH = os.getenv("PRICING_ROUTING_KEY_REFRESH", "pricing.refresh")


MAX_RETRIES = 5 # Número máximo de intentos
RETRY_DELAY = 5 # Segundos entre intentos

async def connect_rabbitmq_with_retry():
    """Intenta conectarse a RabbitMQ con reintentos."""
    last_exception = None
    for attempt in range(MAX_RETRIES):
        try:
            logger.info(f"Intentando conectar a RabbitMQ (intento {attempt + 1}/{MAX_RETRIES})... URL: {settings.RABBITMQ_URL}")
            # Añadir un timeout corto para la conexión inicial
            connection = await asyncio.wait_for(
                aio_pika.connect_robust(settings.RABBITMQ_URL),
                timeout=10 
            )
            logger.info("¡Conectado exitosamente a RabbitMQ!")
            return connection
        # Capturar ConnectionRefusedError específicamente
        except ConnectionRefusedError as e:
            last_exception = e
            if attempt == MAX_RETRIES - 1:
                logger.error("Máximos reintentos alcanzados. No se pudo conectar a RabbitMQ.")
                break # Salir del bucle después del último intento
            logger.warning(f"Conexión rechazada. Reintentando en {RETRY_DELAY} segundos...")
            await asyncio.sleep(RETRY_DELAY)
        # Capturar otros posibles errores de conexión (ej. timeouts, DNS errors)
        except (asyncio.TimeoutError, OSError, aio_pika.exceptions.AMQPConnectionError) as e:
            last_exception = e
            if attempt == MAX_RETRIES - 1:
                logger.error(f"Máximos reintentos alcanzados. Error final al conectar: {e}")
                break
            logger.warning(f"Error de conexión ({type(e).__name__}). Reintentando en {RETRY_DELAY} segundos...")
            await asyncio.sleep(RETRY_DELAY)
        # Capturar cualquier otra excepción inesperada
        except Exception as e:
             last_exception = e
             logger.error(f"Error inesperado al conectar a RabbitMQ: {e}", exc_info=True)
             break # No reintentar en errores inesperados

    # Si salimos del bucle sin éxito, relanzar el último error conocido
    raise ConnectionError(f"No se pudo conectar a RabbitMQ después de {MAX_RETRIES} intentos.") from last_exception


async def init_rabbitmq():
    """Declara el exchange y la cola si no existen."""
    try:
        connection = await connect_rabbitmq_with_retry() # Usa la función con reintentos
        async with connection:
            channel = await connection.channel()
            logger.info("Declarando exchange 'price_updates' y cola 'price_requests'...")
            exchange = await channel.declare_exchange("price_updates", type="direct", durable=True)
            queue = await channel.declare_queue("price_requests", durable=True)
            await queue.bind(exchange, routing_key="")
            logger.info("RabbitMQ exchange y queue declarados y vinculados correctamente.")
    except Exception as e:
        logger.error(f"Fallo crítico al inicializar RabbitMQ (declarar exchange/queue): {e}", exc_info=True)
        # Decide si quieres que el servicio falle completamente aquí o no
        raise # Relanzar para que el startup falle si RabbitMQ es esencial

async def consume_price_requests(callback):
    """Consume mensajes de la cola 'price_requests'."""
    try:
        connection = await connect_rabbitmq_with_retry() # Usa la función con reintentos
        async with connection:
            channel = await connection.channel()
            # Asegurar que la cola existe (puede ser redundante pero seguro)
            queue = await channel.declare_queue("price_requests", durable=True)
            logger.info("Iniciando consumidor de RabbitMQ para 'price_requests'...")
            async with queue.iterator() as queue_iter:
                async for message in queue_iter:
                    logger.debug("Mensaje recibido de RabbitMQ.")
                    async with message.process(): # ACK/NACK handling
                        try:
                            # Ejecuta el callback en un bloque try/except
                            await callback(message.body)
                            logger.debug("Mensaje procesado exitosamente.")
                        except Exception as cb_exc:
                            # Loguear error en el callback sin detener al consumidor
                            logger.error(f"Error procesando mensaje de RabbitMQ en el callback: {cb_exc}", exc_info=True)
                            # El mensaje será 'nack'-eado automáticamente por message.process()
    except ConnectionError as e:
         # Error después de reintentos de conexión
         logger.error(f"No se pudo establecer conexión con RabbitMQ para el consumidor: {e}")
         # Decide cómo manejar esto: ¿el servicio debe fallar o seguir intentando?
         # Por ahora, el startup fallará por el raise en connect_rabbitmq_with_retry
    except Exception as e:
        logger.error(f"Error inesperado en el consumidor de RabbitMQ: {e}", exc_info=True)
        # Considera reiniciar el consumidor o manejar el error
        
        
async def publish_price_job(message: dict):
    connection = await aio_pika.connect_robust(RABBIT_URL)
    try:
        channel = await connection.channel()
        exchange = await channel.declare_exchange(EXCHANGE, aio_pika.ExchangeType.DIRECT, durable=True)
        body = json.dumps(message).encode("utf-8")
        await exchange.publish(
            aio_pika.Message(body=body, delivery_mode=aio_pika.DeliveryMode.PERSISTENT),
            routing_key=ROUTING_KEY,
        )
        logger.info(f"[pricing] queued: {message}")
    finally:
        await connection.close()
        
        
class AmqpClient:
    def __init__(self, url: str | None = None):
        self._url = url or settings.RABBITMQ_URL
        self._conn: Optional[aio_pika.RobustConnection] = None
        self._chan: Optional[aio_pika.abc.AbstractChannel] = None
        self._exchange: Optional[aio_pika.Exchange] = None

    async def connect(self):
        if self._conn and not self._conn.is_closed:
            return
        self._conn = await aio_pika.connect_robust(self._url, heartbeat=30, timeout=10)
        self._chan = await self._conn.channel(publisher_confirms=True)
        await self._chan.set_qos(prefetch_count=8)

        self._exchange = await self._chan.declare_exchange(
            EXCHANGE, aio_pika.ExchangeType.DIRECT, durable=True
        )
        queue = await self._chan.declare_queue(QUEUE_NAME, durable=True)
        await queue.bind(self._exchange, ROUTING_KEY_REFRESH)
        logger.info("AMQP connected. Exchange=%s Queue=%s", EXCHANGE, QUEUE_NAME)

    async def close(self):
        try:
            if self._chan and not self._chan.is_closed:
                await self._chan.close()
            if self._conn and not self._conn.is_closed:
                await self._conn.close()
        except Exception:
            logger.exception("Error closing AMQP")

    async def publish_refresh(self, payload: dict):
        await self.connect()
        body = json.dumps(payload).encode("utf-8")
        msg = aio_pika.Message(body, delivery_mode=aio_pika.DeliveryMode.PERSISTENT)
        await self._exchange.publish(msg, routing_key=ROUTING_KEY_REFRESH)

amqp_client = AmqpClient()

async def startup():
    await amqp_client.connect()

async def shutdown():
    await amqp_client.close()