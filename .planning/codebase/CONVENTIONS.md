# Coding Conventions

**Analysis Date:** 2026-01-20

## Naming Patterns

**Files:**
- Swift: PascalCase for all files - `APIService.swift`, `CameraView.swift`, `DishParserService.swift`
- Python: snake_case for all files - `main.py`, `config.py`, `__init__.py`

**Functions:**
- Swift: camelCase - `fetchDishImages()`, `extractDishes()`, `recognizeText()`, `capturePhoto()`
- Python: snake_case - `fetch_images_from_google()`, `get_cached_images()`, `cache_images()`, `health_check()`

**Variables:**
- Swift: camelCase for properties and local variables - `dishNames`, `capturedImage`, `baseURL`, `isProcessing`
- Python: snake_case for all variables - `redis_client`, `dish_name`, `image_urls`, `cache_key`

**Types:**
- Swift: PascalCase for classes, structs, enums - `APIService`, `DishParserService`, `OCRService`, `CameraManager`, `APIError`
- Python: PascalCase for classes and Pydantic models - `DishRequest`, `ImageResult`, `DishImagesResponse`, `HealthResponse`

**Constants:**
- Swift: camelCase - `baseURL`, `skipPatterns`, `fragmentStarters`
- Python: SCREAMING_SNAKE_CASE in config - `GOOGLE_API_KEY`, `REDIS_URL`, `CACHE_TTL_SECONDS`, `MAX_DISHES_PER_REQUEST`

## Code Style

**Formatting:**
- Swift: Standard Xcode formatting (no custom formatter detected)
- Python: No formatter detected (black/autopep8 not configured)
- Both: 4-space indentation

**Linting:**
- Swift: No linter detected (no `.swiftlint.yml`)
- Python: No linter detected (no `.flake8`, `.pylintrc`, or `pyproject.toml` linting config)

**Line Length:**
- Swift: Lines kept under ~100 characters in practice
- Python: Lines kept under ~100 characters in practice

## Import Organization

**Swift Order:**
1. System frameworks (Foundation, SwiftUI, UIKit, AVFoundation, Vision)
2. Third-party frameworks (none currently)
3. Internal modules (none - single module app)

**Swift Pattern:**
```swift
import SwiftUI
import AVFoundation
```

**Python Order:**
1. Standard library imports
2. Third-party packages
3. Local app imports

**Python Pattern:**
```python
import os
import asyncio
from fastapi import FastAPI, HTTPException, Request, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from typing import List, Optional
import httpx
import redis.asyncio as redis
import json
from slowapi import Limiter, _rate_limit_exceeded_handler
from app import config
```

**Path Aliases:**
- Not used in this codebase

## Error Handling

**Swift Patterns:**
- Use `async throws` for async operations that can fail
- Define custom error enums for specific domains: `enum APIError: Error`
- Guard statements for early returns: `guard !dishes.isEmpty else { return [:] }`
- Optional chaining with guard: `guard let httpResponse = response as? HTTPURLResponse`
- Print errors to console: `print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")`

**Swift Example:**
```swift
func fetchDishImages(for dishes: [String]) async throws -> [String: [String]] {
    guard !dishes.isEmpty else { return [:] }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.requestFailed
    }

    let decoded = try JSONDecoder().decode(DishImagesResponse.self, from: data)
    return result
}
```

**Python Patterns:**
- Raise `HTTPException` for API errors with status codes
- Try-except blocks with specific exception types
- Return empty/default values on non-critical errors (graceful degradation)
- Print errors to console with emoji indicators: `print(f"❌ Error: {e}")`
- Use `Optional` type hints for nullable values

**Python Example:**
```python
async def get_cached_images(dish_name: str) -> Optional[List[str]]:
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
```

## Logging

**Swift Framework:** Console only (standard `print()`)

**Swift Patterns:**
- Print errors with context: `print("Error setting up camera input: \(error)")`
- Print API errors: `print("API Error: \(error)")`
- No structured logging framework

**Python Framework:** Console only (standard `print()`)

**Python Patterns:**
- Use emoji prefixes for visual clarity: `✅` success, `⚠️` warning, `❌` error
- Include context in messages: `print(f"❌ Google API error for '{dish_name}': {e}")`
- No structured logging framework (logging module not used)

## Comments

**When to Comment:**
- File headers with purpose and creation date
- Section separators in Python (with `# ============` borders)
- Complex logic explanations in `DishParserService.swift`
- Function/method documentation comments

