# services/builds/app/main.py
from fastapi import FastAPI, Depends, Header, HTTPException, status
from . import gemini_client
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import uuid
from contextlib import asynccontextmanager
from pydantic import BaseModel

from . import crud, models, schemas
from .database import engine, get_db, Base

# --- Evento Lifespan para crear tablas ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Al iniciar:
    async with engine.begin() as conn:
        # await conn.run_sync(Base.metadata.drop_all) # Opcional: para limpiar en dev
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Al apagar:
    await engine.dispose()

app = FastAPI(title="Builds Service (Async)", lifespan=lifespan)

# --- Endpoints Asíncronos ---

@app.post("/api/v1/builds/", response_model=schemas.BuildRead, status_code=status.HTTP_201_CREATED)
async def create_new_build(
    build: schemas.BuildCreate,
    x_user_id: str = Header(...), 
    x_user_name: str = Header(...),
    db: AsyncSession = Depends(get_db) # <-- AsyncSession
):
    if not x_user_id or not x_user_name:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User info missing from headers")
        
    return await crud.create_build(db=db, build=build, user_id=x_user_id, user_name=x_user_name)

@app.get("/api/v1/builds/my-builds", response_model=List[schemas.BuildSummary])
async def read_my_builds(
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    return await crud.get_user_builds(db=db, user_id=x_user_id)

@app.get("/api/v1/builds/community", response_model=List[schemas.BuildSummary])
async def read_community_builds(
    skip: int = 0, 
    limit: int = 20, 
    db: AsyncSession = Depends(get_db)
):
    return await crud.get_community_builds(db=db, skip=skip, limit=limit)

@app.get("/api/v1/builds/{build_id}", response_model=schemas.BuildRead)
async def read_build_detail(
    build_id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    db_build = await crud.get_build_by_id(db=db, build_id=build_id)
    if db_build is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Build not found")
    return db_build

@app.delete("/api/v1/builds/{build_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_build(
    build_id: uuid.UUID,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db)
):
    deleted_build = await crud.delete_build(db=db, build_id=build_id, user_id=x_user_id)
    if deleted_build is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Build not found or you don't have permission to delete it")
    return None # Retorna 204 No Content



@app.post("/api/v1/builds/check-compatibility", response_model=schemas.CompatibilityResponse)
async def check_build_compatibility(
    request: schemas.CompatibilityRequest
):
    """
    Verifica la compatibilidad de un conjunto de componentes usando Gemini.
    """
    # Llama a la función asíncrona que creamos en gemini_client.py
    # Pasa directamente el diccionario de componentes: request.components
    result = await gemini_client.check_compatibility(request.components)
    
    # Devuelve la respuesta JSON de Gemini (ej. {"compatible": false, "reason": "..."})
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