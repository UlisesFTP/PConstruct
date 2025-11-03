import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv
from pathlib import Path

# --- CORRECCIÓN AQUÍ: Se necesita subir un nivel más ---
# app -> users -> services -> PConstruct (raíz)
env_path = Path(__file__).parent.parent.parent.parent / 'infra' / 'docker' / '.env'
load_dotenv(dotenv_path=env_path)
DATABASE_URL = os.getenv("USERS_DATABASE_URL")

# Añadimos una verificación para asegurarnos de que la URL se cargó
if not DATABASE_URL:
    raise ValueError(f"No se encontró la variable de entorno DATABASE_URL. Se buscó en: {env_path}")

# Crea el motor asíncrono
engine = create_async_engine(DATABASE_URL)

# Crea un generador de sesiones asíncronas
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

Base = declarative_base()

# Nueva dependencia para obtener la sesión asíncrona
async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session

