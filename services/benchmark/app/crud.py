from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from . import models

async def get_all_software_requirements(db: AsyncSession):
    stmt = select(models.SoftwareRequirement)
    res = await db.execute(stmt)
    return res.scalars().all()
