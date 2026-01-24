# Menui

iOS app that uses advanced OCR and spatial layout analysis to scan restaurant menus, parse menu structure, and display food images for each dish.

**Tech Stack:** SwiftUI + FastAPI + Redis + Google Custom Search + Apple Vision Framework

---

## What's New

### Version 2.0 (Latest)

**Major Features**:
- 🎯 **Advanced MenuParser** - Spatial layout analysis understands menu structure
- 💾 **Scan History** - Save and manage scans with SwiftData
- ✏️ **Rename Sessions** - Organize scans with custom names
- 🗑️ **Swipe-to-Delete** - Easy history management
- 📱 **Native Camera UI** - Professional controls with zoom (.5x/1x) and flash
- 📋 **JSON Export** - Export structured menu data
- 🏷️ **Auto-Tagging** - Extract tags from dish descriptions

**Algorithm Improvements**:
- Multi-column menu detection
- Price anchor strategy for accurate dish pairing
- Burger stack grouping for descriptions
- Section header detection
- Modifier extraction (add-ons)

**See**: [Recent Commits](#recent-commits) below for detailed changelog

---

## Features

### Menu Scanning & Parsing
- 📸 **Native camera interface** with live preview, zoom controls (.5x/1x), and flash
- 🔍 **On-device OCR** using Apple Vision Framework with bounding box detection
- 🧠 **Spatial layout analysis** - Understands menu structure, not just text:
  - Multi-column detection (handles 2-column menus with dotted lines)
  - Centered minimalist layout support
  - Boxed grid menu parsing
- 📋 **Structured JSON export** with sections, items, descriptions, prices, and modifiers
- 🏷️ **Automatic tag extraction** from dish descriptions

### Scan Management
- 💾 **Scan history** with SwiftData persistence
- ✏️ **Rename sessions** to organize your scans
- 🗑️ **Swipe-to-delete** unwanted scan history
- 📱 **Session details view** with full menu structure

### Privacy & Performance
- 🔒 **Privacy-first** - All OCR processing on-device
- ⚡ **Redis caching** for fast image lookup
- 🚀 **No tracking** - No analytics, no user accounts, no data collection

---

## Recent Commits

- **feat: add rename functionality to scan session details** - Users can now rename saved scans
- **feat: complete scan details view implementation** - Full session detail view with menu structure
- **feat: add swipe-to-delete in History tab** - Easy scan management
- **refactor: remove Favorites tab** - Simplified to Scan + History tabs
- **feat: revamp results view with NavigationStack** - Modern navigation patterns
- **feat: implement native iOS camera interface** - Professional camera controls
- **feat: add live camera preview with zoom and flash controls** - Enhanced user experience
- **fix: properly detect ultra-wide camera** - Support for .5x zoom
- **feat: hybrid gesture zoom control** - Tap-to-preset + drag-to-dial

---

## How It Works

```
┌─────────────────────────┐
│   iOS App (SwiftUI)     │
└──────────┬──────────────┘
           │
           ├─► 📸 Native Camera UI (AVFoundation)
           │   • Ultra-wide & wide lens support
           │   • Zoom controls (.5x/1x)
           │   • Flash control
           │
           ├─► 🔍 On-device OCR (Vision Framework)
           │   • Text recognition with bounding boxes
           │   • Spatial layout information
           │
           ├─► 🧠 MenuParser - Spatial Layout Analysis
           │   • Column detection (multi-column support)
           │   • Price anchor strategy
           │   • Burger stack grouping (name + description)
           │   • Section header detection
           │   • Structured JSON output
           │
           ├─► 💾 SwiftData Persistence
           │   • Save scan history
           │   • Session management
           │
           ▼
    [Optional: POST /api/dishes/images]
           │
┌──────────▼──────────┐
│  FastAPI Backend    │
└──────────┬──────────┘
           │
           ├─► Check Redis Cache
           │   (30-day TTL)
           │
           ├─► Google Custom Search API
           │   (on cache miss)
           │
           ▼
    [Image URLs returned]
           │
┌──────────▼──────────┐
│   iOS App displays  │
│   structured menu   │
│   with food images  │
└─────────────────────┘
```

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

---

## App Navigation

Menui has a simple two-tab interface:

### 📸 Scan Tab
- **Native Camera Interface** with professional controls
  - Ultra-wide (.5x) and wide (1x) lens switching
  - Flash toggle (auto/on/off)
  - Live preview with framing guide
- **Instant Processing** - Tap capture to scan menu
- **Structured Results** - View parsed menu with sections, items, and prices
- **JSON Export** - Copy structured menu data

### 🕐 History Tab
- **All Saved Scans** - Browse previous menu scans
- **Rename Sessions** - Tap session name to rename
- **Swipe-to-Delete** - Remove unwanted scans
- **Detail View** - See full menu structure with:
  - Section organization
  - Dish names and prices
  - Descriptions and tags
  - Modifiers and add-ons

---

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

Menui uses a sophisticated **spatial layout analysis** engine to understand menu structure, not just extract text. This goes far beyond simple OCR.

### Key Capabilities

1. **Multi-Column Detection**
   - Automatically detects 2-column menus
   - Handles centered single-column layouts
   - Identifies visual "gutters" between columns

2. **Price Anchor Strategy**
   - Uses prices as reliable anchors to find dish names
   - Scans horizontally and vertically to pair dishes with prices
   - Handles dotted lines (e.g., "Burger ......... $12.99")

3. **Burger Stack Grouping**
   - Associates descriptions below dish names
   - Uses spatial proximity and typography heuristics
   - Handles pipe-separated ingredients (e.g., "wagyu beef | arugula | truffle aioli")

4. **Section Detection**
   - Identifies section headers (APPETIZERS, ENTREES, etc.)
   - Groups items hierarchically under sections
   - Extracts modifiers (Add-ons like "Extra cheese +$1.50")

### Supported Menu Archetypes

✅ **Dense List (Two-Column with Dotted Lines)**
```
APPETIZERS                ENTREES
Nachos ......... $8.99    Burger ......... $12.99
Wings .......... $9.99    Steak .......... $24.99
```

✅ **Minimalist (Centered, Pipe-Separated)**
```
              Artisan Burger
      wagyu beef | arugula | truffle aioli
                  $18.00
```

✅ **Boxed Grid (Bordered Sections)**
```
┌─────────────────┐
│  LUNCH SPECIAL  │
│  - Burrito      │
│  - Tacos        │
│  $6.99          │
└─────────────────┘
```

### Output Format

The MenuParser produces structured JSON:

```json
{
  "menu_sections": [
    {
      "section_name": "Lunch Specials",
      "items": [
        {
          "id": "item_a3f2e891",
          "name": "Special Lunch No. 2",
          "description": "One beef burrito, Mexican rice and refried beans",
          "price": 6.75,
          "tags": ["beef", "burrito", "rice", "beans"],
          "modifiers": [
            {
              "text": "Add guacamole",
              "price": 1.50
            }
          ]
        }
      ]
    }
  ]
}
```

For technical details, see [MENU_PARSER_ALGORITHM.md](./MENU_PARSER_ALGORITHM.md).

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

## Development

### Testing

The project includes comprehensive testing guides:

- **MenuParser Testing**: See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for testing the spatial layout analysis
- **Backend Testing**: See [BACKEND_LOCAL_TESTING.md](./BACKEND_LOCAL_TESTING.md) for local API testing
- **Manual Testing**: Test with various menu types (see MenuParser section above)

**Testing Checklist**:
- ✅ Multi-column menu parsing
- ✅ Centered layout detection
- ✅ Price-dish pairing accuracy
- ✅ Description association
- ✅ Section header detection
- ✅ JSON output validation
- ✅ Scan history persistence
- ✅ Rename functionality
- ✅ Swipe-to-delete

**Future Testing Improvements**:
- Unit tests for MenuParser algorithm
- Integration tests for API endpoints
- UI tests for camera flow
- Snapshot tests for different menu archetypes

### Code Style

**Swift:**
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for linting (optional)

**Python:**
- Follow PEP 8
- Use `black` for formatting
- Maximum line length: 100 characters

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Deployment

### iOS App

**TestFlight / App Store:**
1. Archive the app in Xcode (Product → Archive)
2. Distribute to App Store Connect
3. Configure app metadata and screenshots
4. Submit for review

**Requirements:**
- Apple Developer Program membership ($99/year)
- App signing certificates
- Provisioning profiles

### Backend

The backend is currently deployed on **Render.com**.

**Deployment Steps:**

1. **Create New Web Service** on Render
2. **Connect Repository**
3. **Configure Build Settings:**
   - Build Command: `pip install -r backend/requirements.txt`
   - Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - Root Directory: `backend`
4. **Set Environment Variables:**
   - `GOOGLE_API_KEY`
   - `GOOGLE_SEARCH_ENGINE_ID`
   - `REDIS_URL`
   - `ALLOWED_ORIGINS` (set to iOS app domain)
   - `ADMIN_SECRET`
5. **Deploy**

**Alternative Hosting Options:**
- Railway
- Fly.io
- Heroku
- AWS Elastic Beanstalk
- Google Cloud Run

**CORS Configuration:**
For production, update `ALLOWED_ORIGINS` to restrict access to your iOS app or specific domains.

---

## Privacy & Security

### Privacy First
- **On-device OCR:** All text recognition happens locally on the user's device using Apple's Vision Framework
- **No menu images sent:** Only extracted dish names are sent to the backend
- **No user tracking:** No analytics, no user accounts, no data collection
- **No data storage:** Backend doesn't store user requests (only caches dish → image mappings)

### Security Features
- **API keys secured server-side:** Google API credentials never exposed to clients
- **Rate limiting:** 30 requests/minute per IP prevents abuse
- **Input validation:** Dish names validated (2-100 chars, safe characters only)
- **CORS protection:** Configurable allowed origins
- **Admin endpoints protected:** Cache clearing requires secret key

### Security Best Practices
- Never commit `.env` files to version control
- Use environment variables for all secrets
- Restrict CORS origins in production
- Monitor Google API quota usage
- Keep dependencies updated

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

## Acknowledgments

- **Apple Vision Framework** - Powerful on-device OCR with spatial layout detection
- **SwiftUI & SwiftData** - Modern declarative UI and native persistence
- **AVFoundation** - Professional camera controls and ultra-wide lens support
- **Google Custom Search API** - High-quality food image search
- **FastAPI** - Modern, fast web framework for building APIs
- **Upstash Redis** - Serverless Redis for distributed caching
- **Render.com** - Simple and reliable backend hosting

---

## Documentation

- **[PRD.md](./PRD.md)** - Product requirements and technical specifications
- **[MENU_PARSER_ALGORITHM.md](./MENU_PARSER_ALGORITHM.md)** - MenuParser spatial layout analysis documentation
- **[BACKEND_LOCAL_TESTING.md](./BACKEND_LOCAL_TESTING.md)** - Guide for testing backend API locally
- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - MenuParser testing guide with examples
- **API Documentation:** https://menui-f9n2.onrender.com/docs (interactive Swagger UI)
- **Issues & Feedback:** [GitHub Issues](https://github.com/yourusername/menui/issues)

---

**Built with ❤️ using SwiftUI and FastAPI**
