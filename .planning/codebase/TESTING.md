# Testing Patterns

**Analysis Date:** 2026-01-20

## Test Framework

**Runner:**
- Swift: XCTest (standard iOS testing framework)
- Python: Not configured (no test files or framework detected)

**Assertion Library:**
- Swift: XCTest assertions (standard)
- Python: Not applicable

**Run Commands:**
```bash
# Swift (via Xcode)
Command+U                  # Run all tests in Xcode
xcodebuild test           # Run tests from command line

# Python - No tests configured
# Would typically be:
# pytest                   # If pytest were configured
# python -m pytest         # Alternative pytest invocation
# pytest --cov             # With coverage
```

## Test File Organization

**Location:**
- Swift: No test files detected in current codebase
- Python: No test files detected in `/Users/alex/projects/Menui/backend/`

**Expected Naming (if tests existed):**
- Swift: `[ClassName]Tests.swift` (e.g., `APIServiceTests.swift`, `DishParserServiceTests.swift`)
- Python: `test_[module].py` (e.g., `test_main.py`, `test_config.py`)

**Expected Structure:**
```
Menui/
├── Menui/
│   ├── Services/
│   │   ├── APIService.swift
│   │   └── DishParserService.swift
│   └── Views/
│       └── CameraView.swift
└── MenuiTests/                    # Expected but not present
    ├── Services/
    │   ├── APIServiceTests.swift
    │   └── DishParserServiceTests.swift
    └── Views/
        └── CameraViewTests.swift

backend/
├── app/
│   ├── main.py
│   └── config.py
└── tests/                         # Expected but not present
    ├── test_main.py
    └── test_config.py
```

## Test Structure

**Suite Organization:**
- **Current state:** No test suites exist
- **Expected Swift pattern:**
```swift
import XCTest
@testable import Menui

final class DishParserServiceTests: XCTestCase {
    var sut: DishParserService!

    override func setUp() {
        super.setUp()
        sut = DishParserService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testExtractDishes_withValidMenuLines_returnsDishNames() {
        // Given
        let lines = ["Taco Al Pastor", "Burrito Supreme", "appetizers"]

        // When
        let result = sut.extractDishes(from: lines)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("Taco Al Pastor"))
        XCTAssertFalse(result.contains("appetizers"))
    }
}
```

**Expected Python pattern (pytest):**
```python
import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client():
    return TestClient(app)

def test_health_check(client):
    # When
    response = client.get("/health")

    # Then
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_get_dish_images_with_valid_dishes(client):
    # Given
    payload = {"dishes": ["Taco", "Burrito"]}

    # When
    response = client.post("/api/dishes/images", json=payload)

    # Then
    assert response.status_code == 200
    data = response.json()
    assert data["total_dishes"] == 2
```

**Patterns:**
- Swift: Given-When-Then structure (implicit, via comments)
- Python: Given-When-Then or Arrange-Act-Assert
- Both: One assertion per test when possible

## Mocking

**Framework:**
- Swift: Would use protocol-based mocking or libraries like Mockingbird/Cuckoo
- Python: Would use pytest-mock, unittest.mock, or responses library

**Expected Patterns:**

**Swift mocking (if tests existed):**
```swift
// Protocol-based mocking
protocol APIServiceProtocol {
    func fetchDishImages(for dishes: [String]) async throws -> [String: [String]]
}

class MockAPIService: APIServiceProtocol {
    var mockResult: [String: [String]] = [:]
    var shouldThrow = false

    func fetchDishImages(for dishes: [String]) async throws -> [String: [String]] {
        if shouldThrow {
            throw APIError.requestFailed
        }
        return mockResult
    }
}
```

**Python mocking (if tests existed):**
```python
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_fetch_images_uses_cache(mocker):
    # Given
    mock_redis = AsyncMock()
    mock_redis.get.return_value = '["url1.jpg", "url2.jpg"]'
    mocker.patch('app.main.redis_client', mock_redis)

    # When
    result = await get_cached_images("Taco")

    # Then
    assert result == ["url1.jpg", "url2.jpg"]
    mock_redis.get.assert_called_once_with("dish:taco")
```

**What to Mock:**
- External API calls (Google Custom Search, URLSession)
- Database/cache connections (Redis)
- Camera/system services (AVCaptureSession)
- File I/O operations

**What NOT to Mock:**
- Pure business logic (like `DishParserService.extractDishes()`)
- Data models and value types
- Simple utility functions
- Configuration values

## Fixtures and Factories

**Test Data:**

**Expected Swift pattern:**
```swift
// Test fixtures in test file
extension DishParserServiceTests {
    static let sampleMenuLines = [
        "Taco Al Pastor",
        "Enchiladas Verdes",
        "appetizers",
        "with cheese and beans"
    ]

    static let expectedDishes = [
        "Taco Al Pastor",
        "Enchiladas Verdes"
    ]
}

// Use in tests
func testExtractDishes() {
    let result = sut.extractDishes(from: Self.sampleMenuLines)
    XCTAssertEqual(result, Self.expectedDishes)
}
```

**Expected Python pattern:**
```python
# conftest.py
import pytest

@pytest.fixture
def sample_dish_request():
    return {
        "dishes": ["Taco Al Pastor", "Burrito", "Enchiladas"]
    }

@pytest.fixture
def mock_google_api_response():
    return {
        "items": [
            {"link": "https://example.com/taco1.jpg"},
            {"link": "https://example.com/taco2.jpg"},
            {"link": "https://example.com/taco3.jpg"},
        ]
    }

# test_main.py
def test_dish_images_endpoint(client, sample_dish_request):
    response = client.post("/api/dishes/images", json=sample_dish_request)
    assert response.status_code == 200
```

