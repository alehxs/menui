# Codebase Concerns

**Analysis Date:** 2026-01-20

## Tech Debt

**Backend: Python dependencies unpinned:**
- Issue: `backend/requirements.txt` lists packages without version constraints (fastapi, uvicorn, httpx, redis, python-dotenv, slowapi)
- Files: `backend/requirements.txt`
- Impact: Breaking changes in dependencies could silently break production. Different environments may have different versions, making bugs difficult to reproduce.
- Fix approach: Pin exact versions with `pip freeze > requirements.txt` or specify version ranges (e.g., `fastapi>=0.104.0,<1.0.0`)

**Backend: .env file committed to repository:**
- Issue: `.env` file exists in `backend/` and is tracked by git despite containing sensitive credentials
- Files: `backend/.env`
- Impact: API keys and secrets are exposed in version control history. Anyone with repository access has Google API key and Redis credentials.
- Fix approach: Remove `.env` from git history (`git rm --cached backend/.env`), ensure `backend/.gitignore` includes `.env`, create `.env.example` template with placeholder values

**iOS: Placeholder views for History and Favorites tabs:**
- Issue: MainTabView contains stub PlaceholderView components for History and Favorites functionality
- Files: `Menui/MainTabView.swift` (lines 19-29)
- Impact: Two of three tabs are non-functional, creating incomplete user experience
- Fix approach: Implement proper History and Favorites views per recent commit history (files exist in git status: HistoryView.swift, FavoritesView.swift, etc. but not integrated)

**iOS: No error handling UI for API failures:**
- Issue: APIService only throws generic errors (APIError.requestFailed, APIError.invalidResponse) with no user-friendly messages
- Files: `Menui/Services/APIService.swift` (lines 76-79), `Menui/Views/ResultsView.swift` (lines 90-91)
- Impact: Users see generic "Failed to load images" message for all error types (network failure, rate limit, server error, etc.). No retry mechanism.
- Fix approach: Add specific error cases (network, timeout, rateLimit, serverError), display contextual error messages, implement retry button

**iOS: OCR bounding box filtering computed but unused:**
- Issue: OCRService filters observations by bounding box position but never uses the filtered result
- Files: `Menui/Services/OCRService.swift` (lines 29-35)
- Impact: Dead code that adds complexity without benefit. Current implementation processes all text regardless of position.
- Fix approach: Either use the filtered observations (replace `observations` with filtered result on line 37) or remove the filtering logic entirely

**Backend: Hardcoded production behavior based on environment variable:**
- Issue: API documentation endpoints disabled in production based on `RENDER` env var check
- Files: `backend/app/main.py` (lines 65-66)
- Impact: Tightly couples deployment to specific platform (Render.com). Moving to different host requires code changes.
- Fix approach: Use explicit `ENVIRONMENT` or `DISABLE_DOCS` config variable instead of platform detection

**iOS: DishParserService contains extensive hardcoded pattern lists:**
- Issue: 150+ line service contains multiple large arrays of keywords for dish parsing (mexicanDishStarters, sectionHeaders, skipPatterns, etc.)
- Files: `Menui/Services/DishParserService.swift` (lines 13-69)
- Impact: Difficult to maintain and extend. Adding new cuisine types requires code changes. Pattern lists are not data-driven.
- Fix approach: Move pattern lists to external JSON configuration files or database, implement rule engine for extensibility

## Known Bugs

**OCR filtering silently discards edge text:**
- Symptoms: Text detected near edges of image (< 15% or > 85% horizontally, < 10% or > 90% vertically) is filtered out but still processed
- Files: `Menui/Services/OCRService.swift` (lines 29-38)
- Trigger: Scan menu with dish names positioned at edges of frame
- Workaround: Center menu in camera viewfinder. Current code computes filtered list but doesn't use it, so all text is actually returned.

**Backend: AsyncIO TaskGroup requires Python 3.11+:**
- Symptoms: Application fails to start on Python 3.8-3.10 with AttributeError on asyncio.TaskGroup
- Files: `backend/app/main.py` (line 294)
- Trigger: Deploy to environment with Python < 3.11
- Workaround: Use `asyncio.gather()` instead for backward compatibility. README claims Python 3.8+ support but code requires 3.11+.

**iOS: Image loading failures show empty space:**
- Symptoms: When AsyncImage fails to load URL (CORS block, 404, timeout), shows generic photo icon but no retry option
- Files: `Menui/Views/ResultsView.swift` (lines 127-131)
- Trigger: Backend returns URLs from blocked domains or images get deleted
- Workaround: None - user must re-scan menu

