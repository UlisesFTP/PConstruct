from sqlalchemy import (
    Column, Integer, String, Text, DateTime, ForeignKey, 
    UniqueConstraint
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base # Asumiremos que database.py será similar al del user-service

class Post(Base):
    __tablename__ = "posts"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, index=True, nullable=False) # ID del usuario que publica
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=True)
    image_url = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # --- INICIO DE LA CORRECCIÓN ---
    # Añadimos 'cascade="all, delete-orphan"' para que al borrar un Post,
    # se borren sus 'likes' y 'comments' automáticamente.
    likes = relationship(
        "Like", 
        back_populates="post", 
        cascade="all, delete-orphan" # <-- AÑADIR ESTO
    )
    comments = relationship(
        "Comment", 
        back_populates="post", 
        cascade="all, delete-orphan" # <-- AÑADIR ESTO
    )
    # --- FIN DE LA CORRECCIÓN ---

class Like(Base):
    __tablename__ = "likes"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    # --- INICIO DE LA CORRECCIÓN ---
    # Asegúrate de que ForeignKey apunte a "posts.id"
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False) 
    # --- FIN DE LA CORRECCIÓN ---

    post = relationship("Post", back_populates="likes")

    # Un usuario solo puede dar like una vez a una publicación
    __table_args__ = (UniqueConstraint('user_id', 'post_id', name='_user_post_uc'),)

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    # --- INICIO DE LA CORRECCIÓN ---
    # Asegúrate de que ForeignKey apunte a "posts.id"
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False)
    # --- FIN DE LA CORRECCIÓN ---
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    post = relationship("Post", back_populates="comments")