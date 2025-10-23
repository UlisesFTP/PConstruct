# ----- Fase 1: Instalación de dependencias -----
FROM python:3.11.5-slim as builder

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r /code/requirements.txt


# ----- Fase 2: Aplicación Final -----
FROM python:3.11.5-slim

# Instala certificados de confianza (importante para cualquier conexión SSL/TLS)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /code

# Copia las dependencias instaladas de la fase anterior
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copia el código de la aplicación
COPY ./app /code/app

# Expone el puerto que usará este servicio (ej. 8002)
EXPOSE 8002

# Comando para iniciar la aplicación
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]