# api_gateway/jwt_utils.py

import os
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from typing import Dict, Optional
from dotenv import load_dotenv
from pathlib import Path

# Carga las variables de entorno del archivo .env en la carpeta infra/docker
env_path = Path(__file__).parent.parent / 'infra' / 'docker' / '.env'
load_dotenv(dotenv_path=env_path)

# --- CONFIGURACIÓN DE JWT ---
SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

# Si no tienes una clave secreta, la aplicación no funcionará correctamente.
# ¡Asegúrate de haberla añadido a tu archivo .env!
if SECRET_KEY is None:
    raise ValueError("No se encontró la variable de entorno JWT_SECRET")

# Esta es la URL a la que el cliente (frontend) debe ir para obtener el token.
# En nuestro caso, es el endpoint de login en el propio gateway.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def verify_token(token: str = Depends(oauth2_scheme)) -> Dict[str, any]:
    """
    Decodifica y valida un token JWT.
    
    Esta función se usa como una dependencia en los endpoints protegidos.
    Si el token es inválido o ha expirado, lanza una excepción HTTP 401.
    Si es válido, devuelve el payload (los datos dentro del token).
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        
        # 'sub' es el campo estándar en JWT para el "subject" (sujeto),
        # que en nuestro caso es el ID del usuario.
        user_id: Optional[str] = payload.get("sub")
        if user_id is None:
            raise credentials_exception
            
        return payload
        
    except JWTError:
        raise credentials_exception