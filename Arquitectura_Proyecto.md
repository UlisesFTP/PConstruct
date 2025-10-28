# Documentación de Arquitectura: PConstruct

Este documento detalla la arquitectura de microservicios del proyecto PConstruct, la configuración del entorno, y las instrucciones para levantar el sistema con Docker.

## 1. Arquitectura General

El proyecto sigue una arquitectura de microservicios, donde cada servicio es responsable de una funcionalidad de negocio específica. Una API Gateway actúa como punto de entrada único para todas las solicitudes de los clientes, enrutándolas al servicio correspondiente. Esta arquitectura permite un desarrollo, despliegue y escalado independiente de cada componente.

El frontend es una aplicación móvil desarrollada en Flutter, que se comunica con los microservicios a través de la API Gateway.

## 2. Diagrama de Estructura de Carpetas

A continuación se muestra la estructura del backend y los servicios del proyecto:

```
.
├───.gitignore
├───.git/...
├───.venv/
│   ├───Include/...
│   ├───Lib/...
│   └───Scripts/...
├───.vscode/
├───api_gateway/
│   ├───Dockerfile
│   ├───jwt_utils.py
│   ├───main.py
│   ├───requirements.txt
│   ├───schemas.py
│   └───venv/
│       ├───Include/...
│       ├───Lib/...
│       └───Scripts/...
├───infra/
│   └───docker/
│       └───docker-compose.dev.yml
├───scripts/
├───services/
│   ├───benchmark/
│   │   └───app/
│   │       ├───config.py
│   │       ├───crud.py
│   │       ├───main.py
│   │       ├───models.py
│   │       ├───schemas.py
│   │       └───estimators/
│   ├───builds/
│   │   └───app/
│   │       ├───config.py
│   │       ├───crud.py
│   │       ├───dependencies.py
│   │       ├───main.py
│   │       ├───models.py
│   │       ├───schemas.py
│   │       └───algorithm/
│   ├───components/
│   │   ├───requirements.txt
│   │   └───app/
│   │       ├───compatibility.py
│   │       ├───crud.py
│   │       ├───database.py
│   │       ├───main.py
│   │       ├───models.py
│   │       └───schemas.py
│   ├───posts/
│   │   ├───Dockerfile
│   │   ├───requirements.txt
│   │   ├───app/
│   │   │   ├───crud.py
│   │   │   ├───database.py
│   │   │   ├───main.py
│   │   │   ├───models.py
│   │   │   └───schemas.py
│   │   └───venv/
│   │       ├───Include/...
│   │       ├───Lib/...
│   │       └───Scripts/...
│   ├───pricing/
│   │   ├───dsfs.txt
│   │   ├───requirements.txt
│   │   └───app/
│   │       ├───base_scraper.py
│   │       ├───config.py
│   │       ├───crud.py
│   │       ├───main.py
│   │       ├───models.py
│   │       └───queues.py
│   └───users/
│       ├───Dockerfile
│       ├───requirements.txt
│       ├───.venv/
│       │   ├───Include/...
│       │   ├───Lib/...
│       │   └───Scripts/...
│       └───app/
│           ├───crud.py
│           ├───database.py
│           ├───email_utils.py
│           ├───main.py
│           ├───models.py
│           ├───schemas.py
│           ├───test_connection.py
│           ├───__pycache__/
│           ├───assets/
│           └───templates/
└───shared/
```

## 3. Microservicios y Componentes

### 3.1. API Gateway (`api_gateway`)

-   **Función:** Punto de entrada único para todas las solicitudes del cliente. Se encarga de enrutar las peticiones a los microservicios correspondientes. También maneja la validación de tokens JWT para securizar las rutas.
-   **Tecnología:** Python, FastAPI.

### 3.2. Servicio de Usuarios (`services/users`)

-   **Función:** Gestiona todo lo relacionado con los usuarios: registro, inicio de sesión, perfiles de usuario y envío de correos electrónicos (por ejemplo, para verificación de cuenta).
-   **Tecnología:** Python, FastAPI, SQLAlchemy.
-   **Dockerizado:** Sí.

### 3.3. Servicio de Publicaciones (`services/posts`)

-   **Función:** Maneja la creación, lectura, actualización y eliminación de publicaciones o posts en la plataforma.
-   **Tecnología:** Python, FastAPI, SQLAlchemy.
-   **Dockerizado:** Sí.

