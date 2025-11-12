# services/builds/Dockerfile

FROM python:3.11-slim

WORKDIR /code

# Instalar dependencias
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copiar la aplicación
COPY ./app /code/app

# Exponer el puerto del servicio
EXPOSE 8004

# Comando para ejecutar la aplicación
# El reload es útil para desarrollo
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8004", "--reload"]