**Location:**
- Swift: Would use class properties or extensions for test data
- Python: Would use `conftest.py` for shared fixtures

## Coverage

**Requirements:** None enforced (no coverage configuration detected)

**Expected View Coverage (if configured):**
```bash
# Swift (via Xcode)
# Enable code coverage in scheme settings
# View coverage report in Xcode > Reports Navigator

# Python
pytest --cov=app --cov-report=html
pytest --cov=app --cov-report=term-missing
open htmlcov/index.html
```

**Typical Coverage Targets (industry standard):**
- Business logic: 80%+ coverage target
- API endpoints: 70%+ coverage target
- UI/Views: 50%+ coverage target (harder to test)

## Test Types

**Unit Tests:**
- **Scope:** Test individual functions and classes in isolation
- **Expected for Swift:**
  - `DishParserService.extractDishes()` - business logic for filtering dish names
  - `APIService.fetchDishImages()` - HTTP client logic (with mocked URLSession)
  - `OCRService.recognizeText()` - text extraction (with mock images)
- **Expected for Python:**
  - `fetch_images_from_google()` - Google API interaction (with mocked httpx)
  - `get_cached_images()` - Redis cache logic (with mocked Redis)
  - Pydantic validators - input validation

**Integration Tests:**
- **Scope:** Test component interactions
- **Expected for Swift:**
  - Camera → OCR → Parser pipeline
  - API Service → Network → Response parsing
- **Expected for Python:**
  - FastAPI endpoint → Cache → Google API → Response
  - Redis connection and cache operations

**E2E Tests:**
- **Framework:** Not configured (would use XCUITest for iOS)
- **Scope:** Full user workflows
- **Expected scenarios:**
  - Capture menu photo → OCR → Display results with images
  - Select photo from library → Process → View dish cards
  - Error handling for network failures

## Common Patterns

**Async Testing:**

**Swift:**
```swift
func testFetchDishImages_withValidDishes_returnsImages() async throws {
    // Given
    let service = APIService.shared
    let dishes = ["Taco", "Burrito"]

    // When
    let result = try await service.fetchDishImages(for: dishes)

    // Then
    XCTAssertEqual(result.keys.count, 2)
    XCTAssertNotNil(result["Taco"])
}
```

**Python:**
```python
@pytest.mark.asyncio
async def test_health_check_pings_redis():
    # Given
    mock_redis = AsyncMock()
    mock_redis.ping.return_value = True

    # When
    with patch('app.main.redis_client', mock_redis):
        response = await health_check()

    # Then
    assert response.redis_connected is True
    mock_redis.ping.assert_called_once()
```

**Error Testing:**

**Swift:**
```swift
func testFetchDishImages_withEmptyArray_returnsEmptyDict() async throws {
    // Given
    let dishes: [String] = []

    // When
    let result = try await APIService.shared.fetchDishImages(for: dishes)

    // Then
    XCTAssertTrue(result.isEmpty)
}

func testAPIError_requestFailed_throwsError() async {
    // Given
    let mockService = MockAPIService()
    mockService.shouldThrow = true

    // When/Then
    await XCTAssertThrowsError(
        try await mockService.fetchDishImages(for: ["Taco"])
    ) { error in
        XCTAssertEqual(error as? APIError, .requestFailed)
    }
}
```

**Python:**
```python
def test_dish_request_validation_rejects_empty_list(client):
    # Given
    payload = {"dishes": []}

    # When
    response = client.post("/api/dishes/images", json=payload)

    # Then
    assert response.status_code == 422  # Validation error

def test_dish_request_validation_rejects_too_many_dishes(client):
    # Given
    payload = {"dishes": ["Dish"] * 21}  # MAX_DISHES_PER_REQUEST is 20

    # When
    response = client.post("/api/dishes/images", json=payload)

    # Then
    assert response.status_code == 422
```

## Testing Recommendations

**Priority areas for test coverage:**

1. **Swift - DishParserService** (`/Users/alex/projects/Menui/Menui/Services/DishParserService.swift`)
   - Critical business logic with complex filtering rules
   - Many edge cases (section headers, fragments, Mexican dishes)
   - Pure functions ideal for unit testing

2. **Swift - APIService** (`/Users/alex/projects/Menui/Menui/Services/APIService.swift`)
   - Network error handling
   - Response parsing and error cases

3. **Python - API Endpoints** (`/Users/alex/projects/Menui/backend/app/main.py`)
   - `/api/dishes/images` endpoint logic
   - Request validation
   - Error responses

4. **Python - Cache Logic**
   - `get_cached_images()` and `cache_images()` functions
   - Redis connection failures

**Current Testing Status:**
- No test files exist in the codebase
- No test configuration detected
- No CI/CD test automation
- Manual testing only

**To Add Tests:**

For Swift (XCTest):
1. Create `MenuiTests` target in Xcode
2. Add test files mirroring source structure
3. Configure test scheme for code coverage

For Python (pytest):
1. Add to `requirements.txt`: `pytest`, `pytest-asyncio`, `pytest-cov`, `httpx` (for TestClient)
2. Create `backend/tests/` directory
3. Create `conftest.py` for shared fixtures
4. Run with: `pytest backend/tests/`

---

*Testing analysis: 2026-01-20*
