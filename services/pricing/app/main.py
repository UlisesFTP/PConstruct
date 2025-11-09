import logging
import asyncio
from contextlib import asynccontextmanager
from typing import Optional,List

from fastapi import FastAPI, BackgroundTasks, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from .database import get_db  # tu session maker
from .crud import get_component_prices  # usa tus funcs reales
from .queues import publish_price_job
from . import crud, queues, schemas
from .database import get_db, engine, Base
from fastapi.responses import JSONResponse
from app.queues import startup as amqp_startup, shutdown as amqp_shutdown, amqp_client


logger = logging.getLogger("pricing-service")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Service starting up...")

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async def initialize_rabbitmq():
        try:
            await queues.init_rabbitmq()
            logger.info("RabbitMQ exchange and queue declared.")
            await queues.consume_price_requests(crud.process_price_request)
            logger.info("RabbitMQ consumer loop finished.")
        except asyncio.CancelledError:
            logger.info("RabbitMQ consumer task cancelled.")
        except Exception as e:
            logger.error(f"Failed to initialize RabbitMQ or run consumer: {e}", exc_info=True)

    rabbitmq_task = asyncio.create_task(initialize_rabbitmq())
    logger.info("RabbitMQ initialization and consumer task created in background.")

    yield

    logger.info("Service shutting down...")
    if rabbitmq_task and not rabbitmq_task.done():
        rabbitmq_task.cancel()
        try:
            await rabbitmq_task
        except asyncio.CancelledError:
            logger.info("RabbitMQ consumer task successfully cancelled.")
    logger.info("Shutdown complete.")

app = FastAPI(title="Pricing Service", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def _amqp_up():
    await amqp_startup()

@app.on_event("shutdown")
async def _amqp_down():
    await amqp_shutdown()


@app.get("/prices/{component_id}")
async def get_prices(component_id: int,
                     country_code: str = Query("MX"),
                     db=Depends(get_db)):
    # 1) Consulta DB
    rows = await get_component_prices(db, component_id, country_code)
    if not rows:
        # 2) Encola scraping (no bloquea la respuesta)
        asyncio.create_task(publish_price_job({
            "component_id": component_id,
            "country_code": country_code,
            "retailers": ["amazon", "mercadolibre"]
        }))
        # 3) Devuelve [] (compatibilidad con el frontend actual)
        return JSONResponse(content=[], headers={"X-Refresh-Triggered": "true"})
    return rows

@app.post("/prices/refresh", status_code=202)
async def refresh_prices(body: dict):
    # Ejemplo de payload estandarizado
    payload = {
        "component_ids": body.get("component_ids") or [],
        "country_code": body.get("country_code", "MX"),
        "retailers": body.get("retailers") or ["amazon", "newegg"],
        "force": bool(body.get("force", False)),
    }
    await amqp_client.publish_refresh(payload)
    return {"status": "queued", "count": len(payload["component_ids"]) or None}