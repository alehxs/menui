# External Integrations

**Analysis Date:** 2026-01-20

## APIs & External Services

**Image Search:**
- Google Custom Search API - Fetches food images for dish names
  - SDK/Client: httpx async HTTP client
  - Auth: API key via `GOOGLE_API_KEY` env var
  - Search Engine ID: `GOOGLE_SEARCH_ENGINE_ID` env var
  - Endpoint: `https://www.googleapis.com/customsearch/v1`
  - Parameters: `searchType=image`, `num=10` (fetches 10, returns 3 after filtering)
  - Quota: 100 queries/day (free tier)
  - Rate limiting: Semaphore limits concurrent calls to 10 (configurable via `MAX_CONCURRENT_GOOGLE_CALLS`)
  - Implementation: `backend/app/main.py` function `fetch_images_from_google()`
  - Blocked domains: Instagram, TikTok, Pinterest, Facebook (hotlinking prevention)

**Backend API:**
- Menui FastAPI Backend - iOS app calls for dish image URLs
  - Base URL: `https://menui-f9n2.onrender.com`
  - Configured in: `Menui/Services/APIService.swift`
  - Main endpoint: `POST /api/dishes/images`
  - Request format: JSON `{"dishes": ["dish1", "dish2"]}`
  - Response: JSON with image URLs array per dish
  - Rate limit: 30 requests/minute per IP address
  - Implementation: `Menui/Services/APIService.swift` class `APIService`

## Data Storage

**Databases:**
- None (no persistent database)

**Caching:**
- Redis (Upstash serverless)
  - Connection: `REDIS_URL` env var (rediss:// protocol for TLS)
  - Client: `redis.asyncio` Python library
  - Implementation: `backend/app/main.py` (startup/shutdown event handlers)
  - Cache key format: `dish:{dish_name_lowercased}`
  - TTL: 30 days (2,592,000 seconds)
  - Purpose: Cache dish name → image URLs mappings
  - Error handling: Graceful degradation (continues without cache if Redis unavailable)

**File Storage:**
- None (images hosted externally by Google search results)

## Authentication & Identity

**Auth Provider:**
- None (no user authentication)

**Admin Protection:**
- Admin secret for maintenance endpoints
  - Header: `X-Admin-Secret`
  - Env var: `ADMIN_SECRET`
  - Protected endpoint: `DELETE /api/cache/clear`
  - Implementation: `backend/app/main.py` line 340-362

## Monitoring & Observability

**Error Tracking:**
- None (prints to stdout only)

**Logs:**
- Backend: stdout/stderr via print statements
  - Success: "✅ Redis connected successfully"
  - Warnings: "⚠️ Redis connection failed", "⚠️ Cache read/write error"
  - Errors: "❌ Google API error for '{dish_name}'"
- iOS: No logging framework (relies on Xcode console)

**Health Check:**
- Endpoint: `GET /health`
- Returns: `{"status": "healthy", "redis_connected": bool}`
- Implementation: `backend/app/main.py` line 241-258

## CI/CD & Deployment

**Hosting:**
- Backend: Render.com web service
  - Auto-deploy on git push to main branch
  - Build command: `pip install -r backend/requirements.txt`
  - Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
  - Root directory: `backend`
- iOS: Manual Xcode archive and upload to App Store Connect

**CI Pipeline:**
- None (manual deployment only)

## Environment Configuration

**Backend Required env vars:**
- `GOOGLE_API_KEY` - Google Custom Search API key
- `GOOGLE_SEARCH_ENGINE_ID` - Programmable Search Engine ID
- `REDIS_URL` - Redis connection string (rediss://default:password@host:port)

**Backend Optional env vars:**
- `ALLOWED_ORIGINS` - CORS origins (default: `*`)
- `ADMIN_SECRET` - Secret for cache clearing endpoint
- `MAX_CONCURRENT_GOOGLE_CALLS` - Concurrent Google API limit (default: 10)
- `ENABLE_PARALLEL_FETCHING` - Enable parallel fetching (default: true)
- `RENDER` - Disables API docs when set (auto-set by Render.com)

**iOS Configuration:**
- No environment variables
- Backend URL hardcoded in `Menui/Services/APIService.swift`
- Change `baseURL` property to switch between production/local backend

**Secrets location:**
- Backend: `.env` file (not committed, gitignored)
- Production: Render.com environment variable dashboard
- iOS: None (no secrets on client)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## CORS Configuration

**Backend CORS Middleware:**
- Implementation: FastAPI CORSMiddleware in `backend/app/main.py` line 74-80
- Allowed origins: Configured via `ALLOWED_ORIGINS` env var
- Default: `*` (allow all)
- Production recommendation: Set to specific iOS app domain
- Credentials: Allowed
- Methods: All (`*`)
- Headers: All (`*`)

## Platform-Specific Frameworks

**Apple Native Frameworks (On-Device Only):**
- Vision Framework - OCR text recognition
  - Language support: English (en-US), Spanish (es-419)
  - Recognition level: Accurate
  - Bounding box filtering: Center X (0.15-0.85), Center Y (0.1-0.9)
  - No network calls, fully on-device
  - Implementation: `Menui/Services/OCRService.swift`

- AVFoundation - Camera capture
  - Camera: Built-in wide-angle rear camera
  - Session preset: Photo quality
  - Output: AVCapturePhotoOutput
  - Permissions: NSCameraUsageDescription required
  - Implementation: `Menui/Services/CameraManager.swift`

---

*Integration audit: 2026-01-20*
