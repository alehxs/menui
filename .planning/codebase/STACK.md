# Technology Stack

**Analysis Date:** 2026-01-20

## Languages

**Primary:**
- Swift 6.2.3 - iOS application (all client code)
- Python 3.13.7 - Backend API server

**Secondary:**
- Not applicable

## Runtime

**iOS Environment:**
- iOS 18.4+ target
- Swift 6.2.3 runtime
- Xcode project-based (no package manager)

**Backend Environment:**
- Python 3.13.7
- Deployed on Render.com (https://menui-f9n2.onrender.com)

**Package Manager:**
- Python: pip
- Lockfile: None (uses `backend/requirements.txt` only)
- iOS: No external dependencies (100% native frameworks)

## Frameworks

**iOS Core Frameworks:**
- SwiftUI - Declarative UI framework for all views
- AVFoundation - Camera capture and preview (`Menui/Services/CameraManager.swift`)
- Vision Framework - On-device OCR text recognition (`Menui/Services/OCRService.swift`)
- Foundation - Core utilities and URLSession HTTP client
- UIKit - Image handling and camera delegate protocols

**Backend Core:**
- FastAPI (latest) - Async web framework with automatic OpenAPI docs
- Uvicorn (latest) - ASGI server for running FastAPI

**Backend Infrastructure:**
- redis (latest) - Async Redis client for caching (`redis.asyncio`)
- httpx (latest) - Async HTTP client for Google API calls
- python-dotenv (latest) - Environment variable management
- slowapi (latest) - Rate limiting middleware (30 req/min per IP)
- pydantic (latest) - Data validation (included with FastAPI)

**Testing:**
- None configured (manual testing only)

**Build/Dev:**
- Xcode 15.0+ for iOS compilation and signing
- No build configuration beyond standard Xcode

## Key Dependencies

**Critical:**
- Vision Framework - On-device OCR, no network required. Core feature for text extraction from menu photos.
- FastAPI - All backend API endpoints. Serves `/api/dishes/images` endpoint.
- Google Custom Search API - External service for fetching food images. API quota: 100 queries/day (free tier).

**Infrastructure:**
- Redis (Upstash) - Distributed cache with 30-day TTL. Connection via `REDIS_URL` env var. Handles cache hits/misses for dish images.
- AVFoundation - Camera hardware access. Required for menu photo capture.
- URLSession - Native iOS HTTP client. Calls backend POST endpoint with dish names.

## Configuration

**iOS Environment:**
- No environment variables used
- Backend URL hardcoded in `Menui/Services/APIService.swift`: `https://menui-f9n2.onrender.com`
- Camera permissions required via `Info.plist` (NSCameraUsageDescription)
- Network transport security allows arbitrary loads (`Info.plist` - NSAppTransportSecurity)

**Backend Environment:**
- Configuration via environment variables loaded from `.env` file
- Config module: `backend/app/config.py`
- Required vars: `GOOGLE_API_KEY`, `GOOGLE_SEARCH_ENGINE_ID`, `REDIS_URL`
- Optional vars: `ALLOWED_ORIGINS` (default: `*`), `ADMIN_SECRET`, `MAX_CONCURRENT_GOOGLE_CALLS` (default: 10)
- Rate limiting: 30 requests/minute per IP (hardcoded in config)
- Cache TTL: 30 days (hardcoded in config)
- Images per dish: 3 (fetches 10, filters to 3 after removing blocked domains)

**Build:**
- iOS: Standard Xcode build system, no custom build scripts
- Backend: `pip install -r requirements.txt`, run with `uvicorn app.main:app`
- Deployment: Render.com auto-deploys from git push

## Platform Requirements

**Development:**
- macOS with Xcode 15.0+ for iOS development
- iOS 18.4+ device or simulator for testing
- Apple Developer account for physical device testing
- Python 3.8+ for local backend development (optional)
- Redis instance (local or Upstash) for backend caching

**Production:**
- iOS: App Store distribution (requires Apple Developer Program $99/year)
- Backend: Deployed on Render.com (current), compatible with Railway, Fly.io, Heroku, AWS Elastic Beanstalk, Google Cloud Run
- Redis: Upstash serverless Redis (free tier: 10K requests/day, 256MB)
- Google Custom Search API quota: 100 queries/day on free tier

---

*Stack analysis: 2026-01-20*
