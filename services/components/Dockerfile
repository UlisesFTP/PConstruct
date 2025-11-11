# Usa una imagen base de Python
FROM python:3.10-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /code

# --- ¡INICIO DE CORRECCIÓN! ---
# Instalar Chromium y el chromedriver desde los repositorios de Debian.
# Esto es necesario para que Selenium funcione en un contenedor 'slim'.
RUN apt-get update && \
    apt-get install -y \
    chromium \
    chromium-driver \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*
# --- FIN DE CORRECCIÓN! ---

# Copia el archivo de requerimientos
COPY ./requirements.txt /code/requirements.txt

# Instala las dependencias de Python
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copia el código de la aplicación (la carpeta 'app')
COPY ./app /code/app

# (Opcional pero recomendado) Copia el script del scraper
COPY ./run_scraper.py /code/run_scraper.py

# Expone el puerto en el que correrá Uvicorn
EXPOSE 8003

# Comando para iniciar la aplicación FastAPI
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8003"]