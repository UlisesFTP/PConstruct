# ----- Fase 1: Base y Dependencias -----
# Usamos una imagen oficial de Python 3.11, la versión "slim" es más ligera.
FROM python:3.11.5-slim as builder

# Establecemos el directorio de trabajo dentro del contenedor.
WORKDIR /code

# Actualizamos pip e instalamos las dependencias.
# Copiamos solo requirements.txt primero para aprovechar el caché de Docker.
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r /code/requirements.txt


# ----- Fase 2: Aplicación Final -----
# Usamos la misma base para la imagen final.
FROM python:3.11.5-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Establecemos el directorio de trabajo.
WORKDIR /code

# Copiamos las dependencias Y LOS EJECUTABLES de la fase anterior.
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin 

# Copiamos el código de nuestra aplicación.
COPY ./app /code/app


# Exponemos el puerto 8001.
EXPOSE 8001

# El comando para iniciar la aplicación cuando el contenedor se ejecute.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]