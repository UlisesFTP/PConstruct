# services/builds/app/crud.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from . import models, schemas
import uuid
from typing import List, Optional
from sqlalchemy import func, select, delete, or_
from . import gemini_client

# --- Mapeo a Summary ---
def _map_to_summary(
    build: models.Build,
    likes_count: int = 0,
    comments_count: int = 0,
    is_liked: bool = False
) -> schemas.BuildSummary:
    cpu_name = next((c.name for c in build.components if c.category == 'cpu'), None)
    gpu_name = next((c.name for c in build.components if c.category == 'gpu'), None)
    ram_name = next((c.name for c in build.components if c.category == 'ram'), None)
    
    return schemas.BuildSummary(
        id=build.id,
        name=build.name,
        image_url=build.image_url,
        user_name=build.user_name,
        total_price=build.total_price,
        created_at=build.created_at,
        is_public=build.is_public,
        cpu_name=cpu_name,
        gpu_name=gpu_name,
        ram_name=ram_name,
        likes_count=likes_count,         
        comments_count=comments_count,   
        is_liked_by_user=is_liked        
    )

# --- CRUD Builds ---

async def create_build(db: AsyncSession, build: schemas.BuildCreate, user_id: str, user_name: str) -> models.Build:
    total_price = sum(comp.price_at_build_time for comp in build.components)

    db_build = models.Build(
        name=build.name,
        description=build.description,
        use_type=build.use_type,
        image_url=build.image_url,
        is_public=build.is_public,
        total_price=total_price,
        user_id=user_id,
        user_name=user_name
    )
    
    db.add(db_build)
    await db.flush() 

    for comp in build.components:
        db_comp = models.BuildComponent(
            build_id=db_build.id,
            component_id=comp.component_id,
            category=comp.category,
            name=comp.name,
            image_url=comp.image_url,
            price_at_build_time=comp.price_at_build_time
        )
        db.add(db_comp)
    
    await db.commit() 
    await db.refresh(db_build) 
    await db.refresh(db_build, attribute_names=['components'])
    
    return db_build

async def get_build_by_id(
    db: AsyncSession, 
    build_id: uuid.UUID, 
    current_user_id: Optional[str] = None
) -> Optional[schemas.BuildRead]:
    
    likes_sq = (
        select(func.count(models.BuildLike.id))
        .where(models.BuildLike.build_id == build_id)
        .scalar_subquery()
    )
    comments_sq = (
        select(func.count(models.BuildComment.id))
        .where(models.BuildComment.build_id == build_id)
        .scalar_subquery()
    )
    query = (
        select(models.Build, likes_sq, comments_sq)
        .where(models.Build.id == build_id)
        .options(
            selectinload(models.Build.components)
        )
    )
    result = await db.execute(query)
    row = result.first()
    
    if not row:
        return None
        
    db_build, likes_count, comments_count = row
    
    is_liked = False
    if current_user_id:
        like_result = await db.execute(
            select(models.BuildLike)
            .where(
                (models.BuildLike.build_id == build_id) &
                (models.BuildLike.user_id == current_user_id)
            )
        )
        is_liked = like_result.scalars().first() is not None

    build_data = schemas.BuildRead.model_validate(db_build)
    build_data.likes_count = likes_count
    build_data.comments_count = comments_count
    build_data.is_liked_by_user = is_liked
  
    return build_data

async def get_user_builds(db: AsyncSession, user_id: str, current_user_id: Optional[str] = None) -> List[schemas.BuildSummary]:
    query = (
        select(models.Build)
        .where(models.Build.user_id == user_id)
        .order_by(models.Build.created_at.desc())
        .options(
            selectinload(models.Build.components),
            selectinload(models.Build.likes),
            selectinload(models.Build.comments)
        )
    )
    result = await db.execute(query)
    builds = result.scalars().unique().all()
    
    user_liked_build_ids = set()
    if current_user_id:
        like_query = await db.execute(
            select(models.BuildLike.build_id)
            .where(models.BuildLike.user_id == current_user_id)
            .where(models.BuildLike.build_id.in_([b.id for b in builds]))
        )
        user_liked_build_ids = {build_id for build_id, in like_query.all()}
    
    return [
        _map_to_summary(
            b,
            likes_count=len(b.likes),
            comments_count=len(b.comments),
            is_liked=(b.id in user_liked_build_ids)
        ) for b in builds
    ]

