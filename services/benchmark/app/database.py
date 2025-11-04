# app/database.py
import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base

# Toma la URL del entorno (inyectada por docker-compose)
DATABASE_URL = (
    os.getenv("BENCHMARKS_DATABASE_URL")          # nombre que estás usando
    
)
if not DATABASE_URL:
    raise RuntimeError("Falta BENCHMARKS_DATABASE_URL en el entorno")

# Asegúrate que sea async: postgresql+asyncpg://user:pass@host:5432/db
engine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,   # revalida el socket antes de usarlo
    pool_recycle=1800,    # recicla conexiones inactivas (seg)
    echo=False,
    future=True,
)

AsyncSessionLocal = async_sessionmaker(bind=engine, expire_on_commit=False, class_=AsyncSession)
Base = declarative_base()

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
