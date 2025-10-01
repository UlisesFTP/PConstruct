from fastapi import Depends
from .config import settings

def get_component_service():
    return settings.COMPONENT_SERVICE_URL

def get_pricing_service():
    return settings.PRICING_SERVICE_URL

def get_benchmark_service():
    return settings.BENCHMARK_SERVICE_URL