import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv
from pathlib import Path

# NOTA: Usaremos una nueva variable de entorno para la base de datos de posts.
# Puedes apuntarla a la misma base de datos si quieres, pero usar variables 
# separadas es una buena práctica para el futuro.
env_path = Path(__file__).parent.parent.parent.parent / 'infra' / 'docker' / '.env'
load_dotenv(dotenv_path=env_path)
DATABASE_URL = os.getenv("POSTS_DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("No se encontró la variable de entorno POSTS_DATABASE_URL")

# Crear el motor asíncrono
engine = create_async_engine(DATABASE_URL)

# Crear un generador de sesiones asíncronas
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

Base = declarative_base()

# Dependencia para obtener la sesión asíncrona en los endpoints
async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session