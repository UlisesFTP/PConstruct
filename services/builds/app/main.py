from fastapi import FastAPI, Depends, HTTPException, status, Request, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import logging

from .database import get_db, init_db
from . import crud, schemas, models

logger = logging.getLogger("build-service")
logging.basicConfig(level=logging.INFO)


app = FastAPI(
    title="Build Service",
    description="Servicio para crear y consultar builds de PC de usuarios y de la comunidad",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # en prod puedes cerrar esto
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def on_startup():
    await init_db()
    logger.info("Build service inicializado y tablas aseguradas")


def build_to_summary(b: models.Build) -> schemas.BuildSummary:
    return schemas.BuildSummary(
        id=b.id,
        user_id=b.user_id,
        name=b.name,
        description=b.description,
        is_public=b.is_public,
        created_at=b.created_at,
        updated_at=b.updated_at,
    )


def build_to_detail(b: models.Build) -> schemas.BuildDetail:
    return schemas.BuildDetail(
        id=b.id,
        user_id=b.user_id,
        name=b.name,
        description=b.description,
        is_public=b.is_public,
        created_at=b.created_at,
        updated_at=b.updated_at,
        components=[
            schemas.BuildComponentOut(
                id=c.id,
                slot=c.slot,
                component_id=c.component_id,
            )
            for c in (b.components or [])
        ],
    )


def get_user_id_from_request(request: Request) -> int:
    raw = request.headers.get("X-User-Id")
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falta el header X-User-Id",
        )
    try:
        return int(raw)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Header X-User-Id inválido",
        )


@app.get(
    "/builds/community",
    response_model=List[schemas.BuildSummary],
    status_code=status.HTTP_200_OK,
)
async def get_community_builds_endpoint(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    builds = await crud.get_community_builds(db, skip=skip, limit=limit)
    return [build_to_summary(b) for b in builds]


@app.get("/health")
async def healthcheck():
    return {"status": "ok", "service": "build-service"}




@app.get(
    "/builds/mine",
    response_model=List[schemas.BuildSummary],
    status_code=status.HTTP_200_OK,
)
async def get_my_builds_endpoint(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    user_id = get_user_id_from_request(request)

    builds = await crud.get_builds_by_user(db, user_id=user_id)
    return [build_to_summary(b) for b in builds]


@app.post(
    "/builds/",
    response_model=schemas.BuildDetail,
    status_code=status.HTTP_201_CREATED,
)
async def create_build_endpoint(
    build_in: schemas.BuildCreate,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    user_id = get_user_id_from_request(request)

    new_build = await crud.create_build(db, user_id=user_id, build_in=build_in)
    if not new_build:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No se pudo crear la build",
        )

    return build_to_detail(new_build)



@app.get(
    "/builds/{build_id}",
    response_model=schemas.BuildDetail,
    status_code=status.HTTP_200_OK,
)
async def get_build_detail_endpoint(
    build_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    build_obj = await crud.get_build_by_id(db, build_id)
    if not build_obj:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Build no encontrada",
        )

    requester_id: Optional[int] = None
    raw_header = request.headers.get("X-User-Id")
    if raw_header:
        try:
            requester_id = int(raw_header)
        except ValueError:
            requester_id = None

    if not build_obj.is_public:
        if requester_id is None or requester_id != build_obj.user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes acceso a esta build",
            )

    return build_to_detail(build_obj)