**Swift Pattern:**
```swift
//
//  APIService.swift
//  Menui
//
//  Calls backend API to fetch dish images
//

/// Fetches image URLs for a list of dish names
/// - Parameter dishes: Array of dish names from OCR
/// - Returns: Dictionary mapping dish name -> image URLs
func fetchDishImages(for dishes: [String]) async throws -> [String: [String]] {
```

**Python Pattern:**
```python
# ============================================
# 1. PYDANTIC MODELS (Data Validation)
# ============================================

async def fetch_images_from_google(dish_name: str) -> List[str]:
    """
    Fetch image URLs for a dish from Google Custom Search API

    Args:
        dish_name: Name of the dish to search for

    Returns:
        List of image URLs (up to IMAGES_PER_DISH)
    """
```

**MARK Comments:**
- Swift uses `// MARK: -` for section organization
- Example: `// MARK: - Response Models`, `// MARK: - Errors`, `// MARK: - Dish Row`

## Function Design

**Size:**
- Swift: Functions generally under 50 lines
- Python: Functions under 60 lines, with `get_dish_images()` as exception (complex orchestration)

**Parameters:**
- Swift: Use parameter labels for clarity - `from image:`, `for dishes:`
- Python: Type hints required for all parameters
- Both: Prefer fewer parameters (1-3), use models/structs for complex data

**Return Values:**
- Swift: Use explicit return types, `async throws` when needed
- Python: Use type hints including `Optional`, `List`, custom models
- Both: Return empty collections instead of nil when possible

**Swift Example:**
```swift
func extractDishes(from lines: [String]) -> [String]
func recognizeText(from image: UIImage) async -> [String]
func fetchDishImages(for dishes: [String]) async throws -> [String: [String]]
```

**Python Example:**
```python
async def get_cached_images(dish_name: str) -> Optional[List[str]]
async def cache_images(dish_name: str, image_urls: List[str])
async def health_check() -> HealthResponse
```

## Module Design

**Swift Exports:**
- All types are internal by default (no access modifiers in most places)
- Use `private` for internal implementation details: `private let baseURL`, `private init()`
- Use `@Published` for ObservableObject properties: `@Published var capturedImage: UIImage?`

**Swift Pattern:**
```swift
class APIService {
    static let shared = APIService()
    private let baseURL = "https://menui-f9n2.onrender.com"
    private init() {}
}
```

**Python Exports:**
- FastAPI routes use decorators: `@app.get()`, `@app.post()`
- Config values exported from `config.py` as module-level constants
- No `__all__` definition (implicit exports)

**Barrel Files:**
- Not used (Python has `__init__.py` but it's empty)

## Swift-Specific Patterns

**Property Wrappers:**
- `@Published` for observable properties
- `@State` for view-local state
- `@StateObject` for owned ObservableObject instances
- `@Environment` for environment values like `\.dismiss`

**SwiftUI Patterns:**
- Embed child views as computed properties or extract to separate structs
- Use `task` modifier for async work on view appear
- Prefer `.fullScreenCover` and `.sheet` for modal presentations

**Async/Await:**
- Use `async`/`await` for asynchronous operations
- `withCheckedContinuation` for bridging callback-based APIs to async

## Python-Specific Patterns

**Type Hints:**
- Use everywhere: function parameters, return types, class properties
- Import from `typing`: `List`, `Optional`, `Dict`
- Pydantic models for request/response validation

**Async/Await:**
- FastAPI endpoints use `async def`
- Use `asyncio.gather()` for parallel execution
- Use `asyncio.TaskGroup()` for better error handling (Python 3.11+)
- Use `asyncio.Semaphore` for concurrency limiting

**Pydantic Validators:**
```python
@validator('dishes')
def validate_dish_names(cls, dishes):
    for dish in dishes:
        dish_len = len(dish.strip())
        if dish_len < config.MIN_DISH_NAME_LENGTH:
            raise ValueError(f"Dish name must be between...")
    return [d.strip() for d in dishes]
```

## Dependency Injection

**Swift:**
- Singleton pattern for services: `APIService.shared`, `OCRService()`, `DishParserService()`
- No formal DI framework
- Pass dependencies through initializers or as properties

**Python:**
- Global module-level instances: `redis_client`, `limiter`
- FastAPI dependency injection via `Request` parameter
- Configuration via environment variables through `config` module

---

*Convention analysis: 2026-01-20*
