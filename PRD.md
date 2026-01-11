# Menui Backend - Product Requirements Document

## Overview

Backend API service for the Menui iOS app. Takes dish names extracted from menu photos and returns relevant food images from Google Custom Search. Uses Redis caching to minimize API calls and improve response times.

---

## Architecture
```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│    iOS App      │  POST   │  FastAPI        │  GET    │  Google Custom  │
│                 │ ──────► │  Backend        │ ──────► │  Search API     │
│  dish names[]   │         │                 │         │                 │
└─────────────────┘         └────────┬────────┘         └─────────────────┘
                                     │
                                     │ cache
                                     ▼
                            ┌─────────────────┐
                            │     Redis       │
                            │   (Upstash)     │
                            └─────────────────┘
```

---

## API Endpoints

### `GET /health`

Health check endpoint for monitoring and deploys.

**Response:**
```json
{
  "status": "ok",
  "redis": "connected"
}
```

---

### `POST /api/dishes/images`

Returns image URLs for a list of dish names.

**Request:**
```json
{
  "dishes": ["Pad Thai", "Green Curry", "Spring Rolls"]
}
```

**Response:**
```json
{
  "results": {
    "Pad Thai": ["url1.jpg", "url2.jpg", "url3.jpg"],
    "Green Curry": ["url1.jpg", "url2.jpg", "url3.jpg"],
    "Spring Rolls": ["url1.jpg", "url2.jpg", "url3.jpg"]
  },
  "cached": 2,
  "fetched": 1
}
```

---

## Security Requirements

### 1. Input Validation

| Rule | Limit |
|------|-------|
| Max dishes per request | 20 |
| Dish name length | 2-100 characters |
| Allowed characters | Letters, numbers, spaces, hyphens, apostrophes, accented characters |

**Implementation:**
```python
@field_validator("dishes")
def validate_dishes(cls, v):
    if len(v) > 20:
        raise ValueError("Maximum 20 dishes per request")
    
    for dish in v:
        if len(dish) < 2 or len(dish) > 100:
            raise ValueError("Dish name must be 2-100 characters")
        
        if not re.match(r"^[\w\s\-'&áéíóúñü]+$", dish, re.IGNORECASE | re.UNICODE):
            raise ValueError("Invalid characters in dish name")
```

---

### 2. Rate Limiting

| Limit | Value |
|-------|-------|
| Requests per minute per IP | 30 |
| Burst allowance | 10 |

**Implementation:**
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/dishes/images")
@limiter.limit("30/minute")
async def get_dish_images(request: Request, dish_request: DishRequest):
    ...
```

**Response when exceeded:**
```json
{
  "detail": "Rate limit exceeded. Try again later."
}
```
HTTP Status: `429 Too Many Requests`

---

### 3. API Key Security

**Never expose API keys in:**
- Source code
- Client-side code
- Git repositories
- Error messages

**Implementation:**

`.env` file (never committed):
```
GOOGLE_API_KEY=your_key_here
GOOGLE_SEARCH_ENGINE_ID=your_id_here
REDIS_URL=redis://localhost:6379
```

`.gitignore`:
```
.env
```

`config.py`:
```python
import os
from dotenv import load_dotenv

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_SEARCH_ENGINE_ID = os.getenv("GOOGLE_SEARCH_ENGINE_ID")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
```

---

### 4. CORS Configuration

Restrict allowed origins in production.

**Development:**
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
)
```

**Production:**
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_methods=["GET", "POST"],
)
```

---

## Caching Strategy

### Redis Key Structure
```
dish:{dish_name_lowercase}
```

**Examples:**
```
dish:pad thai
dish:green curry
dish:crème brûlée
```

### Cache Duration

| Setting | Value |
|---------|-------|
| TTL | 30 days (2,592,000 seconds) |

### Cache Flow
```
1. Request comes in for ["Pad Thai", "Tacos"]
2. Check Redis for "dish:pad thai"
   - HIT: Return cached URLs
   - MISS: Continue to step 3
3. Call Google Custom Search API
4. Store result in Redis with 30-day TTL
5. Return URLs to client
```

---

## Error Handling

| Error | Status Code | Response |
|-------|-------------|----------|
| Invalid input | 422 | `{"detail": "Validation error message"}` |
| Rate limit exceeded | 429 | `{"detail": "Rate limit exceeded. Try again later."}` |
| Google API failure | 200 | Empty array for that dish `{"Pad Thai": []}` |
| Redis connection failure | 200 | Falls back to Google API (no caching) |
| Server error | 500 | `{"detail": "Internal server error"}` |

---

## Dependencies

### Python Packages
```
fastapi          # Web framework
uvicorn          # ASGI server
httpx            # Async HTTP client
redis            # Redis client
python-dotenv    # Environment variables
slowapi          # Rate limiting
pydantic         # Data validation
```

### External Services

| Service | Purpose | Free Tier |
|---------|---------|-----------|
| Google Custom Search API | Image search | 100 queries/day |
| Upstash Redis | Caching | 10k requests/day, 256MB |
| Railway / Fly.io | Hosting | $5 credit / free tier |

---

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GOOGLE_API_KEY` | Google Cloud API key | Yes |
| `GOOGLE_SEARCH_ENGINE_ID` | Programmable Search Engine ID | Yes |
| `REDIS_URL` | Redis connection string | Yes |

---

## Deployment Checklist

- [ ] Set all environment variables in hosting platform
- [ ] Update CORS origins to production domain
- [ ] Verify Redis connection
- [ ] Test rate limiting
- [ ] Monitor Google API quota usage
- [ ] Set up error alerting

---

## Future Enhancements

### v1.1
- [ ] Add request logging
- [ ] Add API key authentication for iOS app
- [ ] Implement request queuing for burst traffic

### v1.2
- [ ] Add image quality scoring
- [ ] Filter inappropriate images
- [ ] Support multiple image sources (Bing, Unsplash)

### v2.0
- [ ] User accounts
- [ ] Favorite dishes sync
- [ ] Scan history sync
