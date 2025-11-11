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

# --- Schema de Lectura de Reseña (MODIFICADO) ---
class ReviewRead(BaseModel):
    id: int
    rating: int
    title: str | None
    content: str
    created_at: datetime
    comments: List[CommentRead] = [] 
    
   # --- ¡INICIO DE CORRECCIÓN! ---
    # 1. Traemos los campos de la DB
    user_id: str
    user_username: str | None

    # 2. Usamos @computed_field para crear el objeto 'user'
    @computed_field
    @property
    def user(self) -> UserInfo:
        return UserInfo(
            user_id=self.user_id,
            user_username=self.user_username
        )
    # --- FIN DE CORRECCIÓN! ---

    

    class Config:
        from_attributes = True