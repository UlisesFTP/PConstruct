# app/crud.py
from sqlalchemy import select
import os
import httpx
from .models import SoftwareRequirement

BUILD_SERVICE_URL = os.getenv("BUILDS_SERVICE_URL", "http://build-service:8004")

async def get_all_software_requirements(db):
    stmt = select(SoftwareRequirement)
    res = await db.execute(stmt)
    return res.scalars().all()

async def resolve_component_ids_from_build(build_id: int) -> list[int]:
    async with httpx.AsyncClient(timeout=10.0) as client:
        r = await client.get(f"{BUILD_SERVICE_URL}/builds/{build_id}")
        r.raise_for_status()
        data = r.json()
    comps = data.get("components", []) or []
    return [c["component_id"] for c in comps if "component_id" in c]
