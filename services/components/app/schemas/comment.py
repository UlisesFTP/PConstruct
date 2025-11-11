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
    # user: UserInfo # <-- Quitamos esto

    # --- ¡INICIO DE CORRECCIÓN! ---
    user_id: str
    user_username: str | None

    @property
    def user(self) -> UserInfo:
        return UserInfo(
            user_id=self.user_id,
            user_username=self.user_username
        )

    class Config:
        orm_mode = True