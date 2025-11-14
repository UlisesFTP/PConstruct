from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, delete, desc, func # <-- LÍNEA CORREGIDA
from sqlalchemy.orm import selectinload, contains_eager
from sqlalchemy.sql.expression import extract
from . import models, schemas
from typing import Optional
from datetime import datetime, timedelta
from sqlalchemy import update, delete

# --- CRUD para Publicaciones (Posts) ---

async def create_post(db: AsyncSession, post: schemas.PostCreate, user_id: int):
    """Crea una nueva publicación en la base de datos."""
    db_post = models.Post(**post.model_dump(), user_id=user_id)
    db.add(db_post)
    await db.commit()
    await db.refresh(db_post)
    return db_post


async def get_posts(
    db: AsyncSession, 
    current_user_id: Optional[int] = None, 
    sort_by: str = "recent", # Nuevo parámetro para ordenar
    skip: int = 0, 
    limit: int = 20
):
    """
    Obtiene una lista de publicaciones para el feed, incluyendo si el 
    usuario actual le ha dado like, y con ordenamiento dinámico.
    sort_by: "recent" (default) o "popular".
    """
    
    # Query base con carga eficiente de relaciones
    query = (
        select(models.Post)
        .options(
            selectinload(models.Post.comments), # Carga comentarios
            selectinload(models.Post.likes)     # Carga TODOS los likes
        )
    )

    if sort_by == "popular":
        # --- Algoritmo de Ranking Ponderado (Hot Ranking) ---
        # Usamos 'epoch' (segundos desde 1970) para calcular la antigüedad
        age_in_seconds = func.greatest(1.0, extract('epoch', func.now() - models.Post.created_at))
        age_in_hours = age_in_seconds / 3600.0
        
        # Subqueries para contar likes y comentarios eficientemente
        like_count_sq = (
            select(models.Like.post_id, func.count(models.Like.id).label("like_count"))
            .group_by(models.Like.post_id)
            .subquery()
        )
        comment_count_sq = (
            select(models.Comment.post_id, func.count(models.Comment.id).label("comment_count"))
            .group_by(models.Comment.post_id)
            .subquery()
        )
        
        # Unimos la query principal con los conteos
        query = query.outerjoin(like_count_sq, models.Post.id == like_count_sq.c.post_id) \
                   .outerjoin(comment_count_sq, models.Post.id == comment_count_sq.c.post_id)
                   
        likes = func.coalesce(like_count_sq.c.like_count, 0)
        # Damos un poco más de peso a los comentarios
        comments = func.coalesce(comment_count_sq.c.comment_count, 0) * 1.5 
        
        interaction_score = (likes + comments)
        
        # Fórmula "Hot": Puntuación / (Antigüedad + Offset)^Gravedad
        # Offset (2) previene que posts muy nuevos dominen
        # Gravedad (1.8) es un estándar común
        score = interaction_score / func.pow((age_in_hours + 2), 1.8)
        
        # Opcional: solo rankear posts de los últimos 7 días
        query = query.filter(models.Post.created_at >= (datetime.now() - timedelta(days=7)))
        
        query = query.order_by(desc(score))
        # --- Fin del Algoritmo de Ranking ---

    else: # "recent" o por defecto
        query = query.order_by(models.Post.created_at.desc())

    # Aplicar paginación
    query = query.offset(skip).limit(limit)

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




# --- NUEVA FUNCIÓN: Obtener posts por user_id ---
async def get_posts_by_user_id(db: AsyncSession, user_id: int, skip: int = 0, limit: int = 20):
    """Obtiene todos los posts de un usuario específico."""
    query = (
        select(models.Post)
        .filter(models.Post.user_id == user_id)
        .order_by(models.Post.created_at.desc())
        .offset(skip)
        .limit(limit)
        .options(
            selectinload(models.Post.comments),
            selectinload(models.Post.likes)
        )
    )
    result = await db.execute(query)
    posts = result.scalars().unique().all()
    
    # Construimos la respuesta
    post_data_list = []
    for post in posts:
        post_data = schemas.Post.model_validate(post)
        post_data.likes_count = len(post.likes)
        # Para "Mis Posts", no necesitamos 'is_liked_by_user'
        # pero sí podríamos querer el conteo de comentarios
        post_data.comments_count = len(post.comments) # <-- Asumiremos que añades esto al schema
        post_data_list.append(post_data)
        
    return post_data_list

# --- NUEVA FUNCIÓN: Obtener un post (para verificar propiedad) ---
async def get_post_by_id(db: AsyncSession, post_id: int):
    """Obtiene un post simple por ID."""
    query = select(models.Post).filter(models.Post.id == post_id)
    result = await db.execute(query)
    return result.scalars().first()

# --- NUEVA FUNCIÓN: Actualizar un post ---
async def update_post(db: AsyncSession, post_id: int, post_update: schemas.PostUpdate):
    """Actualiza el título y contenido de un post."""
    stmt = (
        update(models.Post)
        .where(models.Post.id == post_id)
        .values(**post_update.model_dump(exclude_unset=True))
        .returning(models.Post) # Devuelve el post actualizado
    )
    result = await db.execute(stmt)
    await db.commit()
    return result.scalars().first()


# --- NUEVA FUNCIÓN: Eliminar un post ---
async def delete_post(db: AsyncSession, post_id: int):
    """Elimina un post por ID."""
    stmt = delete(models.Post).where(models.Post.id == post_id)
    result = await db.execute(stmt)
    await db.commit()
    return result.rowcount > 0 # Devuelve True si se eliminó algo