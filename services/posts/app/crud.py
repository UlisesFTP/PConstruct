from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, delete, desc, func , case
from sqlalchemy.orm import selectinload, contains_eager
from sqlalchemy.sql.expression import extract
from . import models, schemas
from typing import Optional
from datetime import datetime, timedelta
from sqlalchemy import update, delete
import random

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
    sort_by: str = "recent", 
    skip: int = 0, 
    limit: int = 20,
    seed: int = 0 
):
    """
    Obtiene publicaciones con algoritmo de "Ranking Ponderado + Aleatoriedad".
    """
    
    # --- 1. DEFINICIÓN INICIAL DE LA QUERY (ESTO FALTABA) ---
    query = (
        select(models.Post)
        .options(
            selectinload(models.Post.comments), 
            selectinload(models.Post.likes)
        )
    )
    # --------------------------------------------------------

    if sort_by == "popular":
        # Calcular Antigüedad
        age_in_seconds = extract('epoch', func.now() - models.Post.created_at)
        age_in_hours = age_in_seconds / 3600.0
        
        # Subqueries para conteos
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
        
        # Unir con subqueries
        query = query.outerjoin(like_count_sq, models.Post.id == like_count_sq.c.post_id) \
                   .outerjoin(comment_count_sq, models.Post.id == comment_count_sq.c.post_id)
        
        # Factores de puntuación
        likes = func.coalesce(like_count_sq.c.like_count, 0)
        comments = func.coalesce(comment_count_sq.c.comment_count, 0) * 2.0
        
        # Impulso de frescura (< 6 horas)
        freshness_boost = case(
            (age_in_hours < 6.0, 10.0),
            else_=0.0
        )
        
        base_score = likes + comments + freshness_boost + 1.0
        
        # Gravedad
        gravity = 1.8
        time_decay = func.pow((age_in_hours + 2.0), gravity)
        
        hot_score = base_score / time_decay
        
        # Factor de Aleatoriedad (Jitter) basado en SEED
        if seed and seed > 0:
            # Usamos el seed para que el orden sea determinista por sesión
            # (models.Post.id * seed) % 100 genera un número pseudo-aleatorio fijo para ese post+sesión
            pseudo_random = func.abs((models.Post.id * seed) % 100) / 100.0
            random_factor = 0.8 + (pseudo_random * 0.4) 
        else:
            # Fallback totalmente aleatorio (PostgreSQL/SQLite random function)
            random_factor = 0.8 + (func.random() * 0.4)
        
        final_rank = hot_score * random_factor
        
        query = query.order_by(desc(final_rank))

    else: # Orden por defecto: Reciente
        query = query.order_by(models.Post.created_at.desc())

    # Paginación
    query = query.offset(skip).limit(limit)

    # Ejecución
    result = await db.execute(query)
    posts = result.scalars().unique().all()
    
    # Procesamiento de likes del usuario actual
    post_data_list = []
    post_ids = [post.id for post in posts]

    user_liked_post_ids = set()
    if current_user_id is not None and post_ids:
        like_query = (
            select(models.Like.post_id)
            .where(models.Like.user_id == current_user_id)
            .where(models.Like.post_id.in_(post_ids))
        )
        like_result = await db.execute(like_query)
        user_liked_post_ids = {post_id for post_id, in like_result.all()}

    # Mapeo a Schema
    for post in posts:
        post_data = schemas.Post.model_validate(post)
        post_data.likes_count = len(post.likes)
        post_data.is_liked_by_user = post.id in user_liked_post_ids
        # Aseguramos compatibilidad si agregaste comments_count al schema
        # post_data.comments_count = len(post.comments) 
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