import logging
import asyncio
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, BackgroundTasks, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession

from . import crud, queues, schemas
from .database import get_db, engine, Base

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

@app.post("/prices/refresh", status_code=202)
async def refresh_prices(
    request: schemas.RefreshPricesRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    background_tasks.add_task(
        crud.process_price_refresh,
        db=db,
        component_ids=request.component_ids,
        countries=request.countries,
    )
    return {"message": "Price update process started in background"}

@app.get("/prices/{component_id}")
async def get_prices(
    component_id: int,
    country_code: Optional[str] = None,
    timeframe_days: int = 7,
    db: AsyncSession = Depends(get_db),
):
    prices = await crud.get_component_prices(
        db=db,
        component_id=component_id,
        country_code=country_code,
        timeframe_days=timeframe_days,
    )
    return prices

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
