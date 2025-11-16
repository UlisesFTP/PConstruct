# PConstruct/services/users/app/main.py
import os
from fastapi import FastAPI, Depends, HTTPException, status, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta
from jose import jwt
import random
import string
from fastapi import Query
from typing import List

# Importaciones de tu proyecto
from . import crud, schemas, email_utils
# Importamos la nueva dependencia asíncrona desde database.py
from .database import get_db

app = FastAPI(title="Users Service", version="0.1.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Diccionario en memoria para los códigos (simple para desarrollo)
verification_codes = {}

def generate_verification_code():
    return ''.join(random.choices(string.digits, k=6))

# --- ENDPOINTS DE LA APLICACIÓN (AHORA ASÍNCRONOS) ---

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "users", "timestamp": datetime.now()}

@app.post("/auth/register", response_model=schemas.UserResponse)
async def register_user(
    user: schemas.UserCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    if await crud.get_user_by_username(db, username=user.username):
        raise HTTPException(status_code=400, detail="Username already registered")
    if await crud.get_user_by_email(db, email=user.email):
        raise HTTPException(status_code=400, detail="Email already registered")
    
    created_user = await crud.create_user(db=db, user=user)
    
    verification_code = generate_verification_code()
    verification_codes[user.email] = {
        'code': verification_code,
        'expires': datetime.now() + timedelta(minutes=10),
    }
    
    # El correo se envía en segundo plano para una respuesta instantánea
    background_tasks.add_task(
        email_utils.send_verification_email, user.email, verification_code
    )
    
    return created_user



@app.post("/auth/login" , response_model=schemas.LoginResponse)
async def login_user(login_data: schemas.LoginRequest, db: AsyncSession = Depends(get_db)):
    user = await crud.authenticate_user(db, login_data.username, login_data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Incorrect username or password")
        
    if not user.is_verified:
        raise HTTPException(status_code=403, detail="Email not verified. Please check your inbox.")
    
    # --- ASEGÚRATE DE QUE ESTAS LÍNEAS ESTÉN AQUÍ ---
    ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
    SECRET_KEY = os.getenv("SECRET_KEY", "a_very_secret_key_that_should_be_changed")
    ALGORITHM = os.getenv("ALGORITHM", "HS256")
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"sub": user.username, "exp": datetime.utcnow() + access_token_expires}
    access_token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }


@app.post("/auth/verify-email", response_model=schemas.MessageResponse)
async def verify_email(verification: schemas.EmailVerificationRequest, db: AsyncSession = Depends(get_db)):
    stored_code_info = verification_codes.get(verification.email)

    if not stored_code_info or \
       stored_code_info['code'] != verification.verification_code or \
       datetime.now() > stored_code_info['expires']:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")
    
    user = await crud.get_user_by_email(db, verification.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    await crud.verify_user_email(db=db, user=user)
    
    del verification_codes[verification.email]
    
    return schemas.MessageResponse(message="Email verified successfully")

@app.post("/auth/resend-verification", response_model=schemas.MessageResponse)
async def resend_verification_code(
    request: schemas.ResendVerificationRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    user = await crud.get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(status_code=404, detail="Email not found")
    if user.is_verified:
        return schemas.MessageResponse(message="This account is already verified.")
    
    verification_code = generate_verification_code()
    verification_codes[request.email] = {
        'code': verification_code,
        'expires': datetime.now() + timedelta(minutes=10),
    }
    
    background_tasks.add_task(
        email_utils.send_verification_email, request.email, verification_code
    )
    
    return schemas.MessageResponse(message="Verification code resent successfully")

# ... (Aquí irían tus otros endpoints, también convertidos a async si usan la DB)


# ... (importaciones existentes)

# --- NUEVAS FUNCIONES DE AYUDA PARA TOKENS DE RESETEO ---

def create_password_reset_token(email: str):
    """Crea un token JWT especial para reseteo de contraseña, válido por 1 hora."""
    expire = datetime.utcnow() + timedelta(hours=1)
    to_encode = {
        "exp": expire,
        "sub": email,
        "scope": "password_reset" # Para asegurar que el token solo sirva para esto
    }
    SECRET_KEY = os.getenv("SECRET_KEY", "a_very_secret_key")
    ALGORITHM = "HS256"
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_password_reset_token(token: str) -> str:
    """Valida el token de reseteo y devuelve el email."""
    try:
        SECRET_KEY = os.getenv("SECRET_KEY", "a_very_secret_key")
        ALGORITHM = "HS256"
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        
        if payload.get("scope") != "password_reset":
            raise HTTPException(status_code=401, detail="Invalid token scope")
            
        return payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

# --- NUEVOS ENDPOINTS ---

@app.post("/auth/request-password-reset", response_model=schemas.MessageResponse)
async def request_password_reset(
    request: schemas.PasswordResetRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    user = await crud.get_user_by_email(db, email=request.email)
    if user:
        # Generar token y enviar correo en segundo plano
        reset_token = create_password_reset_token(email=request.email)
        # DEBES crear esta nueva función en tu email_utils.py
        background_tasks.add_task(
            email_utils.send_password_reset_email,
            recipient_email=request.email,
            reset_token=reset_token
        )
    # Por seguridad, siempre devolvemos el mismo mensaje, exista o no el correo.
    return schemas.MessageResponse(message="If an account with that email exists, a password reset link has been sent.")

@app.post("/auth/reset-password", response_model=schemas.MessageResponse)
async def reset_password(
    request: schemas.PasswordResetConfirm,
    db: AsyncSession = Depends(get_db)
):
    email = decode_password_reset_token(request.token)
    if not email:
        raise HTTPException(status_code=400, detail="Invalid token")

    user = await crud.get_user_by_email(db, email=email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    await crud.update_user_password(db, user=user, new_password=request.new_password)
    
    return schemas.MessageResponse(message="Password has been reset successfully.")


@app.get("/users/profiles", response_model=List[schemas.UserSummary])
async def read_user_profiles(
    user_ids: List[int] = Query(...), 
    db: AsyncSession = Depends(get_db)
):
    """Obtiene perfiles resumidos para una lista de IDs de usuario."""
    users = await crud.get_users_by_ids(db, user_ids=user_ids)
    return users


@app.get("/users/search/", response_model=List[schemas.UserSummary])
async def search_users_endpoint(q: str, db: AsyncSession = Depends(get_db)):
    """Endpoint para buscar usuarios."""
    users = await crud.search_users(db, query=q)
    return users