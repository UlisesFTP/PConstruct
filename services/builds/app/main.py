# services/builds/app/main.py
import os # 
import httpx 
from fastapi import FastAPI, Depends, Header, HTTPException, status, Query
from . import gemini_client
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import uuid
from contextlib import asynccontextmanager
from pydantic import BaseModel

from . import crud, models, schemas
from .database import engine, get_db, Base

# --- Evento Lifespan (sin cambios) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()

app = FastAPI(title="Builds Service (Async)", lifespan=lifespan)

# --- NUEVO: URL del servicio de usuarios ---
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8001")

# --- NUEVO: Dependencia de User ID Opcional ---
def get_optional_user_id(x_user_id: Optional[str] = Header(None)) -> Optional[str]:
    """Dependencia para obtener el ID de usuario opcional (para 'is_liked_by_user')."""
    return x_user_id

async def _get_author_info(user_ids: List[str]) -> dict:
    """Llama al user-service para obtener datos de perfil (username, avatar)."""
    if not user_ids:
        return {}
 
    user_ids_int = []
    for uid in user_ids:
        try:
            user_ids_int.append(int(uid))
        except (ValueError, TypeError):
            pass 
            
    if not user_ids_int:
        return {}

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{USER_SERVICE_URL}/users/profiles", 
                params={"user_ids": list(set(user_ids_int))} 
            )
            response.raise_for_status()
           
            return {
                str(user["user_id"]): user 
                for user in response.json()
            }
    except Exception as e:
        print(f"Build-service: Error al contactar user-service: {e}")
        return {}



# --- Endpoints Asíncronos ---

@app.post("/api/v1/builds/", response_model=schemas.BuildRead, status_code=status.HTTP_201_CREATED)
async def create_new_build(
    build: schemas.BuildCreate,
    x_user_id: str = Header(...), 
    x_user_name: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    db_build = await crud.create_build(db=db, build=build, user_id=x_user_id, user_name=x_user_name)
    
    # --- INICIO DE LÍNEAS A ELIMINAR ---
    # author_info = await _get_author_info([x_user_id])
    # avatar_url = author_info.get(x_user_id, {}).get("avatar_url")
    # --- FIN DE LÍNEAS A ELIMINAR ---

    build_data = schemas.BuildRead.model_validate(db_build)

    build_data.likes_count = 0 
    build_data.comments_count = 0 
    build_data.is_liked_by_user = False 
    
    # --- ELIMINA ESTA LÍNEA ---
    # build_data.user_avatar_url = avatar_url

    return build_data

@app.get("/api/v1/builds/my-builds", response_model=List[schemas.BuildSummary])
async def read_my_builds(
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    # Pasamos el user_id dos veces: 1. para el filtro, 2. para el 'is_liked'
    return await crud.get_user_builds(db=db, user_id=x_user_id, current_user_id=x_user_id)

@app.get("/api/v1/builds/community", response_model=List[schemas.BuildSummary])
async def read_community_builds(
    skip: int = 0, 
    limit: int = 20, 
    db: AsyncSession = Depends(get_db),
    use_type: Optional[str] = Query(None),
    cpu: Optional[str] = Query(None),
    gpu: Optional[str] = Query(None),
    max_price: Optional[float] = Query(None),
    current_user_id: Optional[str] = Depends(get_optional_user_id) # <-- MODIFICADO
):
    return await crud.get_community_builds(
        db=db, 
        skip=skip, 
        limit=limit,
        use_type=use_type,
        cpu=cpu,
        gpu=gpu,
        max_price=max_price,
        current_user_id=current_user_id # <-- MODIFICADO
    )

@app.get("/api/v1/builds/{build_id}", response_model=schemas.BuildRead)
async def read_build_detail(
    build_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[str] = Depends(get_optional_user_id) # <-- MODIFICADO
):
    db_build = await crud.get_build_by_id(db=db, build_id=build_id, current_user_id=current_user_id)
    if db_build is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Build not found")
    
    # --- LÓGICA AÑADIDA ---
    # db_build ya es un schema BuildRead, y tiene el user_id
    author_info = await _get_author_info([db_build.user_id])
    avatar_url = author_info.get(db_build.user_id, {}).get("avatar_url")
    db_build.user_avatar_url = avatar_url
    # --- FIN DE LÓGICA AÑADIDA ---
    
    return db_build # <-- db_build ya es un schema BuildRead
@app.delete("/api/v1/builds/{build_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_build(
    build_id: uuid.UUID,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    deleted_build = await crud.delete_build(db=db, build_id=build_id, user_id=x_user_id)
    if deleted_build is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Build not found or you don't have permission to delete it")
    return None

# --- NUEVO: Endpoints de Likes ---
@app.post("/api/v1/builds/{build_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def like_build(
    build_id: uuid.UUID,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    await crud.add_like_to_build(db=db, build_id=build_id, user_id=x_user_id)
    return None

@app.delete("/api/v1/builds/{build_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_build(
    build_id: uuid.UUID,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    await crud.remove_like_from_build(db=db, build_id=build_id, user_id=x_user_id)
    return None

# --- NUEVO: Endpoints de Comentarios ---
@app.post("/api/v1/builds/{build_id}/comments", response_model=schemas.BuildCommentRead, status_code=status.HTTP_201_CREATED)
async def create_new_build_comment(
    build_id: uuid.UUID,
    comment: schemas.BuildCommentCreate,
    x_user_id: str = Header(...),
    x_user_name: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    # Nota: Usamos x_user_name directamente.
    # Para obtener el avatar, necesitaríamos llamar a /users/profiles
    new_comment = await crud.create_build_comment(
        db=db, 
        comment=comment, 
        build_id=build_id, 
        user_id=x_user_id,
        user_name=x_user_name
    )
    return new_comment

@app.get("/api/v1/builds/{build_id}/comments", response_model=List[schemas.BuildCommentRead])
async def read_comments_for_build(
    build_id: uuid.UUID, 
    db: AsyncSession = Depends(get_db)
):
    # (Por ahora, no enriquecemos con avatars, solo con el user_name guardado)
    comments = await crud.get_comments_for_build(db=db, build_id=build_id)
    return comments

# --- Endpoints de Gemini (sin cambios) ---
@app.post("/api/v1/builds/check-compatibility", response_model=schemas.CompatibilityResponse)
async def check_build_compatibility(
    request: schemas.CompatibilityRequest
):
    result = await gemini_client.check_compatibility(request.components)
    return result

class ChatTurn(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    history: List[ChatTurn] = []
    message: str

class ChatResponse(BaseModel):
    message: str

@app.post("/api/v1/builds/chat", response_model=ChatResponse)
async def builds_chat(req: ChatRequest):
    reply = await gemini_client.chat_reply([t.model_dump() for t in req.history], req.message)
    print(f"[builds_chat] reply[:160] = {repr(reply[:160])}")
    return ChatResponse(message=reply)