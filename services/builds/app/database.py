import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).parent.parent.parent.parent / 'infra' / 'docker' / '.env'
load_dotenv(dotenv_path=env_path)

DATABASE_URL = os.getenv("BUILDS_DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("No se encontró la variable de entorno BUILDS_DATABASE_URL")

engine = create_async_engine(
    DATABASE_URL,
    future=True,
    echo=False,
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    expire_on_commit=False,
    class_=AsyncSession,
    autoflush=False,
)

Base = declarative_base()

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session

async def init_db():
    import app.models
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
