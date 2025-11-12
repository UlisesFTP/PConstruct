# app/crud.py
import os, httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from .models import SoftwareRequirement

BUILD_SERVICE_URL = os.getenv("BUILDS_SERVICE_URL", "http://build-service:8004")

async def get_all_software_requirements(db: AsyncSession):
    res = await db.execute(select(SoftwareRequirement))
    return list(res.scalars())

async def resolve_component_ids_from_build(build_id: str) -> list[int]:
    async with httpx.AsyncClient(timeout=5.0) as client:
        r = await client.get(f"{BUILD_SERVICE_URL}/builds/{build_id}")
        if r.status_code != 200:
            return []
        j = r.json()
        comps = j.get("components", [])
        return [c.get("component_id") for c in comps if c.get("component_id") is not None]

async def compare_builds(db: AsyncSession, build_ids: list[int], scenario: str | None):
    # por ahora: respuesta dummy comprobando existencia de cada build
    out = []
    async with httpx.AsyncClient(timeout=5.0) as client:
        for bid in build_ids:
            r = await client.get(f"{BUILD_SERVICE_URL}/builds/{bid}")
            out.append({"build_id": bid, "exists": r.status_code == 200})
    return {"scenario": scenario, "results": out}
