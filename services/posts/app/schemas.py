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

# Esquema para mostrar una publicación, incluyendo comentarios y conteo de likes
class Post(PostBase):
    id: int
    user_id: int
    created_at: datetime
    comments: List['Comment'] = [] 
    likes_count: int = 0
    author_username: Optional[str] = None
    author_avatar_url: Optional[str] = None
    
    # --- AÑADE ESTE CAMPO ---
    is_liked_by_user: bool = False # Por defecto es False
    # -------------------------

    model_config = ConfigDict(from_attributes=True)
    
Comment.model_rebuild()