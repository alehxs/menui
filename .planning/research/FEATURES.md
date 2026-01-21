# Feature Research: History & Timeline for Menu Scanner App

**Domain:** iOS scan history and timeline features
**Researched:** 2026-01-20
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Auto-save every scan | Scanner apps (QR, documents) save history by default. Users don't expect to manually save. | LOW | SwiftData auto-save on scan completion. Critical for session-based model. |
| Newest-first timeline | iOS Photos, Messages, Files all show recent items first. Universal pattern. | LOW | Standard List with `.reversed()` or sort descriptor. |
| Swipe-to-delete sessions | iOS 15+ standard pattern. Users expect trailing swipe = delete. | LOW | `.swipeActions(edge: .trailing)` with delete action. Full swipe auto-triggers. |
| View original menu photo | Document scanners (Adobe Scan, Scanner Pro) always show original. Users validate OCR accuracy. | MEDIUM | Store UIImage or file path in session. Present in detail view with zoom/pan. |
| Timestamp display | Every history feature shows "when" - relative ("2 hours ago") or absolute ("Jan 20, 3:45 PM"). | LOW | Use `RelativeDateTimeFormatter` for recent, `DateFormatter` for older. |
| Empty state for new users | iOS apps show helpful empty states on first use. Never show blank screen. | LOW | Text + icon when history is empty: "No scans yet. Tap Scan to get started." |
| Basic search | Users expect to find things in lists. iOS Mail, Notes, Photos all have search bars. | MEDIUM | `.searchable()` modifier, filter by restaurant name and dish names. |
| Delete confirmation | Destructive actions require confirmation. iOS pattern for preventing accidents. | LOW | `.confirmationDialog()` on delete - "Delete this scan?" |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Edit restaurant names inline | QR/document scanners don't have "venue context". Adding editable names makes history meaningful. | MEDIUM | iOS 16+ `.navigationTitle($restaurantName)` binding. Tap to edit pattern. |
| Group by restaurant | Seeing "all scans from this restaurant" is unique to menu scanning. Builds a personal restaurant guide. | MEDIUM | Computed property grouping sessions by restaurant name. Sectioned List. |
| Filter by date range | "Show me all places I visited last month" - trip planning, expense tracking, memory lane. | MEDIUM | Date picker or preset ranges (Today, This Week, This Month, Custom). |
| Dish-level search | Search across all dishes in all sessions, not just restaurant names. "Where did I see pad thai?" | HIGH | Full-text search across session.dishes array. Needs efficient indexing. |
| Quick Actions (3D Touch) | Long-press session for Share, Delete, Rename without entering detail view. | LOW | `.contextMenu()` with actions. Modern iOS pattern. |
| Share session | Share restaurant name + dish list + images via Messages/Email. Social proof, recommendations. | MEDIUM | `UIActivityViewController` with formatted text + images. Standard iOS sharing. |
| Pin favorite sessions | Pin frequently-visited restaurants to top of list. Quick access pattern. | MEDIUM | Boolean flag on session, custom sort. Similar to iOS Mail pinned messages. |
| Smart grouping | "Restaurants near Times Square" or "Mexican restaurants" using auto-categorization. | HIGH | Requires location data or cuisine detection. Nice-to-have, not critical. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Manual scan saving | "I only want to save some scans" | Creates decision fatigue. Users forget to save, lose data. | Auto-save everything, easy delete. Let users remove unwanted scans. |
| Folders/Collections | "Organize by trip or cuisine" | Adds complexity. Users don't maintain folders consistently. | Use search/filter by date or restaurant. Tags could work but defer to v2. |
| Export to PDF | "Make a report of all dishes" | Over-engineered for personal use. Adds maintenance burden. | Share individual sessions via native iOS sharing. Good enough. |
| Sync to calendar | "Add restaurant visit to Calendar" | Wrong mental model. This isn't an event tracker, it's a memory aid. | Keep focused on dish discovery, not event management. |
| Batch delete | "Delete multiple at once" | Rarely needed. Adds UI complexity (edit mode, selection). | Individual swipe-to-delete is sufficient. Power users can clear all via settings. |
| Undo delete | "I deleted by accident" | Requires tombstoning or recycle bin. Adds complexity. | Good delete confirmation prevents most accidents. |
| Cloud backup | "Don't lose my data" | Scope creep. Requires backend, accounts, sync logic. | Out of scope for v1. Local backup via iCloud device backup is sufficient. |

## Feature Dependencies

