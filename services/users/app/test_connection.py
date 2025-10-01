# users/app/test_connection.py
import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("No se encontró la variable de entorno DATABASE_URL para el test")

try:
    # Test con SQLAlchemy (más simple y relevante)
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT version()"))
        db_version = result.fetchone()
        print("✅ Conexión con SQLAlchemy exitosa.")
        print(f"✅ Versión de la base de datos: {db_version[0]}")
        
except Exception as e:
    print(f"❌ Error de conexión: {e}")