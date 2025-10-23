import os
import smtplib
from email.message import EmailMessage
from email.mime.image import MIMEImage
from pathlib import Path

def send_verification_email(recipient_email: str, verification_code: str) -> bool:
    EMAIL_ADDRESS = os.getenv('SMTP_USERNAME')
    EMAIL_PASSWORD = os.getenv('SMTP_APP_PASSWORD')
    SMTP_SERVER = os.getenv('SMTP_SERVER')
    SMTP_PORT = int(os.getenv('SMTP_PORT', 465))

    if not all([EMAIL_ADDRESS, EMAIL_PASSWORD, SMTP_SERVER]):
        print("!!! ERROR: Faltan variables de entorno para el envío de correos.")
        return False

    try:
        template_path = Path(__file__).parent / 'templates' / 'verification_email.html'
        with open(template_path, 'r', encoding='utf-8') as f:
            html_content = f.read()
        html_content = html_content.replace('{CODE}', verification_code)
    except FileNotFoundError:
        print(f"!!! ERROR: No se encontró la plantilla de correo en {template_path}.")
        return False

    msg = EmailMessage()
    msg['Subject'] = 'Tu Código de Verificación para PConstruct'
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = recipient_email
    msg.add_alternative(html_content, subtype='html')

    logo_path = 'app/assets/img/logo.png'
    try:
        # Usamos Path() para construir la ruta desde la raíz del WORKDIR
        full_logo_path = Path.cwd() / logo_path
        with open(full_logo_path, 'rb') as img_file:
            logo_img = MIMEImage(img_file.read())
            logo_img.add_header('Content-ID', '<logo>')
            msg.attach(logo_img)
    except FileNotFoundError:
        print(f"!!! ADVERTENCIA: No se encontró el logo en la ruta '{full_logo_path}'.")

    try:
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT, timeout=10) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.send_message(msg)
            print(f"Correo de verificación enviado exitosamente a {recipient_email}")
            return True
    except Exception as e:
        print(f"!!! ERROR AL ENVIAR CORREO: {e}")
        return False
    
    
def send_password_reset_email(recipient_email: str, reset_token: str) -> bool:
    """Envía un correo de reseteo de contraseña con un enlace."""
    EMAIL_ADDRESS = os.getenv('SMTP_USERNAME')
    EMAIL_PASSWORD = os.getenv('SMTP_APP_PASSWORD')
    SMTP_SERVER = os.getenv('SMTP_SERVER')
    SMTP_PORT = int(os.getenv('SMTP_PORT', 465))
    FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000') # URL de tu app Flutter

    if not all([EMAIL_ADDRESS, EMAIL_PASSWORD, SMTP_SERVER]):
        print("!!! ERROR: Faltan variables de entorno para el envío de correos.")
        return False

    # Construir el enlace completo de reseteo
    reset_link = f"{FRONTEND_URL}/reset-password?token={reset_token}"

    try:
        template_path = Path(__file__).parent / 'templates' / 'password_reset_email.html'
        with open(template_path, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        html_content = html_content.replace('{RESET_LINK}', reset_link)
    except FileNotFoundError:
        print(f"!!! ERROR: No se encontró la plantilla de correo en {template_path}.")
        return False

    msg = EmailMessage()
    msg['Subject'] = 'Restablece tu Contraseña de PConstruct'
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = recipient_email
    msg.add_alternative(html_content, subtype='html')

    logo_path = 'app/assets/img/logo.png'
    try:
        full_logo_path = Path.cwd() / logo_path
        with open(full_logo_path, 'rb') as img_file:
            logo_img = MIMEImage(img_file.read())
            logo_img.add_header('Content-ID', '<logo>')
            msg.attach(logo_img)
    except FileNotFoundError:
        print(f"!!! ADVERTENCIA: No se encontró el logo en la ruta '{full_logo_path}'.")

    try:
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT, timeout=10) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.send_message(msg)
            print(f"Correo de reseteo enviado exitosamente a {recipient_email}")
            return True
    except Exception as e:
        print(f"!!! ERROR AL ENVIAR CORREO: {e}")
        return False