# services/users-service/app/main.py
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
import random
import string
from sqlalchemy import text  # Añadir este import al inicio

# Importaciones corregidas (sin puntos relativos)
from . import crud, models, schemas
from .database import SessionLocal, engine

# NO crear tablas automáticamente ya que tu DB ya existe
# models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Users Service", version="0.1.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
SECRET_KEY = "a_very_secret_key_that_should_be_changed"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Simulación de almacenamiento de códigos de verificación (en producción usar Redis)
verification_codes = {}

def get_db():
    db = SessionLocal()
    try:
        # Test de conexión simple antes de usar
        db.execute(text("SELECT 1"))
        yield db
    except Exception as e:
        print(f"Database error: {e}")
        db.rollback()
        raise
    finally:
        db.close()

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def generate_verification_code():
    """Genera un código de verificación de 6 dígitos"""
    return ''.join(random.choices(string.digits, k=6))

# Health check
@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "users", "timestamp": datetime.now()}

# Endpoints de autenticación
@app.post("/auth/register", response_model=schemas.UserResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    print(f"Datos recibidos: {user.dict()}")
    # Verificar si el usuario ya existe
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # Verificar si el email ya existe
    db_email = crud.get_user_by_email(db, email=user.email)
    if db_email:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Crear usuario
    created_user = crud.create_user(db=db, user=user)
    
    # Generar código de verificación
    verification_code = generate_verification_code()
    verification_codes[user.email] = {
        'code': verification_code,
        'expires': datetime.now() + timedelta(minutes=10),
        'user_id': created_user.user_id  # Cambiado de id a user_id
    }
    
    # TODO: Enviar email con código de verificación
    print(f"Código de verificación para {user.email}: {verification_code}")
    
    return created_user

@app.post("/auth/login")
def login_user(login_data: schemas.LoginRequest, db: Session = Depends(get_db)):
    # Autenticar usuario
    user = crud.authenticate_user(db, login_data.username, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    
    # Crear token de acceso
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.user_id,  # Cambiado de id a user_id
            "username": user.username,
            "email": user.email,
            "name": user.name,  # Cambiado de first_name a name
            "role": user.role,
            "is_active": user.is_active
        }
    }

@app.post("/auth/verify-email", response_model=schemas.MessageResponse)
def verify_email(verification: schemas.EmailVerificationRequest, db: Session = Depends(get_db)):
    # Verificar si existe el código
    if verification.email not in verification_codes:
        raise HTTPException(status_code=400, detail="Verification code not found")
    
    stored_data = verification_codes[verification.email]
    
    # Verificar si el código ha expirado
    if datetime.now() > stored_data['expires']:
        del verification_codes[verification.email]
        raise HTTPException(status_code=400, detail="Verification code has expired")
    
    # Verificar si el código es correcto
    if stored_data['code'] != verification.verification_code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
    
    # Marcar usuario como verificado (necesitarías añadir is_verified a tu tabla)
    user = crud.get_user_by_email(db, verification.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Limpiar código usado
    del verification_codes[verification.email]
    
    return schemas.MessageResponse(
        message="Email verified successfully",
        success=True
    )

@app.post("/auth/resend-verification", response_model=schemas.MessageResponse)
def resend_verification_code(request: schemas.ResendVerificationRequest, db: Session = Depends(get_db)):
    # Verificar si el usuario existe
    user = crud.get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(status_code=404, detail="Email not found")
    
    # Generar nuevo código
    verification_code = generate_verification_code()
    verification_codes[request.email] = {
        'code': verification_code,
        'expires': datetime.now() + timedelta(minutes=10),
        'user_id': user.user_id  # Cambiado de id a user_id
    }
    
    # TODO: Enviar email con nuevo código
    print(f"Nuevo código de verificación para {request.email}: {verification_code}")
    
    return schemas.MessageResponse(
        message="Verification code resent successfully",
        success=True
    )

@app.post("/auth/reset-password", response_model=schemas.MessageResponse)
def request_password_reset(request: schemas.PasswordResetRequest, db: Session = Depends(get_db)):
    # Verificar si el usuario existe
    user = crud.get_user_by_email(db, request.email)
    if not user:
        # Por seguridad, no revelar si el email existe o no
        return schemas.MessageResponse(
            message="If the email exists, a password reset link has been sent",
            success=True
        )
    
    # TODO: Generar token de reset y enviar email
    print(f"Password reset requested for {request.email}")
    
    return schemas.MessageResponse(
        message="If the email exists, a password reset link has been sent",
        success=True
    )

# Endpoints de usuario
@app.get("/users/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = crud.get_user_by_id(db, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# Endpoint para obtener usuario actual (usado por el API Gateway)
@app.get("/users/me", response_model=schemas.UserResponse)
def get_current_user(user_id: str = None, db: Session = Depends(get_db)):
    # En un escenario real, esto vendría del token JWT
    # Por ahora, usamos el user_id pasado por el API Gateway
    if not user_id:
        raise HTTPException(status_code=401, detail="User ID not provided")
    
    try:
        user = crud.get_user_by_id(db, user_id=int(user_id))
        if user is None:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")