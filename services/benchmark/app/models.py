from sqlalchemy import Column, Integer, String
from .database import Base

class SoftwareRequirement(Base):
    __tablename__ = "software_requirements"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)           # "Cyberpunk 2077", "Blender"
    scenario = Column(String(100), nullable=False)       # "1440p Ultra", "Render Cycles Monster Scene"
    type = Column(String(50), nullable=False)            # "game" | "software"

    # mínimos jugable
    min_cpu_score = Column(Integer, nullable=False)
    min_gpu_score = Column(Integer, nullable=False)

    # recomendados / high
    rec_cpu_score = Column(Integer, nullable=False)
    rec_gpu_score = Column(Integer, nullable=False)
