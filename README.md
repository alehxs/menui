# Menui

<p align="center">
  <img src="visuals/app-mockup.png" alt="Menui App Mockup" width="800">
</p>

iOS app that uses advanced OCR and spatial layout analysis to scan restaurant menus, parse menu structure, and display food images for each dish.

**Tech Stack:** SwiftUI + FastAPI + Redis + Google Custom Search + Apple Vision Framework

---

## Features

- 📸 Native camera with zoom (.5x/1x) and flash controls
- 🧠 Spatial layout analysis - understands menu structure (multi-column, centered, boxed layouts)
- 📋 Structured JSON export with sections, items, descriptions, prices, and modifiers
- 💾 Scan history with rename and swipe-to-delete
- 🔍 On-device OCR with Apple Vision Framework
- 🏷️ Automatic tag extraction from descriptions
- ⚡ Redis caching for fast image lookup

---

## How It Works

1. **Camera Capture** - Native iOS camera with zoom/flash controls
2. **OCR + Spatial Analysis** - Vision Framework extracts text with bounding boxes
3. **MenuParser** - Analyzes layout to understand structure (columns, sections, price-dish pairing)
4. **Save & Display** - SwiftData persistence + structured menu view
5. **Image Lookup** (optional) - Backend fetches food images via Google Custom Search (cached in Redis)

---

## Tech Stack

### iOS App
- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Native persistence for scan history
- **AVFoundation** - Camera capture with ultra-wide & wide lens support
- **Vision Framework** - On-device OCR with spatial layout (bounding boxes)
- **URLSession** - Native HTTP client for API calls
- **NavigationStack** - Modern navigation patterns
- **No external dependencies** - 100% native iOS frameworks

### Backend
- **Python 3.8+** - Core language
- **FastAPI** - Modern async web framework
- **Redis** (Upstash) - Distributed caching layer
- **Google Custom Search API** - Image search
- **slowapi** - Rate limiting (30 req/min per IP)
- **httpx** - Async HTTP client

---

## Prerequisites

### iOS Development
- macOS with Xcode 15.0 or later
- iOS 18.4+ device or simulator
- Apple Developer account (for physical device testing)

### Backend Development (Optional - only if running locally)
- Python 3.8 or later
- Redis instance (local or Upstash)
- Google Cloud account with Custom Search API enabled

---

## Quick Start

### iOS App

The iOS app is pre-configured to use the production backend. Just run it!

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/menui.git
cd menui

# 2. Open in Xcode
open Menui.xcodeproj

# 3. Select your development team in Xcode:
#    - Select project in navigator
#    - Go to "Signing & Capabilities"
#    - Choose your team

# 4. Run on device or simulator (⌘R)
```

### Backend (Optional - for local development)

```bash
# 1. Navigate to backend directory
cd backend

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create .env file (see Configuration section below)
cp .env.example .env  # Edit with your API keys

# 5. Run the server
uvicorn app.main:app --reload

# API will be available at http://localhost:8000
# Interactive docs at http://localhost:8000/docs
```


## iOS App Setup (Detailed)

### 1. Clone and Open Project

```bash
git clone https://github.com/yourusername/menui.git
cd menui
open Menui.xcodeproj
```

### 2. Configure Signing

1. Select the **Menui** project in the navigator
2. Select the **Menui** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** from the dropdown
5. Xcode will automatically manage provisioning profiles

### 3. Camera Permissions

The app requires camera access. On first launch, iOS will prompt for permission. The permission description is configured in `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Menui needs camera access to scan restaurant menus</string>
```

### 4. Backend Configuration

**Production (Default):**
The app is configured to use the production backend at `https://menui-f9n2.onrender.com`. No changes needed!

**Local Development:**
To use a local backend, edit `APIService.swift`:

```swift
// Change this line:
private let baseURL = "https://menui-f9n2.onrender.com"

// To this:
private let baseURL = "http://localhost:8000"
```

### 5. Running the App

