from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from . import models, schemas

async def create_build(db: AsyncSession, user_id: int, build_in: schemas.BuildCreate) -> models.Build:
    build = models.Build(
        user_id=user_id,
        name=build_in.name,
        description=build_in.description,
        is_public=build_in.is_public,
    )
    db.add(build)
    await db.flush()

    for comp in build_in.components:
        db.add(
            models.BuildComponent(
                build_id=build.id,
                slot=comp.slot,
                component_id=comp.component_id,
            )
        )

    await db.commit()

    query = (
        select(models.Build)
        .options(selectinload(models.Build.components))
        .where(models.Build.id == build.id)
    )
    result = await db.execute(query)
    created_build = result.scalars().first()
    return created_build

async def get_build_by_id(db: AsyncSession, build_id: int) -> Optional[models.Build]:
    query = (
        select(models.Build)
        .options(selectinload(models.Build.components))
        .where(models.Build.id == build_id)
    )
    result = await db.execute(query)
    return result.scalars().first()

async def get_builds_by_user(db: AsyncSession, user_id: int) -> List[models.Build]:
    query = (
        select(models.Build)
        .where(models.Build.user_id == user_id)
        .order_by(models.Build.created_at.desc())
    )
    result = await db.execute(query)
    return list(result.scalars().all())

async def get_community_builds(
    db: AsyncSession,
    skip: int = 0,
    limit: int = 20,
) -> List[models.Build]:
    query = (
        select(models.Build)
        .where(models.Build.is_public.is_(True))
        .order_by(models.Build.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    result = await db.execute(query)
    return list(result.scalars().all())
