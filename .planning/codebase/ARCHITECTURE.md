# Architecture

**Analysis Date:** 2026-01-20

## Pattern Overview

**Overall:** Client-Server Architecture with Mobile-First Design

**Key Characteristics:**
- iOS SwiftUI app communicates with Python FastAPI backend
- Backend acts as API gateway to Google Custom Search
- On-device OCR processing (Apple Vision Framework)
- Asynchronous data flow throughout both client and server
- Redis caching layer for image URL persistence

## Layers

**Presentation Layer (iOS):**
- Purpose: User interface and user interaction handling
- Location: `Menui/Views/`, `Menui/MainTabView.swift`
- Contains: SwiftUI views, navigation, UI state management
- Depends on: Services layer, UIKit bridge components
- Used by: MenuiApp entry point

**Services Layer (iOS):**
- Purpose: Business logic and external integrations
- Location: `Menui/Services/`
- Contains: OCR processing, API client, camera management, dish parsing
- Depends on: Apple frameworks (Vision, AVFoundation), backend API
- Used by: Presentation layer

**API Layer (Backend):**
- Purpose: HTTP request handling and response formatting
- Location: `backend/app/main.py`
- Contains: FastAPI endpoints, Pydantic models, middleware
- Depends on: Configuration, external APIs (Google), Redis
- Used by: iOS APIService

**Business Logic Layer (Backend):**
- Purpose: Image fetching, caching, rate limiting
- Location: `backend/app/main.py` (functions: `fetch_images_from_google`, `get_cached_images`, `cache_images`)
- Contains: Google API integration, cache management, concurrency control
- Depends on: httpx, Redis client
- Used by: API endpoints

**Configuration Layer (Backend):**
- Purpose: Environment-based configuration management
- Location: `backend/app/config.py`
- Contains: API keys, rate limits, feature flags, blocked domains
- Depends on: Environment variables
- Used by: All backend layers

## Data Flow

**Menu Scan Flow:**

1. User captures photo via `Menui/Views/CameraView.swift` using `CameraManager`
2. Image processed on-device by `OCRService` (Apple Vision) → raw text lines
3. `DishParserService` filters OCR output → dish names list
4. `APIService` sends POST request to backend `/api/dishes/images`
5. Backend checks Redis cache for each dish in parallel
6. Cache misses trigger Google Custom Search API calls (concurrency-limited)
7. Image URLs cached in Redis with 30-day TTL
8. Response returned to iOS app with dish → images mapping
9. `ResultsView` displays dishes with AsyncImage loading

**State Management:**
- iOS uses `@StateObject` and `@State` for view-level state
- Backend uses async/await with `asyncio.TaskGroup` for concurrent operations
- No global state management framework on iOS (SwiftUI native patterns)
- Backend maintains Redis connection pool via app lifecycle events

## Key Abstractions

**ObservableObject (iOS):**
- Purpose: Reactive state containers for SwiftUI views
- Examples: `Menui/Services/CameraManager.swift`
- Pattern: Publisher-subscriber with `@Published` properties

**Service Classes (iOS):**
- Purpose: Encapsulate single responsibilities (OCR, parsing, API calls, camera)
- Examples: `Menui/Services/OCRService.swift`, `Menui/Services/DishParserService.swift`, `Menui/Services/APIService.swift`
- Pattern: Singleton for APIService, instance-based for others

**Pydantic Models (Backend):**
- Purpose: Request/response validation and serialization
- Examples: `DishRequest`, `DishImagesResponse`, `ImageResult` in `backend/app/main.py`
- Pattern: Data validation at API boundaries

**Async Functions (Backend):**
- Purpose: Non-blocking I/O for external API calls and Redis operations
- Examples: `fetch_images_from_google`, `get_cached_images`, `fetch_and_cache_with_semaphore`
- Pattern: Async/await with semaphore-based concurrency control

## Entry Points

**iOS App Entry:**
- Location: `Menui/MenuiApp.swift`
- Triggers: App launch
- Responsibilities: Initialize SwiftUI app, set root view to `MainTabView`

**Backend Server Entry:**
- Location: `backend/app/main.py` (FastAPI app instance)
- Triggers: uvicorn server start
- Responsibilities: Initialize FastAPI app, configure CORS, setup rate limiting, establish Redis connection

**Primary User Flow Entry:**
- Location: `Menui/Views/CameraView.swift`
- Triggers: App launch (default tab)
- Responsibilities: Camera session management, photo capture, navigation to results

**API Endpoint Entry:**
- Location: `backend/app/main.py` → `@app.post("/api/dishes/images")`
- Triggers: HTTP POST from iOS app
- Responsibilities: Rate limiting, parallel cache lookup, Google API fetching, response assembly

## Error Handling

**Strategy:** Graceful degradation with user feedback

**Patterns:**
- iOS: Try-catch in async contexts, optional chaining for nullable values
- Backend: Exception handlers return empty arrays rather than failing requests
- API errors logged to console, empty image arrays returned to client
- Redis connection failures logged but don't block requests (cache disabled)
- Rate limiting returns 429 status with slowapi middleware

## Cross-Cutting Concerns

**Logging:**
- iOS: `print()` statements for debugging (OCR errors, API failures)
- Backend: Console output with emoji prefixes (✅, ⚠️, ❌) for visibility

**Validation:**
- iOS: None explicit (relies on backend validation)
- Backend: Pydantic validators on `DishRequest` (length limits, dish count limits)

**Authentication:**
- iOS to Backend: No authentication (public API, rate-limited by IP)
- Backend to Google: API key in request parameters
- Admin endpoints: Header-based secret (`X-Admin-Secret`)

---

*Architecture analysis: 2026-01-20*
