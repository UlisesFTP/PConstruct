from fastapi import FastAPI, BackgroundTasks, Depends
from fastapi.middleware.cors import CORSMiddleware
from . import models, schemas, crud, scraper, queues
from .database import SessionLocal, engine
from .config import settings
import logging
import httpx
 
# Configuración inicial
app = FastAPI(title="Pricing Service", version="1.0.0")
logger = logging.getLogger("pricing-service")

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Eventos
@app.on_event("startup")
async def startup():
    models.Base.metadata.create_all(bind=engine)
    await queues.init_rabbitmq()
    logger.info("Service started")

# Dependencias
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Endpoints
@app.post("/prices/refresh", status_code=202)
async def refresh_prices(
    request: schemas.RefreshPricesRequest,
    background_tasks: BackgroundTasks,
    db=Depends(get_db)
):
    """Trigger price scraping for components"""
    background_tasks.add_task(
        crud.process_price_refresh,
        db=db,
        component_ids=request.component_ids,
        countries=request.countries
    )
    return {"message": "Price update started"}

@app.get("/prices/{component_id}")
async def get_prices(
    component_id: str,
    country: str | None = None,
    timeframe_days: int = 30,
    db=Depends(get_db)
):
    """Obtener precios históricos de un componente"""
    return crud.get_component_prices(
        db=db,
        component_id=component_id,
        country_code=country,
        timeframe_days=timeframe_days
    )

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Consumer de RabbitMQ
@app.on_event("startup")
async def start_consumers():
    await queues.consume_price_requests(crud.process_price_request)