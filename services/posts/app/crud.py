from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload, contains_eager
from . import models, schemas
from sqlalchemy import select, or_, delete
from typing import Optional

# --- CRUD para Publicaciones (Posts) ---

async def create_post(db: AsyncSession, post: schemas.PostCreate, user_id: int):
    """Crea una nueva publicación en la base de datos."""
    db_post = models.Post(**post.model_dump(), user_id=user_id)
    db.add(db_post)
    await db.commit()
    await db.refresh(db_post)
    return db_post


async def get_posts(db: AsyncSession, current_user_id: Optional[int] = None, skip: int = 0, limit: int = 20):
    """
    Obtiene una lista de publicaciones para el feed, incluyendo si el 
    usuario actual le ha dado like.
    """
    query = (
        select(models.Post)
        .order_by(models.Post.created_at.desc())
        .offset(skip)
        .limit(limit)
        .options(
            selectinload(models.Post.comments), # Carga comentarios
            selectinload(models.Post.likes)     # Carga TODOS los likes (necesario para el conteo)
        )
    )

    result = await db.execute(query)
    posts = result.scalars().unique().all()
    
    # Preparamos una lista para los datos finales
    post_data_list = []
    
    # Obtenemos los IDs de los posts obtenidos
    post_ids = [post.id for post in posts]

    # Hacemos una consulta separada para saber a cuáles de ESTOS posts 
    # le ha dado like el usuario actual (si hay un usuario logueado)
    user_liked_post_ids = set()
    if current_user_id is not None and post_ids:
        like_query = (
            select(models.Like.post_id)
            .where(models.Like.user_id == current_user_id)
            .where(models.Like.post_id.in_(post_ids))
        )
        like_result = await db.execute(like_query)
        user_liked_post_ids = {post_id for post_id, in like_result.all()}

    # Construimos la respuesta final
    for post in posts:
        post_data = schemas.Post.model_validate(post)
        post_data.likes_count = len(post.likes)
        # Establecemos si el usuario actual le dio like
        post_data.is_liked_by_user = post.id in user_liked_post_ids
        post_data_list.append(post_data)
        
    return post_data_list


# --- CRUD para Comentarios ---

async def create_comment(db: AsyncSession, comment: schemas.CommentCreate, post_id: int, user_id: int):
    """Añade un nuevo comentario a una publicación."""
    db_comment = models.Comment(
        **comment.model_dump(), 
        post_id=post_id, 
        user_id=user_id
    )
    db.add(db_comment)
    await db.commit()
    await db.refresh(db_comment)
    return db_comment


async def get_comments_for_post(db: AsyncSession, post_id: int):
    """Obtiene todos los comentarios de una publicación específica."""
    query = (
        select(models.Comment)
        .filter(models.Comment.post_id == post_id)
        .order_by(models.Comment.created_at.asc())
    )
    result = await db.execute(query)
    return result.scalars().all()




async def search_posts(db: AsyncSession, query: str, limit: int = 10):
    """Busca publicaciones cuyo título o contenido coincida con la consulta."""
    search_query = f"%{query}%"
    
    # Añadimos .options(selectinload(...)) para cargar las relaciones de forma proactiva
    stmt = (
        select(models.Post)
        .filter(or_(
            models.Post.title.ilike(search_query),
            models.Post.content.ilike(search_query)
        ))
        .limit(limit)
        .options(
            selectinload(models.Post.comments), # Carga eficiente de comentarios
            selectinload(models.Post.likes)     # Carga eficiente de likes
        )
    )
    result = await db.execute(stmt)
    # .unique() es importante para evitar duplicados
    return result.scalars().unique().all()


# --- Lógica para Likes ---

async def add_like_to_post(db: AsyncSession, post_id: int, user_id: int):
    """Añade un like a una publicación, si el usuario no le ha dado like antes."""
    # Primero, verifica si el like ya existe
    existing_like_query = await db.execute(
        select(models.Like).filter_by(post_id=post_id, user_id=user_id)
    )
    if existing_like_query.scalars().first():
        return None # Indica que el like ya existía

    db_like = models.Like(post_id=post_id, user_id=user_id)
    db.add(db_like)
    await db.commit()
    await db.refresh(db_like)
    return db_like


async def remove_like_from_post(db: AsyncSession, post_id: int, user_id: int):
    """Elimina un like de una publicación por parte de un usuario."""
    stmt = (
        delete(models.Like)
        .where(models.Like.post_id == post_id)
        .where(models.Like.user_id == user_id)
    )
    result = await db.execute(stmt)
    await db.commit()
    # rowcount > 0 significa que se eliminó algo (el like existía)
    return result.rowcount > 0