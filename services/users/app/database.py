# users/app/database.py
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Cargar variables de entorno desde un archivo .env (útil para desarrollo local)
load_dotenv()

# Leer la variable de entorno. Si no existe, usa una cadena vacía como fallback.
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("No se encontró la variable de entorno DATABASE_URL")

# Motor con configuración robusta para RDS
engine = create_engine(
    DATABASE_URL, 
    echo=False, # Cambiado a False para no llenar los logs en producción
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=1800,
    connect_args={
        "connect_timeout": 10,
        "application_name": "users_service"
    }
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()