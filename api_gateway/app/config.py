import os
import time
import logging
from datetime import datetime, timedelta

# Logging base config (igual que antes)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("api_gateway")

SERVICE_CONFIG = {
    "user": os.getenv("USER_SERVICE_URL", "http://user-service:8001"),
    "posts": os.getenv("POSTS_SERVICE_URL", "http://posts-service:8002"),
    "component": os.getenv("COMPONENT_SERVICE_URL", "http://component-service:8003"),
    "build": os.getenv("BUILD_SERVICE_URL", "http://build-service:8004"),
    "price": os.getenv("PRICE_SERVICE_URL", "http://pricing-service:8005"),
    "benchmark": os.getenv("BENCHMARK_SERVICE_URL", "http://benchmark-service:8006"),
}

JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_MINUTES = 60 * 24  # 24h

CLOUDINARY_CLOUD_NAME = os.getenv("CLOUDINARY_CLOUD_NAME")
CLOUDINARY_API_KEY = os.getenv("CLOUDINARY_API_KEY")
CLOUDINARY_API_SECRET = os.getenv("CLOUDINARY_API_SECRET")
