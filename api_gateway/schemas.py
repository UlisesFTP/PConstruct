# api_gateway/schemas.py

from pydantic import BaseModel
from typing import Optional

# Este es el "molde" para los datos de un nuevo post.
# Es una copia del schema que tienes en tu posts-service.
class PostCreate(BaseModel):
    title: str
    content: Optional[str] = None
    image_url: Optional[str] = None