### 3.4. Otros Servicios (No orquestados en `docker-compose.dev.yml`)

Estos servicios existen en el código base pero no están incluidos en el archivo `docker-compose.dev.yml` principal. Para integrarlos, necesitarían ser añadidos al compose.

-   **Servicio de Benchmarks (`services/benchmark`):** Probablemente diseñado para realizar pruebas de rendimiento sobre componentes o configuraciones.
-   **Servicio de Builds (`services/builds`):** Posiblemente para gestionar y guardar las configuraciones de PC (builds) creadas por los usuarios.
-   **Servicio de Componentes (`services/components`):** Para gestionar la información de los componentes de hardware (CPU, GPU, etc.) y verificar su compatibilidad.
-   **Servicio de Precios (`services/pricing`):** Encargado de obtener y actualizar los precios de los componentes, posiblemente a través de web scraping.

## 4. Configuración del Entorno (`.env`)

Para que los servicios funcionen correctamente, es necesario crear un archivo `.env` en la raíz del directorio `infra/docker`. Este archivo debe contener las siguientes variables de entorno:

```env
# Base de Datos de Usuarios
DATABASE_URL=postgresql://user:password@host:port/database

# Base de Datos de Publicaciones
POSTS_DATABASE_URL=postgresql://user:password@host:port/database

# Secretos para JWT (Deben ser iguales en api-gateway y user-service)
SECRET_KEY=tu_super_secreto_para_users
JWT_SECRET=tu_super_secreto_para_gateway
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Configuración de Email (SMTP) para el servicio de usuarios
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=tu_email@example.com
SMTP_APP_PASSWORD=tu_contraseña_de_aplicacion

# URL del Frontend (para la verificación por correo)
FRONTEND_URL=http://localhost:3000

# Credenciales de Cloudinary (para la API Gateway)
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret
```

**Nota:** Asegúrate de que `SECRET_KEY` (usada por `user-service`) y `JWT_SECRET` (usada por `api-gateway`) tengan el mismo valor para que la validación de tokens funcione.

## 5. Uso de Docker

Docker se utiliza para contenerizar cada microservicio, asegurando un entorno de ejecución consistente y aislado. `Docker Compose` orquesta el despliegue y la comunicación entre los diferentes servicios.

-   **`Dockerfile`:** Cada servicio dockerizado (`api_gateway`, `users`, `posts`) tiene su propio `Dockerfile`. Este archivo contiene las instrucciones para construir la imagen de Docker del servicio, incluyendo la instalación de dependencias y la configuración del punto de entrada.
-   **`docker-compose.dev.yml`:** Ubicado en `infra/docker`, este archivo define cómo se levantan los servicios.
    -   Define los servicios a ejecutar (`user-service`, `api-gateway`, `posts-service`).
    -   Especifica el contexto de construcción y el `Dockerfile` para cada servicio.
    -   Carga las variables de entorno desde el archivo `.env`.
    -   Expone los puertos necesarios (el puerto `8000` de la API Gateway se mapea al host).
    -   Crea una red virtual (`pcbuilder_net`) para que los contenedores puedan comunicarse entre sí por sus nombres de servicio.

## 6. Cómo Iniciar el Proyecto

Para levantar todos los servicios definidos en el `docker-compose`, sigue estos pasos:

1.  **Navega al directorio de Docker:**
    ```bash
    cd "C:\Users\weon2\OneDrive\Desktop\modular\Proyecto 3\PConstruct\infra\docker"
    ```

2.  **Crea y configura tu archivo `.env`** en este directorio con los valores correspondientes, como se explicó en la sección 4.

3.  **Ejecuta Docker Compose:**
    ```bash
    docker-compose -f docker-compose.dev.yml up --build
    ```

    -   `up`: Inicia los contenedores.
    -   `--build`: Fuerza la reconstrucción de las imágenes de Docker si ha habido cambios en los `Dockerfile` o en el código fuente de los servicios.

4.  **Verificar:** Una vez que los contenedores estén en ejecución, la API Gateway estará disponible en `http://localhost:8000`.

Para detener los servicios, puedes presionar `Ctrl + C` en la terminal donde se ejecutó el comando, o ejecutar `docker-compose -f docker-compose.dev.yml down` desde el mismo directorio.
