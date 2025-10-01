# services/users-service/app/schemas.py
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: EmailStr
    name: Optional[str] = None  # Coincide con tu esquema

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    user_id: int  # Cambió de 'id' a 'user_id'
    is_active: bool
    role: str
    country_code: Optional[str] = None
    created_at: Optional[datetime] = None
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

class PasswordResetRequest(BaseModel):
    email: EmailStr

# Respuestas estándar
class MessageResponse(BaseModel):
    message: str
    success: bool = True