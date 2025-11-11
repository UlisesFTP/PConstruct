from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from app.models.review import Review # <-- Importar Review
from app.db.session import get_db
from app.schemas.review import ReviewCreate, ReviewRead
from app.schemas.comment import CommentCreate, CommentRead
from app.crud import crud_review
# --- ¡Nuevas importaciones de caché! ---
from app.services.cache_service import invalidate_cache

router = APIRouter()






async def get_current_user_info(
    x_user_id: str = Header(..., description="ID del usuario (inyectado por API Gateway)"),
    x_user_name: str = Header(..., description="Username (inyectado por API Gateway)")
) -> dict:
    if not x_user_id or not x_user_name:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Usuario no autenticado (Falta X-User-ID o X-User-Name)")
    return {"user_id": x_user_id, "user_username": x_user_name}


@router.post(
    "/components/{component_id}/reviews",
    response_model=ReviewRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una nueva reseña"
)
async def create_new_review(
    component_id: int,
    review_in: ReviewCreate,
    db: Session = Depends(get_db),
    user_info: dict = Depends(get_current_user_info) 
):
    
    db_review = crud_review.create_review(
        db=db,
        component_id=component_id,
        review=review_in,
        user_id=user_info["user_id"],
        user_username=user_info["user_username"]
    )
    
    if db_review is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Componente no encontrado")

    # --- ¡Invalidación de Caché! ---
    # 1. Borra la caché de detalle de este componente
    await invalidate_cache(f"component_detail:{component_id}")
    # 2. Borra TODAS las cachés de listas (porque el rating promedio pudo cambiar)
    await invalidate_cache("components:*")

    return db_review


@router.post(
    "/components/{component_id}/reviews/{review_id}/comments",
    response_model=CommentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear un nuevo comentario en una reseña"
)
async def create_new_comment(
    component_id: int, # <-- Lo recibimos de la URL
    review_id: int,
    comment_in: CommentCreate,
    db: Session = Depends(get_db),
    user_info: dict = Depends(get_current_user_info)
):
    
    # (Validación opcional)
    db_review = db.query(Review).filter(Review.id == review_id, Review.component_id == component_id).first()
    if not db_review:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reseña no encontrada para este componente")

    db_comment = crud_review.create_comment(
        db=db,
        review_id=review_id,
        comment=comment_in,
        user_id=user_info["user_id"], # <-- ¡CORREGIDO!
        user_username=user_info["user_username"]
  
    )
    
    if db_comment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reseña no encontrada")

    # --- ¡Invalidación de Caché! ---
    # 1. Borra la caché de detalle de este componente
    await invalidate_cache(f"component_detail:{component_id}")
    # (No es necesario borrar 'components:*' por un comentario, pero sí por la reseña)

    return db_comment