- **Simulator:** Select any iOS 18.4+ simulator and press ⌘R
- **Physical Device:** Connect device, select it as target, and press ⌘R

**Note:** Camera functionality works best on physical devices. Simulator may have limited camera support.

---

## Backend Setup (Detailed)

### 1. Environment Variables

Create a `.env` file in the `backend/` directory:

```bash
# Required
GOOGLE_API_KEY=your_google_api_key_here
GOOGLE_SEARCH_ENGINE_ID=your_search_engine_id_here

# Redis (use Upstash or local)
REDIS_URL=redis://default:password@host:port

# Optional
ALLOWED_ORIGINS=*  # Use specific domain in production
ADMIN_SECRET=your_secret_key_for_cache_clearing
```

### 2. Environment Variables Reference

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `GOOGLE_API_KEY` | Google Cloud API key with Custom Search enabled | ✅ Yes | - |
| `GOOGLE_SEARCH_ENGINE_ID` | Programmable Search Engine ID | ✅ Yes | - |
| `REDIS_URL` | Redis connection string | ✅ Yes | - |
| `ALLOWED_ORIGINS` | CORS allowed origins (comma-separated) | ❌ No | `*` |
| `ADMIN_SECRET` | Secret for admin endpoints (cache clearing) | ❌ No | `None` |

