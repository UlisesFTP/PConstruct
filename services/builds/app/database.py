# services/builds/app/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from .config import DATABASE_URL
from typing import AsyncGenerator

# Convertimos la URL de DB para que use el driver asyncpg
ASYNC_DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

# 1. Usamos create_async_engine
engine = create_async_engine(
    ASYNC_DATABASE_URL,
    # echo=True # Descomenta para debugging de SQL
)

# 2. Usamos async_sessionmaker
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False  # Requerido para async
)

# 3. Base sigue igual
Base = declarative_base()

# 4. El generador de sesión ahora es asíncrono
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session