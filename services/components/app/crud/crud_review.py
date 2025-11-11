from sqlalchemy.orm import Session
from app.models.review import Review
from app.models.comment import Comment
from app.models.component import Component # Para verificar que existe
from app.schemas.review import ReviewCreate
from app.schemas.comment import CommentCreate

def create_review(
    db: Session,
    component_id: int,
    review: ReviewCreate,
    user_id: str,
    user_username: str
) -> Review:
    """
    Crea una nueva reseña para un componente.
    """
    
    # Verificamos que el componente exista (opcional pero recomendado)
    db_component = db.query(Component).filter(Component.id == component_id).first()
    if not db_component:
        # En un caso real, lanzaríamos una excepción HTTP
        return None

    # Creamos el nuevo objeto Review
    db_review = Review(
        **review.dict(),
        component_id=component_id,
        user_id=user_id,
        user_username=user_username
    )
    
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    
    return db_review

def create_comment(
    db: Session,
    review_id: int,
    comment: CommentCreate,
    user_id: str,
    user_username: str
) -> Comment:
    """
    Crea un nuevo comentario para una reseña.
    """
    
    # Verificamos que la reseña exista
    db_review = db.query(Review).filter(Review.id == review_id).first()
    if not db_review:
        return None

    # Creamos el nuevo objeto Comment
    db_comment = Comment(
        **comment.dict(),
        review_id=review_id,
        user_id=user_id,
        user_username=user_username
    )
    
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)
    
    return db_comment