## Security Considerations

**Backend: CORS allows all origins by default:**
- Risk: Any website can make requests to API, enabling unauthorized use and quota exhaustion
- Files: `backend/app/config.py` (line 21), `backend/app/main.py` (lines 74-80)
- Current mitigation: Rate limiting (30 req/min per IP)
- Recommendations: Set ALLOWED_ORIGINS to specific iOS app domain in production. Document proper CORS setup in deployment guide.

**Backend: Admin secret validation timing attack:**
- Risk: Admin cache clear endpoint compares secrets using `!=` operator, vulnerable to timing attacks
- Files: `backend/app/main.py` (line 342)
- Current mitigation: Endpoint requires knowledge of secret header name (X-Admin-Secret)
- Recommendations: Use `secrets.compare_digest()` for constant-time comparison

**Backend: No request payload size limits:**
- Risk: Malicious clients can send large payloads to exhaust memory
- Files: `backend/app/main.py` (no size limit middleware)
- Current mitigation: Pydantic validation limits dishes to 20 items, dish names to 100 chars
- Recommendations: Add FastAPI middleware to limit request body size (e.g., 1MB max)

**iOS: API endpoint URL hardcoded in source:**
- Risk: Backend URL change requires app store update, can't hotfix endpoint changes
- Files: `Menui/Services/APIService.swift` (line 13)
- Current mitigation: None
- Recommendations: Move baseURL to configuration file or remote config service for runtime updates

**Backend: Google API key has broad scope:**
- Risk: If leaked, key can be used for any Google Custom Search requests until manually revoked
- Files: `backend/app/config.py` (line 7)
- Current mitigation: Key stored in environment variables, not in code
- Recommendations: Restrict API key to specific referrers/IP addresses in Google Cloud Console

**Backend: Redis connection failure silently degrades performance:**
- Risk: When Redis is unavailable, app continues without caching, potentially exhausting Google API quota
- Files: `backend/app/main.py` (lines 101-103, 177-187, 193-204)
- Current mitigation: Logs warning but continues operation
- Recommendations: Add monitoring/alerting for Redis failures, implement circuit breaker to prevent quota exhaustion

## Performance Bottlenecks

**Backend: Sequential cache writes after API calls:**
- Problem: Cache writes happen asynchronously but fire-and-forget, no guarantee of completion before response
- Files: `backend/app/main.py` (line 226)
- Cause: `asyncio.create_task()` doesn't wait for cache write completion
- Improvement path: For failed cache writes, subsequent requests repeat expensive Google API calls. Add cache write error logging and health monitoring.

**iOS: All dish images fetched upfront:**
- Problem: ResultsView fetches images for all dishes immediately, even those off-screen
- Files: `Menui/Views/ResultsView.swift` (lines 86-94)
- Cause: Single API call for entire dish list, all AsyncImage views created at once
- Improvement path: Implement lazy loading with pagination or on-demand image fetching as user scrolls

**Backend: No connection pooling for httpx client:**
- Problem: Each Google API request creates new httpx.AsyncClient instance
- Files: `backend/app/main.py` (line 147)
- Cause: Client created in context manager per request
- Improvement path: Create shared httpx.AsyncClient at startup with connection pooling, reuse across requests

**iOS: Camera session starts/stops on every navigation:**
- Problem: Camera session restarts when returning from ResultsView, causing delay and flash
- Files: `Menui/Views/CameraView.swift` (lines 79-82, 104-108)
- Cause: Session stopped on navigation, restarted on appear
- Improvement path: Keep session running in background or cache session state

## Fragile Areas

**DishParserService pattern matching logic:**
- Files: `Menui/Services/DishParserService.swift`
- Why fragile: Complex nested conditionals (lines 84-140) with overlapping pattern checks. Easy to introduce regression when adding new patterns. No test coverage.
- Safe modification: Add new patterns to existing arrays first, test thoroughly with real menus. Avoid changing filter order without regression testing.
- Test coverage: No unit tests found for dish extraction logic

**Backend parallel fetching with semaphore:**
- Files: `backend/app/main.py` (lines 207-234, 290-298)
- Why fragile: Complex concurrent code with shared dictionary, TaskGroup error handling. Race conditions possible if results_dict modified incorrectly.
- Safe modification: Never modify google_api_semaphore value without load testing. Ensure all exceptions caught in fetch_and_cache_with_semaphore.
- Test coverage: No tests for concurrent behavior

