# PConstruct/services/components/app/database.py
import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
import logging
from .config import settings
from typing import AsyncGenerator # <-- 1. IMPORTA AsyncGenerator

logger = logging.getLogger(__name__)

DATABASE_URL = settings.COMPONENTS_DATABASE_URL

if not DATABASE_URL:
    logger.error("COMPONENTS_DATABASE_URL no se encontró en el objeto settings.")
    raise ValueError("COMPONENTS_DATABASE_URL no se encontró en el objeto settings.")
else:
    logger.info("COMPONENTS_DATABASE_URL cargada exitosamente desde settings.")


try:
    engine = create_async_engine(DATABASE_URL, pool_pre_ping=True)
    logger.info("Motor de base de datos asíncrono creado.")
except Exception as e:
    logger.error(f"Error al crear el motor de base de datos: {e}")
    raise

AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

Base = declarative_base()

# Dependencia para obtener la sesión asíncrona
async def get_db() -> AsyncGenerator[AsyncSession, None]: # <-- 2. CORRIGE EL TIPO DE RETORNO
    async with AsyncSessionLocal() as session:
        # logger.debug("Sesión de base de datos asíncrona obtenida.")
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error(f"Error en la sesión de base de datos: {e}")
            raise
        finally:
            await session.close()
            # logger.debug("Sesión de base de datos asíncrona cerrada.")