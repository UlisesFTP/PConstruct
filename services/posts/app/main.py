import os
import httpx
import json
from fastapi import (
    FastAPI, Depends, HTTPException, Header, status,
    WebSocket, WebSocketDisconnect,Response
)
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional, Set

from . import crud, models, schemas
from .database import engine, get_db
import asyncio

app = FastAPI(title="Posts Service")

# --- Gestor de Conexiones WebSocket ---
class ConnectionManager:
    def __init__(self):
        # Mantiene un seguimiento de las conexiones activas
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        """Envía un mensaje a todas las conexiones activas."""
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception as e:
                # Opcional: manejar conexiones rotas
                print(f"Error sending message: {e}")
                # self.disconnect(connection) # Puede ser necesario

manager = ConnectionManager()
# --- Fin del Gestor de Conexiones ---


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


# --- Endpoint de WebSocket ---
@app.websocket("/ws/feed")
async def websocket_feed(websocket: WebSocket):
    """
    Endpoint de WebSocket para el feed. Solo recibe notificaciones.
    """
    await manager.connect(websocket)
    try:
        # Mantenemos la conexión viva indefinidamente.
        # El 'manager' usará esta 'websocket' para ENVIAR datos.
        # Ya no necesitamos 'recibir' nada.
        while True:
            await asyncio.sleep(3600) # Simplemente dormimos
    except (WebSocketDisconnect, asyncio.CancelledError):
        # Esta excepción se lanza cuando el cliente (el gateway) se desconecta
        manager.disconnect(websocket)
    except Exception as e:
        print(f"Error en WebSocket (service): {e}")
        manager.disconnect(websocket)
# --- Fin del Endpoint de WebSocket ---


@app.get("/posts/", response_model=List[schemas.Post])
async def read_posts(
    skip: int = 0, 
    limit: int = 20, 
    sort_by: Optional[str] = "recent", # Añadido parámetro de orden
    db: AsyncSession = Depends(get_db),
    # Hacemos que el user_id sea opcional
    user_id: Optional[int] = Depends(get_current_user_id) if True else None # Truco para hacerlo opcional
):
    """
    Obtiene posts y enriquece datos del autor. 
    Ahora también calcula si el usuario actual dio like y permite ordenar.
    """
    # Pasamos el user_id y el sort_by a la función crud
    posts_data = await crud.get_posts(
        db, 
        current_user_id=user_id, 
        sort_by=sort_by, # Pasar el parámetro
        skip=skip, 
        limit=limit
    )
    
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
    
    # --- DISPARADOR WEBSOCKET ---
    # Notifica a todos los clientes que hay un nuevo post.
    await manager.broadcast(json.dumps({
            "event": "new_post", 
            "post_id": created_post.id
        }))
    # --- Fin Disparador ---
    
    # Construimos manualmente la respuesta para evitar el lazy-loading
    return schemas.Post(
        id=created_post.id,
        user_id=created_post.user_id,
        title=created_post.title,
        content=created_post.content,
        image_url=created_post.image_url,
        created_at=created_post.created_at,
        comments=[],  # Un post nuevo siempre tiene 0 comentarios
        likes_count=0,   # Un post nuevo siempre tiene 0 likes
        is_liked_by_user=False
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
    

    return


@app.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_post(
    post_id: int,
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id) 
):
    """Elimina un like de un usuario a una publicación."""
    deleted = await crud.remove_like_from_post(db=db, post_id=post_id, user_id=user_id)

        # --- Fin Disparador ---
    return



@app.post("/posts/{post_id}/comments", response_model=schemas.Comment)
async def create_new_comment(
    post_id: int,
    comment: schemas.CommentCreate, # El body de la petición
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Crea un nuevo comentario en una publicación."""
    new_comment = await crud.create_comment(
        db=db, 
        comment=comment, 
        post_id=post_id, 
        user_id=user_id
    )
    # --- Fin Disparador ---
    
    # Enriquecemos el comentario devuelto con el nombre del autor
    # (Aunque el broadcast ya se envió, la respuesta HTTP debe ser completa)
    comment_data = schemas.Comment.model_validate(new_comment)
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{USER_SERVICE_URL}/users/profiles", 
                params={"user_ids": [user_id]}
            )
            response.raise_for_status()
            author_info = response.json()[0]
            comment_data.author_username = author_info.get("username")
    except Exception as e:
        print(f"Could not fetch user profile for new comment: {e}")
        
    return comment_data


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

@app.get("/posts/me/", response_model=List[schemas.Post])
async def read_my_posts(
    skip: int = 0, 
    limit: int = 20, 
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id) # Requiere autenticación
):
    """Obtiene solo los posts del usuario autenticado."""
    # Usamos la nueva función de crud
    posts_data = await crud.get_posts_by_user_id(db, user_id=user_id, skip=skip, limit=limit)
    
    # (El enriquecimiento de autor no es necesario,
    # pero los conteos ya vienen de la función crud)
            
    return posts_data


@app.put("/posts/{post_id}", response_model=schemas.Post)
async def update_post_endpoint(
    post_id: int,
    post_update: schemas.PostUpdate, # Schema solo con title y content
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Actualiza un post. Solo el propietario puede."""
    db_post = await crud.get_post_by_id(db, post_id=post_id)
    
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # --- Verificación de Propiedad ---
    if db_post.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this post")

    updated_post = await crud.update_post(db=db, post_id=post_id, post_update=post_update)

    # --- DISPARADOR WEBSOCKET (EDICIÓN) ---
    await manager.broadcast(json.dumps({
        "event": "post_update", 
        "action": "edit", # Acción específica de edición
        "post_id": updated_post.id
    }))
    # --- Fin Disparador ---
    
    # Devolvemos el post actualizado (cargando relaciones manualmente)
    await db.refresh(updated_post, ["comments", "likes"])
    post_data = schemas.Post.model_validate(updated_post)
    post_data.likes_count = len(updated_post.likes)
    post_data.comments_count = len(updated_post.comments)
    return post_data


# --- NUEVO ENDPOINT: DELETE /posts/{post_id} ---
@app.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_post_endpoint(
    post_id: int,
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Elimina un post. Solo el propietario puede."""
    db_post = await crud.get_post_by_id(db, post_id=post_id)
    
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
        
    # --- Verificación de Propiedad ---
    if db_post.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")

    deleted = await crud.delete_post(db=db, post_id=post_id)
    
    if deleted:
        # --- DISPARADOR WEBSOCKET (ELIMINACIÓN) ---
        await manager.broadcast(json.dumps({
            "event": "post_delete", # Evento nuevo
            "post_id": post_id
        }))
        # --- Fin Disparador ---
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    else:
        # Esto no debería pasar si la comprobación anterior funcionó
        raise HTTPException(status_code=404, detail="Post not found")