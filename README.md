# Menui

<p align="center">
  <img src="visuals/app-mockup.png" alt="Menui App Mockup" width="800">
</p>

iOS app that scans restaurant menus using OCR and spatial layout analysis, then displays food images for each dish.

**Tech Stack:** SwiftUI + FastAPI + Redis + Google Custom Search + Apple Vision Framework

---

## Features

- Native camera with zoom (.5x/1x) and flash controls
- Spatial layout analysis that understands menu structure (multi-column, centered, boxed layouts)
- Structured menu view with sections, items, descriptions, prices, and modifiers
- Scan history with rename and swipe-to-delete
- On-device OCR via Apple Vision Framework — no menu images sent to the backend
- Redis caching for fast image lookup

---

## Requirements

- macOS with Xcode 15.0 or later
- iOS 18.4+ device or simulator
- Apple Developer account (for physical device testing)

---

## Getting Started

```bash
git clone https://github.com/yourusername/menui.git
open menui/Menui.xcodeproj
```

1. Select the **Menui** target in Xcode
2. Go to **Signing & Capabilities** and choose your development team
3. Run on a simulator or device (Cmd+R)

The app is pre-configured to use the production backend — no additional setup required.

**Local backend:** To run the backend locally, see `backend/README.md` (if present) or set `GOOGLE_API_KEY`, `GOOGLE_SEARCH_ENGINE_ID`, and `REDIS_URL` in `backend/.env`, then run `uvicorn app.main:app --reload`. Switch the base URL in `Menui/Services/APIService.swift` to `http://localhost:8000`.

---

## Privacy

- All OCR processing happens on-device
- No menu images are sent to the backend (only dish names for image lookup)
- No tracking, analytics, or user accounts

---

## License

MIT License — Copyright (c) 2026 Menui
