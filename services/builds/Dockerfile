# PConstruct/services/builds/Dockerfile

FROM python:3.11-slim


# 2. Directorio de trabajo interno del contenedor
WORKDIR /code

# 3. Copiamos primero requirements.txt para aprovechar la capa de caché
COPY requirements.txt /code/requirements.txt

# 4. Instalamos dependencias del servicio
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /code/requirements.txt

# 5. Copiamos el código del microservicio
#    En tu repo, todo lo de este servicio vive en ./app/
COPY ./app /code/app

# 6. Exponemos el puerto interno del servicio de builds
EXPOSE 8004

# 7. Comando de arranque
#    uvicorn va a levantar FastAPI en 0.0.0.0:8004
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8004", "--log-level", "info"]
