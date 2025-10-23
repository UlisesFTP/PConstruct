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
    
    # Relaciones
    likes = relationship("Like", back_populates="post", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")

class Like(Base):
    __tablename__ = "likes"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False)

    post = relationship("Post", back_populates="likes")

    # Un usuario solo puede dar like una vez a una publicación
    __table_args__ = (UniqueConstraint('user_id', 'post_id', name='_user_post_uc'),)

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    post = relationship("Post", back_populates="comments")