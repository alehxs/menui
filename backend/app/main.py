import os
from fastapi import FastAPI, HTTPException, Request, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from typing import List, Optional
import httpx
import redis.asyncio as redis
import json
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app import config

# Rate limiter - uses IP address to track requests
limiter = Limiter(key_func=get_remote_address)

# ============================================
# 1. PYDANTIC MODELS (Data Validation)
# ============================================

class DishRequest(BaseModel):
    """Request model: list of dish names from OCR"""
    dishes: List[str] = Field(..., min_items=1, max_items=config.MAX_DISHES_PER_REQUEST)

    @validator('dishes')
    def validate_dish_names(cls, dishes):
        for dish in dishes:
            dish_len = len(dish.strip())
            if dish_len < config.MIN_DISH_NAME_LENGTH or dish_len > config.MAX_DISH_NAME_LENGTH:
                raise ValueError(f"Dish name must be between {config.MIN_DISH_NAME_LENGTH}-{config.MAX_DISH_NAME_LENGTH} characters")
        return [d.strip() for d in dishes]


class ImageResult(BaseModel):
    """Image URLs for a single dish"""
    dish_name: str
    image_urls: List[str]
    from_cache: bool = False


class DishImagesResponse(BaseModel):
    """Response: all dishes with their images"""
    results: List[ImageResult]
    total_dishes: int


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    redis_connected: bool


# ============================================
# 2. FASTAPI APP INITIALIZATION
# ============================================

app = FastAPI(
    title="Menui API",
    description="Fetch food images from Google Custom Search",
    version="1.0.0",
    docs_url=None if os.getenv("RENDER") else "/docs",
    redoc_url=None if os.getenv("RENDER") else "/redoc",
)

# Rate limiter setup
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Middleware - allows iOS app to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================
# 3. REDIS CONNECTION
# ============================================

redis_client: Optional[redis.Redis] = None

@app.on_event("startup")
async def startup_event():
    """Initialize Redis connection when server starts"""
    global redis_client
    try:
        redis_client = redis.from_url(
            config.REDIS_URL,
            encoding="utf-8",
            decode_responses=True
        )
        await redis_client.ping()
        print("✅ Redis connected successfully")
    except Exception as e:
        print(f"⚠️ Redis connection failed: {e}")
        redis_client = None


@app.on_event("shutdown")
async def shutdown_event():
    """Close Redis connection when server stops"""
    if redis_client:
        await redis_client.close()


# ============================================
# 4. GOOGLE CUSTOM SEARCH FUNCTION
# ============================================

async def fetch_images_from_google(dish_name: str) -> List[str]:
    """
    Fetch image URLs for a dish from Google Custom Search API

    Args:
        dish_name: Name of the dish to search for

    Returns:
        List of image URLs (up to IMAGES_PER_DISH)
    """
    if not config.GOOGLE_API_KEY or not config.GOOGLE_SEARCH_ENGINE_ID:
        raise HTTPException(
            status_code=500,
            detail="Google API credentials not configured"
        )

    # Build search query
    query = f"{dish_name} {config.SEARCH_QUERY_SUFFIX}"

    # Google Custom Search API endpoint
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": config.GOOGLE_API_KEY,
        "cx": config.GOOGLE_SEARCH_ENGINE_ID,
        "q": query,
        "searchType": "image",
        "num": config.IMAGES_TO_FETCH,  # Fetch extra to filter bad sources
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, timeout=10.0)
            response.raise_for_status()
            data = response.json()

            # Extract image URLs, filtering out blocked domains
            image_urls = []
            if "items" in data:
                for item in data["items"]:
                    if "link" in item:
                        link = item["link"]
                        # Skip URLs from domains that block hotlinking
                        if not any(domain in link for domain in config.BLOCKED_IMAGE_DOMAINS):
                            image_urls.append(link)
                            if len(image_urls) >= config.IMAGES_PER_DISH:
                                break

            return image_urls

    except httpx.HTTPError as e:
        print(f"❌ Google API error for '{dish_name}': {e}")
        return []  # Return empty list on error instead of failing


# ============================================
# 5. CACHE HELPER FUNCTIONS
# ============================================

async def get_cached_images(dish_name: str) -> Optional[List[str]]:
    """Get images from Redis cache"""
    if not redis_client:
        return None

    try:
        cache_key = f"dish:{dish_name.lower()}"
        cached = await redis_client.get(cache_key)
        if cached:
            return json.loads(cached)
    except Exception as e:
        print(f"⚠️ Cache read error: {e}")

    return None


async def cache_images(dish_name: str, image_urls: List[str]):
    """Store images in Redis cache with TTL"""
    if not redis_client:
        return

    try:
        cache_key = f"dish:{dish_name.lower()}"
        await redis_client.setex(
            cache_key,
            config.CACHE_TTL_SECONDS,
            json.dumps(image_urls)
        )
    except Exception as e:
        print(f"⚠️ Cache write error: {e}")


# ============================================
# 6. API ENDPOINTS
# ============================================

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint
    Returns API status and Redis connection state
    """
    redis_connected = False
    if redis_client:
        try:
            await redis_client.ping()
            redis_connected = True
        except:
            pass

    return HealthResponse(
        status="healthy",
        redis_connected=redis_connected
    )


@app.post("/api/dishes/images", response_model=DishImagesResponse)
@limiter.limit(config.RATE_LIMIT)
async def get_dish_images(request: Request, dish_request: DishRequest):
    """
    Main endpoint: Get images for a list of dishes

    Security: Rate limited to 30 requests/minute per IP address.
    No API key required - Google API credentials stay server-side only.

    Flow:
    1. For each dish, check Redis cache
    2. If not cached, fetch from Google Custom Search API
    3. Cache the results
    4. Return all images
    """
    results = []

    for dish_name in dish_request.dishes:
        # Try cache first
        cached_images = await get_cached_images(dish_name)

        if cached_images is not None:
            # Cache hit!
            results.append(ImageResult(
                dish_name=dish_name,
                image_urls=cached_images,
                from_cache=True
            ))
        else:
            # Cache miss - fetch from Google
            image_urls = await fetch_images_from_google(dish_name)

            # Cache the result for next time
            await cache_images(dish_name, image_urls)

            results.append(ImageResult(
                dish_name=dish_name,
                image_urls=image_urls,
                from_cache=False
            ))

    return DishImagesResponse(
        results=results,
        total_dishes=len(results)
    )


# ============================================
# 7. ROOT ENDPOINT (Optional - for testing)
# ============================================

@app.get("/")
async def root():
    """Root endpoint - confirms API is running"""
    return {
        "message": "Menui API is running",
        "docs": "/docs",
        "health": "/health"
    }


@app.delete("/api/cache/clear")
async def clear_cache(x_admin_secret: str = Header(...)):
    """Clear all cached dish images from Redis. Requires admin secret."""
    if not config.ADMIN_SECRET or x_admin_secret != config.ADMIN_SECRET:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not redis_client:
        raise HTTPException(status_code=503, detail="Redis not connected")

    try:
        # Find and delete all dish cache keys
        cursor = 0
        deleted_count = 0
        while True:
            cursor, keys = await redis_client.scan(cursor, match="dish:*", count=100)
            if keys:
                await redis_client.delete(*keys)
                deleted_count += len(keys)
            if cursor == 0:
                break

        return {"message": f"Cleared {deleted_count} cached dishes"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear cache: {e}")
