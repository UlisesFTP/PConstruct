import asyncio
import bcrypt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from . import models, schemas
from sqlalchemy import select
from typing import List
from sqlalchemy import select, or_

# --- FUNCIONES DE BÚSQUEDA ASÍNCRONAS ---

async def get_user_by_username(db: AsyncSession, username: str):
    result = await db.execute(select(models.User).filter(models.User.username == username))
    return result.scalars().first()

async def get_user_by_email(db: AsyncSession, email: str):
    result = await db.execute(select(models.User).filter(models.User.email == email))
    return result.scalars().first()

async def get_user_by_id(db: AsyncSession, user_id: int):
    result = await db.execute(select(models.User).filter(models.User.user_id == user_id))
    return result.scalars().first()

# --- FUNCIONES DE MODIFICACIÓN ASÍNCRONAS ---

async def create_user(db: AsyncSession, user: schemas.UserCreate):
    password_bytes = user.password.encode('utf-8')
    salt = bcrypt.gensalt()
    
    # bcrypt es bloqueante (CPU-bound), lo ejecutamos en un hilo aparte
    hashed_password_bytes = await asyncio.to_thread(bcrypt.hashpw, password_bytes, salt)
    
    hashed_password = hashed_password_bytes.decode('utf-8')

    db_user = models.User(
        username=user.username, 
        email=user.email,
        name=user.name,
        hashed_password=hashed_password
    )
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

async def verify_user_email(db: AsyncSession, user: models.User):
    """Marca a un usuario como verificado."""
    user.is_verified = True
    await db.commit()
    await db.refresh(user)
    return user

async def authenticate_user(db: AsyncSession, username: str, password: str):
    """Autentica un usuario de forma asíncrona."""
    user = await get_user_by_username(db, username)
    if not user:
        return None

    password_bytes = password.encode('utf-8')
    hashed_password_bytes = user.hashed_password.encode('utf-8')
    
    # checkpw es bloqueante, lo ejecutamos en un hilo aparte
    is_password_correct = await asyncio.to_thread(
        bcrypt.checkpw, password_bytes, hashed_password_bytes
    )

    if not is_password_correct:
        return None
        
    return user


# ... (importaciones existentes, incluyendo 'bcrypt' y 'asyncio')

async def update_user_password(db: AsyncSession, user: models.User, new_password: str):
    """Hashea y actualiza la contraseña de un usuario."""
    password_bytes = new_password.encode('utf-8')
    salt = bcrypt.gensalt()
    
    hashed_password_bytes = await asyncio.to_thread(bcrypt.hashpw, password_bytes, salt)
    hashed_password = hashed_password_bytes.decode('utf-8')
    
    user.hashed_password = hashed_password
    await db.commit()
    await db.refresh(user)
    return user


async def get_users_by_ids(db: AsyncSession, user_ids: List[int]):
    """Busca y devuelve una lista de usuarios a partir de sus IDs."""
    if not user_ids:
        return []
    result = await db.execute(select(models.User).filter(models.User.user_id.in_(user_ids)))
    return result.scalars().all()



async def search_users(db: AsyncSession, query: str, limit: int = 5):
    """Busca usuarios por username o name."""
    search_query = f"%{query}%"
    result = await db.execute(
        select(models.User)
        .filter(or_(
            models.User.username.ilike(search_query),
            models.User.name.ilike(search_query)
        ))
        .limit(limit)
    )
    return result.scalars().all()