```
[Auto-save scans]
    └──requires──> [SwiftData persistence layer]
                       └──requires──> [Session data model]

[Timeline view]
    └──requires──> [Auto-save scans]
    └──requires──> [Session data model]

[Search/filter]
    └──requires──> [Timeline view]
    └──enhances──> [View sessions by restaurant]

[Edit restaurant name]
    └──requires──> [Session data model with editable property]
    └──enhances──> [Timeline view] (shows meaningful names)
    └──enhances──> [Search/filter] (better search results)

[View original photo]
    └──requires──> [Image storage in session]
    └──enhances──> [Timeline view] (visual context)

[Delete sessions]
    └──requires──> [Timeline view]
    └──requires──> [SwiftData deletion]

[Share session]
    └──requires──> [Detail view]
    └──requires──> [Access to session data]
```

### Dependency Notes

- **Timeline view requires auto-save:** Can't show history without saving scans automatically.
- **Search enhances restaurant grouping:** Filtering by name makes "all scans from X restaurant" practical.
- **Edit restaurant name enhances search:** Named sessions are searchable, unnamed sessions are anonymous.
- **Original photo enhances timeline:** Visual thumbnails help users identify sessions faster than text alone.
- **Share requires detail view:** Need to view a session's full content before sharing it.

## MVP Definition

### Launch With (History v1)

Minimum viable history feature — what's needed to validate the "revisit past scans" value prop.

- [x] **Session data model** — ScanSession with timestamp, restaurantName, dishes, images, originalPhoto
- [x] **Auto-save on scan completion** — Every scan creates a session, no manual save button
- [x] **Timeline view (newest first)** — List of sessions, sorted by date descending
- [x] **View session detail** — Tap session → see dishes + images + original photo
- [x] **Edit restaurant name** — Inline rename in detail view (iOS 16+ navigation title binding)
- [x] **Swipe-to-delete sessions** — Standard iOS pattern, trailing swipe
- [x] **Delete confirmation** — Prevent accidental deletion
- [x] **Empty state** — First-use message when no scans exist
- [x] **Basic search** — Filter timeline by restaurant name

### Add After Validation (v1.x)

Features to add once core history is working and users are engaged.

- [ ] **Filter by date range** — Add when users have 20+ scans (trigger: user feedback requesting it)
- [ ] **Dish-level search** — Add when users request "find where I saw X dish" (needs indexing)
- [ ] **Share session** — Add when users ask to share recommendations (low complexity, high delight)
- [ ] **Group by restaurant** — Add when users revisit same restaurants (pattern emerges from usage)
- [ ] **Pin sessions** — Add when power users have 50+ scans (nice-to-have optimization)

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Context menus (long-press)** — Defer until SwiftUI improvements (currently buggy on iOS)
- [ ] **Smart grouping** — Defer until AI/ML makes sense (requires significant engineering)
- [ ] **Export features** — Defer until enterprise/power user demand emerges
- [ ] **Tags/collections** — Defer until users request better organization beyond search

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Auto-save scans | HIGH | LOW | P1 |
| Timeline view | HIGH | LOW | P1 |
| View session detail | HIGH | MEDIUM | P1 |
| Swipe-to-delete | HIGH | LOW | P1 |
| Edit restaurant name | MEDIUM | MEDIUM | P1 |
| Basic search | MEDIUM | MEDIUM | P1 |
| Empty state | MEDIUM | LOW | P1 |
| View original photo | MEDIUM | MEDIUM | P1 |
| Delete confirmation | HIGH | LOW | P1 |
| Share session | MEDIUM | MEDIUM | P2 |
| Filter by date | LOW | MEDIUM | P2 |
| Group by restaurant | LOW | MEDIUM | P2 |
| Dish-level search | MEDIUM | HIGH | P2 |
| Pin sessions | LOW | MEDIUM | P3 |
| Context menus | LOW | LOW | P3 |
| Smart grouping | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch (History v1)
- P2: Should have, add based on usage patterns
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Scanner Apps (Adobe Scan, Genius Scan) | QR Code Apps (QR Reader) | Photo Apps (iOS Photos) | Our Approach |
|---------|----------------------------------------|--------------------------|------------------------|--------------|
| Auto-save | ✓ Every scan saved | ✓ History saved by default | ✓ Every photo saved | ✓ Match standard - auto-save everything |
| Timeline ordering | ✓ Newest first | ✓ Newest first | ✓ Newest first | ✓ Newest first (universal pattern) |
| Swipe actions | ✓ Swipe to delete/share | ✓ Swipe to delete | ✓ Swipe to favorite/delete | ✓ Swipe to delete (iOS standard) |
| Search | ✓ Search by filename/date | ✓ Search scan content | ✓ Search photos, places, people | ✓ Search by restaurant + dishes |
| Empty state | ✓ "No documents yet" | ✓ "Scan your first code" | ✓ "Add photos to get started" | ✓ "No scans yet. Tap Scan." |
| Grouping | ✓ Group by date/folder | ✗ Flat list only | ✓ Group by date/place | ✓ Group by restaurant (unique to our domain) |
| Original image | ✓ Always show original scan | ✗ N/A for QR codes | ✓ Full resolution original | ✓ Show original menu photo |
| Edit metadata | ✓ Rename documents | ✗ Can't edit QR content | ✓ Edit location/date | ✓ Edit restaurant name (our key metadata) |
| Share | ✓ Share PDF/images | ✓ Share QR code/link | ✓ Share photos/albums | ✓ Share session (restaurant + dishes) |
| Filters | ✓ Filter by date/type | ✓ Filter by date | ✓ Filter by date/location/favorites | ✓ Filter by date/restaurant |

