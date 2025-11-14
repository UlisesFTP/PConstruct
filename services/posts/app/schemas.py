from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import datetime

# --- Esquemas para Comentarios ---
class CommentBase(BaseModel):
    content: str

class CommentCreate(CommentBase):
    pass

class Comment(CommentBase):
    id: int
    user_id: int
    post_id: int
    created_at: datetime
    author_username: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

# --- Esquemas para Likes ---
# No necesitamos un esquema complejo para likes, solo el ID del post/usuario.

# --- Esquemas para Publicaciones (Posts) ---
class PostBase(BaseModel):
    title: str
    content: Optional[str] = None
    image_url: Optional[str] = None

class PostCreate(PostBase):
    pass

# --- AÑADE ESTA CLASE ---
# Este es el schema que faltaba, para la validación de la ACTUALIZACIÓN
class PostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
# -------------------------


# Esquema para mostrar una publicación, incluyendo comentarios y conteo de likes
class Post(PostBase):
    id: int
    user_id: int
    created_at: datetime
    comments: List['Comment'] = [] 
    likes_count: int = 0
    author_username: Optional[str] = None
    author_avatar_url: Optional[str] = None
    is_liked_by_user: bool = False
    
    # --- AÑADE ESTE CAMPO ---
    # Para que la página "Mis Posts" pueda mostrar el conteo
    comments_count: int = 0
    # -------------------------

    model_config = ConfigDict(from_attributes=True)
    
Comment.model_rebuild()