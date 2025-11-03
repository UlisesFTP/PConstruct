from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from .config import BENCHMARKS_DATABASE_URL

engine = create_async_engine(BENCHMARKS_DATABASE_URL)

AsyncSessionLocal = async_sessionmaker(
    engine,
    expire_on_commit=False,
    class_=AsyncSession,
)

Base = declarative_base()

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session

async def init_db():
    # crea las tablas si no existen
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
