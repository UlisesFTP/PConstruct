# services/users-service/app/schemas.py
from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: EmailStr
    name: Optional[str] = None  # Coincide con tu esquema
    avatar_url: Optional[str] = None # <-- AÑADIR ESTA LÍNEA

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    user_id: int  # Cambió de 'id' a 'user_id'
    is_active: bool
    is_verified: bool
    role: str
    country_code: Optional[str] = None
    created_at: Optional[datetime] = None
    avatar_url: Optional[str] = None
    updated_at: Optional[datetime] = None
    last_login: Optional[datetime] = None

    class Config:
        orm_mode = True

# Esquemas para autenticación
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: str | None = None

# Esquemas para el login (compatible con el API Gateway)
class LoginRequest(BaseModel):
    username: str
    password: str

# Esquemas para verificación de email
class EmailVerificationRequest(BaseModel):
    email: EmailStr
    verification_code: str

class ResendVerificationRequest(BaseModel):
    email: EmailStr

class PasswordResetRequest(BaseModel): # <--- Tienes esta clase duplicada
    email: EmailStr

# Respuestas estándar
class MessageResponse(BaseModel):
    message: str
    success: bool = True
    
    
class PasswordResetRequest(BaseModel): # <--- Tienes esta clase duplicada
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str
    
    
class UserSummary(BaseModel):
    """Esquema reducido con la información pública del usuario."""
    user_id: int
    username: str
    avatar_url: Optional[str] = None # <-- AÑADIR ESTA LÍNEA

    class Config:
        orm_mode = True
        
        

class LoginResponse(BaseModel):
    """
    Schema para la respuesta completa del endpoint de login.
    """
    access_token: str
    token_type: str = "bearer"
    user: UserResponse  # <-- LA CLAVE: Usamos UserResponse que tiene orm_mode

    class Config:
        orm_mode = True # Aunque el principal es el de UserResponse, no hace daño