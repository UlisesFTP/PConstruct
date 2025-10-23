import os
import httpx
from fastapi import FastAPI, Depends, HTTPException, Header, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional

from . import crud, models, schemas
from .database import engine, get_db

app = FastAPI(title="Posts Service")

# Al arrancar la aplicación, crea las tablas en la base de datos si no existen.
@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(models.Base.metadata.create_all)

# Dependencia para obtener el User ID de la cabecera X-User-ID
def get_current_user_id(x_user_id: Optional[str] = Header(None)) -> int:
    if not x_user_id:
        raise HTTPException(status_code=401, detail="User ID not provided in headers")
    return int(x_user_id)

USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8001")

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "posts"}



@app.get("/posts/", response_model=List[schemas.Post])
async def read_posts(
    skip: int = 0, 
    limit: int = 20, 
    db: AsyncSession = Depends(get_db),
    # Hacemos que el user_id sea opcional
    user_id: Optional[int] = Depends(get_current_user_id) if True else None # Truco para hacerlo opcional
):
    """
    Obtiene posts y enriquece datos del autor. 
    Ahora también calcula si el usuario actual dio like.
    """
    # Pasamos el user_id (puede ser None si no está autenticado)
    posts_data = await crud.get_posts(db, current_user_id=user_id, skip=skip, limit=limit)
    
    # --- El enriquecimiento de datos del autor se aplica a la lista devuelta por crud.get_posts ---
    user_ids = {post.user_id for post in posts_data}
    authors_info = {}
    if user_ids:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{USER_SERVICE_URL}/users/profiles", 
                    params={"user_ids": list(user_ids)}
                )
                response.raise_for_status()
                authors_info = {user["user_id"]: user for user in response.json()}
        except Exception as e:
            print(f"Could not fetch user profiles: {e}")

    # Combina los datos del autor con los datos del post (que ya incluyen is_liked_by_user)
    for post_data in posts_data:
        author = authors_info.get(post_data.user_id)
        if author:
            post_data.author_username = author.get("username")
            post_data.author_avatar_url = author.get("avatar_url")
            
    return posts_data



@app.post("/posts/", response_model=schemas.Post)
async def create_post(
    post: schemas.PostCreate,
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Endpoint para crear una nueva publicación."""
    created_post = await crud.create_post(db=db, post=post, user_id=user_id)
    
    # Construimos manualmente la respuesta para evitar el lazy-loading
    return schemas.Post(
        id=created_post.id,
        user_id=created_post.user_id,
        title=created_post.title,
        content=created_post.content,
        image_url=created_post.image_url,
        created_at=created_post.created_at,
        comments=[],  # Un post nuevo siempre tiene 0 comentarios
        likes_count=0   # Un post nuevo siempre tiene 0 likes
    )
    
    
@app.get("/posts/search/", response_model=List[schemas.Post])
async def search_posts_endpoint(q: str, db: AsyncSession = Depends(get_db)):
    """Endpoint para buscar publicaciones."""
    posts = await crud.search_posts(db, query=q)
    
    # Construimos la respuesta manualmente para asegurar que los conteos sean correctos
    results = []
    for post in posts:
        post_data = schemas.Post.model_validate(post)
        post_data.likes_count = len(post.likes)
        # Los datos del autor no se enriquecen en la búsqueda para mantenerla rápida
        results.append(post_data)
        
    return results


@app.post("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def like_post(
    post_id: int,
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id) # Usamos la dependencia que ya tienes
):
    """
    Añade un like de un usuario a una publicación.
    La lógica de crud.py ya previene duplicados.
    """
    like = await crud.add_like_to_post(db=db, post_id=post_id, user_id=user_id)
    
    # Si el like ya existía, crud.add_like_to_post devuelve None
    # Por ahora, no implementamos "unlike", simplemente no hacemos nada si ya existe.
    # Devolvemos 204 No Content para indicar éxito sin cuerpo de respuesta.
    return


@app.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_post(
    post_id: int,
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id) 
):
    """Elimina un like de un usuario a una publicación."""
    deleted = await crud.remove_like_from_post(db=db, post_id=post_id, user_id=user_id)
    if not deleted:
        # Opcional: Si el like no existía, podrías devolver un 404,
        # pero devolver 204 (éxito sin contenido) simplifica el frontend.
        pass 
    return



@app.post("/posts/{post_id}/comments", response_model=schemas.Comment)
async def create_new_comment(
    post_id: int,
    comment: schemas.CommentCreate, # El body de la petición
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Crea un nuevo comentario en una publicación."""
    return await crud.create_comment(
        db=db, 
        comment=comment, 
        post_id=post_id, 
        user_id=user_id
    )


@app.get("/posts/{post_id}/comments", response_model=List[schemas.Comment])
async def read_comments_for_post(
    post_id: int, 
    db: AsyncSession = Depends(get_db)
):
    """Obtiene comentarios y enriquece con el nombre de usuario."""
    comments = await crud.get_comments_for_post(db=db, post_id=post_id)
    
    # --- Enriquecimiento de Datos (similar a /posts/) ---
    user_ids = {comment.user_id for comment in comments}
    authors_info = {}
    if user_ids:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{USER_SERVICE_URL}/users/profiles", # Asumiendo este endpoint existe
                    params={"user_ids": list(user_ids)}
                )
                response.raise_for_status()
                authors_info = {user["user_id"]: user for user in response.json()}
        except Exception as e:
            print(f"Could not fetch user profiles for comments: {e}")

    # Combina los datos
    results = []
    for comment in comments:
        comment_data = schemas.Comment.model_validate(comment)
        author = authors_info.get(comment.user_id)
        if author:
            comment_data.author_username = author.get("username")
        results.append(comment_data)
        
    return results