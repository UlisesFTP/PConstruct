from pydantic import BaseModel, constr, conint, computed_field
from datetime import datetime
from typing import List
from .comment import CommentCreate, CommentRead, UserInfo

# --- Schema de Creación de Reseña ---
# Lo que la API recibe en el BODY de un POST
# (Validado según los requerimientos)
class ReviewCreate(BaseModel):
    rating: conint(ge=1, le=5) # rating debe estar entre 1 y 5
    title: constr(max_length=255) | None = None
    content: str

# --- Schema de Lectura de Reseña ---
# Lo que la API devuelve (incluye autor y sus comentarios)
class ReviewRead(BaseModel):
    id: int
    rating: int
    title: str | None
    content: str
    created_at: datetime
   # user: UserInfo # Anidamos la info del autor
   # comments: List[CommentRead] = [] # Lista de comentarios
    comments: List[CommentRead] = []
    
    @computed_field
    @property
    def user(self, obj) -> UserInfo:
        # 'obj' es el modelo 'Review' de SQLAlchemy
        return UserInfo(
            user_id=obj.user_id,
            user_username=obj.user_username
        )

    class Config:
        from_attributes = True