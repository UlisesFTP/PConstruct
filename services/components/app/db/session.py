from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

# 1. Crear el "Engine" de SQLAlchemy
# Usamos la URL de la base de datos de nuestra configuración
engine = create_engine(
    settings.COMPONENTS_DATABASE_URL,
    pool_pre_ping=True # Recomendado para manejar reconexiones
)

# 2. Crear una clase de Sesión (SessionLocal)
# Esta será la que usaremos para cada transacción en la base de datos
SessionLocal = sessionmaker(
    autocommit=False, 
    autoflush=False, 
    bind=engine
)

# 3. Crear una Base declarativa
# Nuestras clases de modelos heredarán de esta 'Base'
Base = declarative_base()

# 4. Función de Dependencia (para FastAPI)
# Esto es crucial. Nos permite "inyectar" una sesión de base de datos
# en nuestros endpoints de la API.
def get_db():
    """
    Dependencia de FastAPI para obtener una sesión de base de datos.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 5. Función de inicialización (para crear tablas)
def init_db():
    """
    Crea todas las tablas en la base de datos.
    Esto se llama al iniciar la aplicación en main.py
    """
    # Importamos todos los modelos aquí para que 'Base' los conozca
    from app.models import component, offer, review, comment
    Base.metadata.create_all(bind=engine)