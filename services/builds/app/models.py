from sqlalchemy import Column, Integer, String, Boolean, Text, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from .database import Base

class Build(Base):
    __tablename__ = "user_builds"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=False)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    is_public = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=False), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=False), server_default=func.now(), onupdate=func.now(), nullable=False)

    components = relationship(
        "BuildComponent",
        back_populates="build",
        cascade="all, delete-orphan",
        lazy="selectin"
    )

class BuildComponent(Base):
    __tablename__ = "build_components"

    id = Column(Integer, primary_key=True, index=True)
    build_id = Column(Integer, ForeignKey("user_builds.id", ondelete="CASCADE"), nullable=False, index=True)
    slot = Column(String(50), nullable=False)
    component_id = Column(Integer, nullable=False)

    build = relationship("Build", back_populates="components")