**Key insights:**
- Auto-save is universal across all scan/capture apps
- Newest-first timeline is the expected default
- Swipe-to-delete is iOS table stakes
- Search is expected but varies by domain (we need restaurant + dish search)
- Restaurant name editing is our unique metadata (documents have filenames, we have venues)
- Grouping by restaurant is unique to menu scanning (vs. date-based grouping)

## iOS-Specific Patterns

### SwiftUI List Patterns (iOS 15+)

```swift
// Standard timeline with swipe actions
List {
    ForEach(sessions) { session in
        SessionRow(session: session)
    }
    .onDelete(perform: deleteSessions)  // Edit mode deletion
    .swipeActions(edge: .trailing) {    // Swipe-to-delete
        Button(role: .destructive) {
            deleteSession(session)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
.searchable(text: $searchText)  // Native search bar
```

### Navigation Title Editing (iOS 16+)

```swift
// Editable restaurant name in detail view
NavigationStack {
    SessionDetailView(session: session)
        .navigationTitle($session.restaurantName)  // Binding enables edit
}
```

### Empty State Pattern

```swift
// Show when history is empty
if sessions.isEmpty {
    ContentUnavailableView(
        "No Scans Yet",
        systemImage: "camera.viewfinder",
        description: Text("Tap the Scan tab to get started")
    )
}
```

### Relative Date Formatting

```swift
// iOS native relative dates
Text(session.timestamp, format: .relative(presentation: .named))
// Output: "2 hours ago", "Yesterday", "Last week"
```

### Search Implementation

```swift
// Filter sessions by search text
var filteredSessions: [ScanSession] {
    if searchText.isEmpty {
        return sessions
    }
    return sessions.filter { session in
        session.restaurantName.localizedCaseInsensitiveContains(searchText) ||
        session.dishes.contains { $0.localizedCaseInsensitiveContains(searchText) }
    }
}
```

## Sources

**iOS Design Patterns:**
- [SwiftUI List Complete Guide: Move, Delete, Pin & Custom Actions](https://dev.to/swift_pal/swiftui-list-complete-guide-move-delete-pin-custom-actions-2025-edition-429o)
- [SwiftUI Swipe Actions Guide](https://codewithchris.com/swiftui-swipe-actions/)
- [Apple Human Interface Guidelines - Searching](https://developer.apple.com/design/human-interface-guidelines/patterns/searching)
- [Building editable lists with SwiftUI](https://www.swiftbysundell.com/articles/building-editable-swiftui-lists/)

**Scanner App Features:**
- [Top 10 Free Mobile Scanning Apps: Updated for 2026](https://www.securescan.com/articles/records-management/the-best-mobile-scanning-apps-rated/)
- [iOS Document Scanner using Swift - Scanbot SDK](https://scanbot.io/developer/ios-document-scanner/)
- [QR Reader: Scan & Keep History App](https://apps.apple.com/us/app/qr-reader-scan-keep-history/id1505362553)

**Search & Filter Patterns:**
- [UI Patterns For Mobile Apps: Search, Sort And Filter — Smashing Magazine](https://www.smashingmagazine.com/2012/04/ui-patterns-for-mobile-apps-search-sort-filter/)
- [Mobile Design Pattern Gallery: Search, Sort, and Filter](https://www.oreilly.com/library/view/mobile-design-pattern/9781449368586/ch04.html)

**Empty State Design:**
- [Empty State UI Pattern: Best practices & examples | Mobbin](https://mobbin.com/glossary/empty-state)
- [Empty States – The Most Overlooked Aspect of UX | Toptal](https://www.toptal.com/designers/ux/empty-state-ux-design)

**iOS Persistence:**
- [SwiftData: A Comprehensive Guide to Data Persistence](https://medium.com/@srivastavapraveen/swiftdata-a-comprehensive-guide-to-data-persistence-in-ios-with-coredata-c30b338a5810)
- [A complete guide to iOS data persistence](https://byby.dev/ios-persistence)
- [Apple Developer Documentation - Persistent storage](https://developer.apple.com/documentation/swiftui/persistent-storage)

**iOS 26 Features:**
- [Inside Photos in iOS 26 - Apple Insider](https://appleinsider.com/inside/ios-26/tips/inside-photos-in-ios-26-macos-26----refinements-in-apples-image-and-video-management-tool)

---
*Feature research for: Menui History & Timeline*
*Researched: 2026-01-20*