### 3. Google Custom Search API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Custom Search API**
4. Create credentials (API key)
5. Go to [Programmable Search Engine](https://programmablesearchengine.google.com/)
6. Create a new search engine:
   - Search the entire web
   - Enable Image Search
7. Copy the **Search Engine ID**

**Free Tier:** 100 queries/day

### 4. Redis Setup Options

**Option A: Upstash (Recommended for production)**
1. Sign up at [Upstash](https://upstash.com/)
2. Create a Redis database
3. Copy the connection string
4. Free tier: 10,000 requests/day, 256MB

**Option B: Local Redis**
```bash
# macOS
brew install redis
brew services start redis

# Connection string
REDIS_URL=redis://localhost:6379
```

### 5. Running Locally

```bash
cd backend
source venv/bin/activate  # Activate virtual environment
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Access:**
- API: http://localhost:8000
- Interactive API docs: http://localhost:8000/docs
- Health check: http://localhost:8000/health

---

## Configuration

### Switching iOS App Backend

Edit `Menui/Services/APIService.swift`:

```swift
class APIService {
    static let shared = APIService()

    // Production
    private let baseURL = "https://menui-f9n2.onrender.com"

    // Local development
    // private let baseURL = "http://localhost:8000"

    // iOS Simulator talking to macOS localhost
    // private let baseURL = "http://127.0.0.1:8000"
}
```

### Backend CORS Configuration

For production, restrict CORS to your app's domain. Edit `.env`:

```bash
# Development - allow all
ALLOWED_ORIGINS=*

# Production - restrict to specific origins
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

---

## Project Structure

```
Menui/
├── Menui/                      # iOS app source code
│   ├── Models/                 # Data models
│   │   ├── ScanSession.swift       # SwiftData model for scan history
│   │   └── MenuModels.swift        # Menu parsing models (OCRBlock, MenuItem, etc.)
│   ├── Services/               # Business logic layer
│   │   ├── APIService.swift        # Backend API client
│   │   ├── CameraManager.swift     # Camera capture manager
│   │   ├── OCRService.swift        # Vision Framework OCR with spatial layout
│   │   ├── MenuParser.swift        # Spatial layout analysis engine
│   │   └── DishParserService.swift # Legacy dish name extraction
│   ├── Views/                  # SwiftUI views
│   │   ├── CameraView.swift        # Native camera UI with zoom/flash
│   │   ├── CameraPreview.swift     # Camera preview layer
│   │   ├── CameraFrameGuide.swift  # Visual framing guide overlay
│   │   ├── ResultsView.swift       # Image results display (legacy)
│   │   ├── ResultsViewV2.swift     # Structured menu results with MenuParser
│   │   ├── HistoryView.swift       # Scan history list with swipe-to-delete
│   │   └── ScanSessionDetail.swift # Detailed view of saved scan
│   ├── Assets.xcassets/        # App icons, images
│   ├── Info.plist              # App configuration
│   ├── MenuiApp.swift          # App entry point with SwiftData setup
│   └── MainTabView.swift       # Tab navigation (Scan + History)
│
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py             # API endpoints & app setup
│   │   └── config.py           # Environment configuration
│   ├── requirements.txt        # Python dependencies
│   └── .env                    # Environment variables (not committed)
│
├── Menui.xcodeproj/            # Xcode project files
├── PRD.md                      # Product requirements document
├── README.md                   # This file
├── MENU_PARSER_ALGORITHM.md    # MenuParser technical documentation
├── BACKEND_LOCAL_TESTING.md    # Guide for local backend testing
├── TESTING_GUIDE.md            # MenuParser testing guide
└── .gitignore
```

---

## MenuParser Algorithm

Spatial layout analysis engine that understands menu structure:

**Techniques**:
- Multi-column detection with gutter analysis
- Price anchor strategy for dish-price pairing
- Burger stack grouping (associates descriptions with dishes)
- Section header detection
- Modifier extraction

**Supported Layouts**:
- Two-column with dotted lines
- Centered minimalist
- Boxed grid sections

See [MENU_PARSER_ALGORITHM.md](./MENU_PARSER_ALGORITHM.md) for technical details.

---

## API Endpoints

The backend exposes the following REST API endpoints:

### `GET /health`

Health check endpoint for monitoring.

**Response:**
```json
{
  "status": "ok",
  "redis": "connected"
}
```

### `POST /api/dishes/images`

Fetch image URLs for a list of dish names.

**Request:**
```json
{
  "dishes": ["Pad Thai", "Green Curry", "Spring Rolls"]
}
```

**Response:**
```json
{
  "results": [
    {
      "dish_name": "Pad Thai",
      "image_urls": ["url1.jpg", "url2.jpg", "url3.jpg"],
      "from_cache": true
    },
    {
      "dish_name": "Green Curry",
      "image_urls": ["url1.jpg", "url2.jpg", "url3.jpg"],
      "from_cache": false
    }
  ],
  "total_dishes": 2
}
```

**Rate Limiting:** 30 requests/minute per IP

### `DELETE /api/cache/clear`

Clear the Redis cache (admin only).

**Headers:**
```
X-Admin-Secret: your_admin_secret
```

**Response:**
```json
{
  "status": "success",
  "cleared": 42
}
```

---

## Development & Testing

See testing guides: [TESTING_GUIDE.md](./TESTING_GUIDE.md) and [BACKEND_LOCAL_TESTING.md](./BACKEND_LOCAL_TESTING.md)


---

## Deployment

**iOS**: Archive in Xcode → App Store Connect (requires Apple Developer Program)

**Backend**: Deployed on Render.com (or Railway, Fly.io, etc.)
- Set env vars: `GOOGLE_API_KEY`, `GOOGLE_SEARCH_ENGINE_ID`, `REDIS_URL`
- Start: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

---

## Privacy & Security

- All OCR processing on-device (Apple Vision Framework)
- No menu images sent to backend (only dish names)
- No tracking, analytics, or user accounts
- API keys secured server-side
- Rate limiting (30 req/min per IP)
- CORS protection

---

## License

MIT License

Copyright (c) 2026 Menui

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---


---

## Documentation

- [PRD.md](./PRD.md) - Product requirements
- [MENU_PARSER_ALGORITHM.md](./MENU_PARSER_ALGORITHM.md) - MenuParser technical details
- [BACKEND_LOCAL_TESTING.md](./BACKEND_LOCAL_TESTING.md) - Local backend testing
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Testing guide
- API Docs: https://menui-f9n2.onrender.com/docs
