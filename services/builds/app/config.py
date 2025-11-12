# services/builds/app/config.py
from decouple import config

DATABASE_URL = config("BUILDS_DATABASE_URL")
GEMINI_API_KEY = config("GEMINI_API_KEY", default="")