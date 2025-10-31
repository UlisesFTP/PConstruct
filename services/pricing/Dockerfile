# PConstruct/services/pricing/Dockerfile

# ----- Fase 1: Build con dependencias del sistema y Python -----
FROM python:3.11.5-slim as builder

WORKDIR /code

# Paso 1: Instalar herramientas base necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Paso 2: Añadir la clave de Google Chrome usando wget y apt-key
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

# Paso 3: Añadir el repositorio de Google Chrome
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Paso 4: Actualizar apt e instalar Chrome
RUN apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable \
    fonts-liberation \
    libnss3 \
    libu2f-udev \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependencias de Python
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /code/requirements.txt


# ----- Fase 2: Aplicación Final -----
FROM python:3.11.5-slim

WORKDIR /code

# Paso 1 (Final): Instalar herramientas base
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libu2f-udev \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Paso 2 (Final): Añadir la clave de Google Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

# Paso 3 (Final): Añadir el repositorio de Google Chrome
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Paso 4 (Final): Actualizar apt e instalar Chrome
RUN apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable \
    fonts-liberation \
    libnss3 \
    && rm -rf /var/lib/apt/lists/*

# Copiar dependencias de Python de la fase builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copiar el código de la aplicación
COPY ./app /code/app

# Puerto que usará el servicio
EXPOSE 8005

# Comando para iniciar
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8005"]