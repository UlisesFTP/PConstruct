import os
import logging
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base

logger = logging.getLogger(__name__)

env_path = Path(__file__).parent.parent.parent.parent / "infra" / "docker" / ".env"
load_dotenv(dotenv_path=env_path)

DATABASE_URL = os.getenv("PRICES_DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("PRICES_DATABASE_URL not set")

engine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    future=True,
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    expire_on_commit=False,
    class_=AsyncSession,
)

Base = declarative_base()


async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error(f"Error en la sesión de base de datos: {e}")
            raise
        finally:
            await session.close()