# --- AQUÍ ESTABA EL PROBLEMA DE DUPLICADOS ---
async def get_community_builds(
    db: AsyncSession, 
    skip: int = 0, 
    limit: int = 20,
    use_type: Optional[str] = None,
    cpu: Optional[str] = None,
    gpu: Optional[str] = None,
    max_price: Optional[float] = None,
    current_user_id: Optional[str] = None 
) -> List[schemas.BuildSummary]:
    
    # Subconsultas
    likes_sq = (
        select(models.BuildLike.build_id, func.count(models.BuildLike.id).label("likes_count"))
        .group_by(models.BuildLike.build_id)
        .subquery()
    )
    comments_sq = (
        select(models.BuildComment.build_id, func.count(models.BuildComment.id).label("comments_count"))
        .group_by(models.BuildComment.build_id)
        .subquery()
    )
    
    query = (
        select(
            models.Build,
            func.coalesce(likes_sq.c.likes_count, 0),
            func.coalesce(comments_sq.c.comments_count, 0)
        )
        .outerjoin(likes_sq, models.Build.id == likes_sq.c.build_id)
        .outerjoin(comments_sq, models.Build.id == comments_sq.c.build_id)
        .where(models.Build.is_public == True)
        .options(selectinload(models.Build.components)) 
    )

    # 1. Filtros Estándar
    if use_type and use_type != 'Todos':
        query = query.where(models.Build.use_type == use_type)
        
    if max_price and max_price > 0:
        query = query.where(models.Build.total_price <= max_price)

    # 2. Filtros Inteligentes (Gemini)
    if cpu or gpu:
        # Llamada a Gemini (UNA SOLA VEZ)
        search_terms = await gemini_client.normalize_search_terms(cpu, gpu)
        
        # Filtro CPU
        if search_terms.get("cpu_terms"):
            cpu_conditions = [
                models.BuildComponent.name.ilike(f"%{term}%") 
                for term in search_terms["cpu_terms"]
            ]
            query = query.where(models.Build.components.any(
                (models.BuildComponent.category == 'cpu') & 
                or_(*cpu_conditions)
            ))

        # Filtro GPU
        if search_terms.get("gpu_terms"):
            gpu_conditions = [
                models.BuildComponent.name.ilike(f"%{term}%") 
                for term in search_terms["gpu_terms"]
            ]
            query = query.where(models.Build.components.any(
                (models.BuildComponent.category == 'gpu') & 
                or_(*gpu_conditions)
            ))

    # 3. Ordenamiento y Paginación
    query = (
        query
        .order_by(models.Build.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    
    # --- Ejecución ---
    result = await db.execute(query)
    rows = result.all() 
    
    build_ids = [row[0].id for row in rows]
    user_liked_build_ids = set()
    
    if current_user_id and build_ids:
        like_query = await db.execute(
            select(models.BuildLike.build_id)
            .where(models.BuildLike.user_id == current_user_id)
            .where(models.BuildLike.build_id.in_(build_ids))
        )
        user_liked_build_ids = {build_id for build_id, in like_query.all()}

    return [
        _map_to_summary(
            build,
            likes_count=likes_count,
            comments_count=comments_count,
            is_liked=(build.id in user_liked_build_ids)
        ) for build, likes_count, comments_count in rows
    ]

async def delete_build(db: AsyncSession, build_id: uuid.UUID, user_id: str) -> Optional[models.Build]:
    build_query = await db.execute(
        select(models.Build).where(models.Build.id == build_id)
    )
    db_build = build_query.scalars().first()

    if not db_build:
        return None
    
    if db_build.user_id != user_id:
        return None 

    await db.delete(db_build)
    await db.commit()
    return db_build

# --- Likes ---
async def add_like_to_build(db: AsyncSession, build_id: uuid.UUID, user_id: str):
    existing_like = await db.execute(
        select(models.BuildLike).filter_by(build_id=build_id, user_id=user_id)
    )
    if existing_like.scalars().first():
        return None 

    db_like = models.BuildLike(build_id=build_id, user_id=user_id)
    db.add(db_like)
    await db.commit()
    await db.refresh(db_like)
    return db_like

async def remove_like_from_build(db: AsyncSession, build_id: uuid.UUID, user_id: str):
    stmt = (
        delete(models.BuildLike)
        .where(models.BuildLike.build_id == build_id)
        .where(models.BuildLike.user_id == user_id)
    )
    result = await db.execute(stmt)
    await db.commit()
    return result.rowcount > 0

# --- Comentarios ---
async def create_build_comment(db: AsyncSession, comment: schemas.BuildCommentCreate, build_id: uuid.UUID, user_id: str, user_name: str):
    db_comment = models.BuildComment(
        **comment.model_dump(), 
        build_id=build_id, 
        user_id=user_id,
        user_name=user_name
    )
    db.add(db_comment)
    await db.commit()
    await db.refresh(db_comment)
    return db_comment

async def get_comments_for_build(db: AsyncSession, build_id: uuid.UUID):
    query = (
        select(models.BuildComment)
        .filter(models.BuildComment.build_id == build_id)
        .order_by(models.BuildComment.created_at.asc())
    )
    result = await db.execute(query)
    return result.scalars().all()