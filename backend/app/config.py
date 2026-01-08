import os
from dotenv import load_dotenv

load_dotenv()

# Google Custom Search API
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_SEARCH_ENGINE_ID = os.getenv("GOOGLE_SEARCH_ENGINE_ID")

# Redis Configuration
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
CACHE_TTL_SECONDS = 30 * 24 * 60 * 60  # 30 days

# API Configuration
RATE_LIMIT = "30/minute"  # 30 requests per minute per IP
MAX_DISHES_PER_REQUEST = 20
MIN_DISH_NAME_LENGTH = 2
MAX_DISH_NAME_LENGTH = 100

# CORS
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

# Search Configuration
IMAGES_PER_DISH = 3  # Number of images to fetch per dish
SEARCH_QUERY_SUFFIX = "food dish"  # Append to dish names for better results
