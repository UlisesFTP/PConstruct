import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from pathlib import Path

print("Iniciando prueba de conexión a la base de datos...")

try:
    # --- Cargar variables de entorno ---
    # CORREGIDO: Sube 4 NIVELES (app -> users -> services -> PConstruct)
    env_path = Path(__file__).parent.parent.parent.parent / 'infra' / 'docker' / '.env'

    if not env_path.exists():
        raise FileNotFoundError(f"El archivo .env no se encontró en la ruta esperada: {env_path}")

    load_dotenv(dotenv_path=env_path)
    print(f"Cargando variables desde: {env_path}")

    DATABASE_URL = os.getenv("DATABASE_URL")

    if not DATABASE_URL:
        raise ValueError("La variable DATABASE_URL no se encontró en el archivo .env")

    print("DATABASE_URL encontrada. Intentando conectar...")

    # --- Probar Conexión ---
    engine = create_engine(DATABASE_URL)
    with engine.connect() as connection:
        result = connection.execute(text("SELECT version()"))
        db_version = result.fetchone()

        print("\n" + "="*30)
        print("✅ ¡CONEXIÓN EXITOSA! ✅")
        print(f"Versión de PostgreSQL: {db_version[0]}")
        print("="*30 + "\n")

except Exception as e:
    print("\n" + "="*30)
    print("❌ ¡ERROR DE CONEXIÓN! ❌")
    print("Detalles del error:")
    print(e)
    print("="*30 + "\n")
    print("Posibles soluciones:")
    print("1. Revisa que las credenciales en tu archivo .env son correctas.")
    print("2. Asegúrate de que tu instancia de RDS en AWS está en estado 'Available'.")
    print("3. Verifica que el Security Group de tu RDS permite el acceso desde tu IP actual.")