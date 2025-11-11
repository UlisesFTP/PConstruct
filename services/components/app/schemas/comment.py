from pydantic import BaseModel
from datetime import datetime

# --- Schema Base (para el 'hijo') ---
# Info de un usuario (denormalizada)
class UserInfo(BaseModel):
    user_id: str
    user_username: str | None = None

    class Config:
        from_attributes = True

# --- Schema de Creación de Comentario ---
# Lo que la API recibe en el BODY de un POST
class CommentCreate(BaseModel):
    content: str

# --- Schema de Lectura de Comentario ---
# Lo que la API devuelve (incluye el autor)
class CommentRead(BaseModel):
    id: int
    content: str
    created_at: datetime
    user: UserInfo # Anidamos la info del usuario

    class Config:
        orm_mode = True