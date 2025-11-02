import os

USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8001")
POSTS_SERVICE_URL = os.getenv("POSTS_SERVICE_URL", "http://posts-service:8002")
COMPONENT_SERVICE_URL = os.getenv("COMPONENT_SERVICE_URL", "http://component-service:8003")
BUILDS_SERVICE_URL = os.getenv("BUILDS_SERVICE_URL", "http://builds-service:8004")
PRICING_SERVICE_URL = os.getenv("PRICING_SERVICE_URL", "http://pricing-service:8005")
BENCHMARK_SERVICE_URL = os.getenv("BENCHMARK_SERVICE_URL", "http://benchmark-service:8006")

JWT_EXP_MINUTES = int(os.getenv("JWT_EXP_MINUTES", "60"))