**iOS camera permission handling:**
- Files: `Menui/Views/CameraView.swift`, `Menui/Services/CameraManager.swift`
- Why fragile: No explicit permission checking, relies on system prompts. If denied, camera shows black screen with no error message.
- Safe modification: Add AVCaptureDevice.authorizationStatus check before session start
- Test coverage: No handling for permission denied state

## Scaling Limits

**Google API free tier quota:**
- Current capacity: 100 queries per day (Google Custom Search free tier)
- Limit: At 30 req/min rate limit with 20 dishes max per request = 600 dishes/min = 36,000 dishes/day theoretical max. Google quota limits to ~100 unique dishes per day.
- Scaling path: Paid Google API tier ($5 per 1000 queries), implement aggressive caching (30-day TTL already set), add fallback image sources (Unsplash, Pexels)

**Redis memory constraints:**
- Current capacity: Upstash free tier = 256MB
- Limit: Each cached dish ~1-3KB (JSON array of URLs). Approximately 85,000-250,000 dishes at capacity. With 30-day TTL, sustainable for moderate use.
- Scaling path: Upgrade Upstash tier, implement LRU eviction policy, compress cached data

**Backend concurrency limit:**
- Current capacity: MAX_CONCURRENT_GOOGLE_CALLS = 10 (configurable via env var)
- Limit: Semaphore limits parallel Google API calls. With 10 concurrent calls at ~1-2s each, max throughput ~5-10 requests/sec
- Scaling path: Increase semaphore limit (watch for Google API rate limits), add request queuing, horizontal scaling with multiple backend instances

**iOS: No pagination for large result sets:**
- Current capacity: Displays all dishes in single List view
- Limit: Menus with 50+ dishes cause memory pressure from simultaneous image loading
- Scaling path: Implement virtual scrolling, lazy load images, limit visible dishes with "Load More" button

## Dependencies at Risk

**Backend: slowapi maintenance status unclear:**
- Risk: Last significant update 2+ years ago, limited Python 3.11+ testing
- Impact: Rate limiting could break on Python version upgrades
- Migration plan: Switch to fastapi-limiter (more actively maintained) or implement custom rate limiting with Redis

**Backend: Python 3.13 in venv but no version constraint:**
- Risk: Using Python 3.13 locally but README claims 3.8+ support, actual code needs 3.11+
- Impact: Version mismatch between development, production
- Migration plan: Add `python_requires='>=3.11'` to setup or requirements, update documentation to match

## Missing Critical Features

**No user feedback during OCR processing:**
- Problem: ResultsView shows "Scanning menu..." but no visual indication of OCR progress or detected text count
- Blocks: User doesn't know if scanning is working or stuck
- Priority: Medium - affects perceived performance

**No retry mechanism for failed operations:**
- Problem: API failures, OCR failures, image load failures all terminal with no retry
- Blocks: Users must re-scan menu from scratch on any failure
- Priority: High - poor user experience

**No caching of OCR results:**
- Problem: Re-opening same scanned image runs OCR again
- Blocks: Wasted computation, battery drain
- Priority: Low - OCR is fast on-device

**No offline support:**
- Problem: App completely non-functional without network connection (can't fetch images)
- Blocks: Usage in areas with poor connectivity (common in restaurants)
- Priority: Medium - could show cached images or placeholder state

## Test Coverage Gaps

**Backend API endpoints:**
- What's not tested: All endpoints (no test files found)
- Files: `backend/app/main.py`
- Risk: Changes to validation, caching logic, or error handling could break production silently
- Priority: High

**iOS DishParserService extraction logic:**
- What's not tested: Pattern matching, filtering, text cleaning
- Files: `Menui/Services/DishParserService.swift`
- Risk: Regex changes or pattern additions could regress dish detection accuracy
- Priority: High

**iOS camera permissions and error states:**
- What's not tested: Permission denied, camera unavailable, capture failures
- Files: `Menui/Services/CameraManager.swift`, `Menui/Views/CameraView.swift`
- Risk: Edge cases leave users with no guidance on fixing issues
- Priority: Medium

**Backend concurrent API fetching:**
- What's not tested: Semaphore behavior under load, race conditions in results_dict, TaskGroup error propagation
- Files: `backend/app/main.py` (lines 207-298)
- Risk: Race conditions or deadlocks under high concurrency
- Priority: Medium

**iOS network error scenarios:**
- What's not tested: Timeout, rate limiting, malformed responses, partial failures
- Files: `Menui/Services/APIService.swift`, `Menui/Views/ResultsView.swift`
- Risk: Poor error messages, app hangs, or crashes on network issues
- Priority: Medium

---

*Concerns audit: 2026-01-20*
