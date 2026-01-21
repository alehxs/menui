# Menui

## What This Is

An iOS app that scans restaurant menus using on-device OCR and displays food images for each detected dish. Users point their camera at a menu, the app extracts dish names locally, then fetches appetizing food images from the backend.

## Core Value

Users can see what dishes look like before ordering, making menu decisions faster and more confident.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ Camera capture with live preview — v1.0
- ✓ On-device OCR using Apple Vision Framework — v1.0
- ✓ Intelligent dish name extraction and filtering — v1.0
- ✓ Backend API fetches food images via Google Custom Search — v1.0
- ✓ Redis caching with 30-day TTL — v1.0
- ✓ Rate limiting (30 req/min per IP) — v1.0
- ✓ Privacy-first architecture (OCR on-device, no tracking) — v1.0

### Active

<!-- Current scope. Building toward these. -->

- [ ] Save scan sessions to local history
- [ ] Display history timeline (newest first)
- [ ] View saved dishes with images
- [ ] Add/edit restaurant names for scans
- [ ] Search and filter history
- [ ] Delete individual sessions

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Cloud sync / iCloud — Keeping it simple for v1, on-device storage only
- User accounts / authentication — Privacy-first approach, no server-side user data
- Social features / sharing — Focus on personal utility first
- Restaurant database integration — Manual naming is sufficient for now
- Nutrition data / dietary filters — Images are the primary value add

## Context

**Tech Stack:**
- iOS: SwiftUI, AVFoundation, Vision Framework, URLSession
- Backend: FastAPI, Redis (Upstash), Google Custom Search API
- Deployment: iOS app (not yet on App Store), Backend on Render.com

**Current Architecture:**
- iOS app handles camera + OCR locally
- Extracted dish names sent to backend via POST /api/dishes/images
- Backend checks Redis cache, fetches from Google on miss
- No persistence layer yet (history will be first data model)

**User Feedback:**
- Core scanning flow works well
- Users want to revisit past scans
- Restaurant context is valuable (where did I see this dish?)

## Constraints

- **Privacy**: On-device processing, no user tracking, minimal data sent to backend
- **Platform**: iOS 18.4+ only (leveraging latest Vision Framework improvements)
- **API Costs**: Google Custom Search free tier (100 queries/day), Redis free tier sufficient
- **Storage**: On-device only for now (no backend storage, no accounts)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| On-device OCR | Privacy-first, no menu photos leave device | ✓ Good - users trust the app |
| Session-based history | Natural unit = one menu scan at one restaurant | — Pending |
| SwiftData for persistence | Modern Apple framework, replaces CoreData | — Pending |
| Auto-save scans | Reduce friction, users can delete unwanted | — Pending |

---
*Last updated: 2026-01-20 after initial GSD setup*
