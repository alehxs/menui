# Architecture Research: History & Persistence Integration

**Domain:** SwiftUI iOS app with history/persistence features
**Researched:** 2026-01-20
**Confidence:** HIGH

## Current Architecture Analysis

### Existing System (Before History)

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐   │
│  │ CameraView│ │ResultsView│ │MainTabView│ │PlaceholderView│
│  │ (Scan tab)│ │ (Modal)   │ │ (Tabs)    │ │ (History) │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───────────┘   │
│       │ @StateObject │             │                         │
├───────┴──────────────┴─────────────┴─────────────────────────┤
│                       SERVICE LAYER                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────┐ ┌──────────────┐            │
│  │CameraManager │ │OCRService│ │DishParserSvc │            │
│  │(@Observable) │ │          │ │              │            │
│  └──────┬───────┘ └────┬─────┘ └──────┬───────┘            │
│         │              │               │                     │
│  ┌──────┴──────────────┴───────────────┴─────┐              │
│  │            APIService (Singleton)          │              │
│  │     Fetches dish images from backend       │              │
│  └────────────────────────────────────────────┘              │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER                              │
│                    ❌ DOES NOT EXIST                         │
└─────────────────────────────────────────────────────────────┘
```

**Current Data Flow:**
```
Camera Capture → OCR → Parser → API → Results Display
                                          (ephemeral, lost on dismiss)
```

**Key Characteristics:**
- All services instantiated directly in views (@StateObject, direct init)
- No data persistence
- Results exist only during ResultsView lifecycle
- State lives in @State properties, cleared on navigation

## Recommended Architecture with History/Persistence

### Integrated System (With SwiftData)

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │CameraView│  │ResultsView│  │HistoryView│ │SessionDetail│
│  │          │  │           │  │(@Query)   │ │ View       │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬──────┘   │
│       │ @Environment │             │ @Query      │          │
│       │ (modelContext)             │             │          │
├───────┴──────────────┴─────────────┴─────────────┴──────────┤
│                     SERVICE LAYER                            │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────┐ ┌──────────────┐            │
│  │CameraManager │ │OCRService│ │DishParserSvc │            │
│  │(@Observable) │ │          │ │              │            │
│  └──────┬───────┘ └────┬─────┘ └──────┬───────┘            │
│         │              │               │                     │
│  ┌──────┴──────────────┴───────────────┴─────┐              │
│  │            APIService (Singleton)          │              │
│  └────────────────────────────────────────────┘              │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER (NEW)                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │              SwiftData ModelContainer                │    │
│  │                (injected via .modelContainer())      │    │
│  └──────────────────────────────────┬──────────────────┘    │
│                                     │                        │
│  ┌─────────────────┐  ┌─────────────────────────────┐       │
│  │  @Model         │  │  @Model                     │       │
│  │  ScanSession    │  │  DishResult                 │       │
│  │  ─────────────  │  │  ─────────────              │       │
│  │  id             │  │  id                         │       │
│  │  timestamp      │  │  dishName                   │       │
│  │  restaurantName │  │  imageUrls: [String]        │       │
│  │  scanImage: Data│◄─┤  session (relationship)     │       │
│  │  dishes: [Dish] │  │                             │       │
│  └─────────────────┘  └─────────────────────────────┘       │
│         │                                                    │
│         └─ @Relationship(deleteRule: .cascade)              │
└─────────────────────────────────────────────────────────────┘
```

### Enhanced Data Flow

```
[Camera Capture]
    ↓
[OCR Service] → Extract text lines
    ↓
[DishParser Service] → Filter dish names
    ↓
[API Service] → Fetch dish images
    ↓
[ResultsView] → Display + SAVE TO SWIFTDATA
    ↓
[ModelContext.insert()] → Persist ScanSession + DishResults
    ↓
[HistoryView @Query] ← Auto-updates when data changes
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **ScanSession** (@Model) | Owns scan metadata and relationships | SwiftData model with cascade delete to DishResult |
| **DishResult** (@Model) | Owns individual dish data | SwiftData model with inverse relationship to ScanSession |
| **ModelContainer** | Manages SwiftData storage | Configured in MenuiApp with .modelContainer() |
| **ModelContext** | Performs CRUD operations | Injected via @Environment, used in ResultsView to save |
| **@Query** | Declarative data fetching | Used in HistoryView with sorting/filtering |
| **HistoryView** | Lists saved scans | NavigationStack with @Query, searchable, sorted by date |
| **SessionDetailView** | Shows full scan details | Receives ScanSession, displays all dishes + image |

## Recommended Project Structure

```
Menui/
├── Views/
│   ├── CameraView.swift        # Existing - no changes needed
│   ├── CameraPreview.swift     # Existing - no changes needed
│   ├── ResultsView.swift       # MODIFY - add save logic
│   ├── HistoryView.swift       # NEW - replace PlaceholderView
│   ├── SessionDetailView.swift # NEW - drill-down from history
│   └── EditRestaurantSheet.swift # NEW - edit restaurant name
├── Services/
│   ├── CameraManager.swift     # Existing - no changes needed
│   ├── OCRService.swift        # Existing - no changes needed
│   ├── DishParserService.swift # Existing - no changes needed
│   └── APIService.swift        # Existing - no changes needed
├── Models/                     # NEW FOLDER
│   ├── ScanSession.swift       # @Model for scan metadata
│   └── DishResult.swift        # @Model for individual dishes
├── MainTabView.swift           # MODIFY - replace placeholder
└── MenuiApp.swift              # MODIFY - add .modelContainer()
```

### Structure Rationale

- **Models/:** Separate folder for SwiftData models keeps data layer isolated from views
- **Views/:** All UI components, organized by feature (camera, results, history)
- **Services/:** Existing services unchanged - SwiftData integrates at view level, not service level
- **No Repository Pattern:** For this app size, direct SwiftData integration is simpler and idiomatic

## Architectural Patterns

### Pattern 1: Direct SwiftData Integration (Recommended)

**What:** Use @Query, @Model, and ModelContext directly in SwiftUI views without abstraction layer.

**When to use:** Small to medium iOS apps where SwiftData is the only persistence mechanism.

**Trade-offs:**
- ✅ Rapid development, minimal boilerplate
- ✅ SwiftUI automatically updates views when data changes
- ✅ Type-safe queries with #Predicate macro
- ❌ Tight coupling to SwiftData (hard to swap persistence)
- ❌ Less testable (views depend on SwiftData)

**Example:**
```swift
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \ScanSession.timestamp, order: .reverse)
    var sessions: [ScanSession]

    @State private var searchText = ""

    var filteredSessions: [ScanSession] {
        if searchText.isEmpty { return sessions }
        return sessions.filter { session in
            session.restaurantName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredSessions) { session in
                NavigationLink(value: session) {
                    SessionRow(session: session)
                }
            }
            .searchable(text: $searchText, prompt: "Search restaurants")
            .navigationDestination(for: ScanSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }
}
```

### Pattern 2: Save-on-Success Pattern

**What:** Save scan results to SwiftData immediately after successful API fetch, before displaying results.

**When to use:** When you want to persist data as soon as it's available, ensuring no data loss.

**Trade-offs:**
- ✅ No data loss if user dismisses view
- ✅ Simple logic flow
- ❌ Saves even if user doesn't want to keep the scan (could add delete option)

**Example:**
```swift
// In ResultsView.swift
@Environment(\.modelContext) private var modelContext

private func processImage() async {
    // Step 1: OCR
    let ocrLines = await ocrService.recognizeText(from: image)
    dishNames = parserService.extractDishes(from: ocrLines)
    isProcessing = false

    guard !dishNames.isEmpty else { return }

    // Step 2: Fetch images
    isFetchingImages = true
    do {
        dishImages = try await APIService.shared.fetchDishImages(for: dishNames)

        // NEW: Save to SwiftData
        saveScanSession()
    } catch {
        errorMessage = "Failed to load images"
    }
    isFetchingImages = false
}

private func saveScanSession() {
    // Create session
    let session = ScanSession(
        timestamp: Date(),
        scanImage: image.jpegData(compressionQuality: 0.8)
    )

    // Create dishes
    for dishName in dishNames {
        let dish = DishResult(
            dishName: dishName,
            imageUrls: dishImages[dishName] ?? []
        )
        dish.session = session
        session.dishes.append(dish)
    }

    modelContext.insert(session)
    try? modelContext.save()
}
```

### Pattern 3: Cascade Delete with Relationships

**What:** Define one-to-many relationship between ScanSession and DishResult with cascade delete rule.

**When to use:** When child entities (dishes) have no meaning without parent (scan session).

**Trade-offs:**
- ✅ Single delete operation removes session + all dishes
- ✅ Prevents orphaned dish records
- ⚠️ SwiftData cascade delete has known bugs - test thoroughly

**Example:**
```swift
@Model
class ScanSession {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var restaurantName: String?
    @Attribute(.externalStorage) var scanImage: Data?

    // Cascade delete: deleting session deletes all dishes
    @Relationship(deleteRule: .cascade, inverse: \DishResult.session)
    var dishes: [DishResult] = []

    init(timestamp: Date, scanImage: Data?) {
        self.id = UUID()
        self.timestamp = timestamp
        self.scanImage = scanImage
    }
}

@Model
class DishResult {
    @Attribute(.unique) var id: UUID
    var dishName: String
    var imageUrls: [String]
    var session: ScanSession?

    init(dishName: String, imageUrls: [String]) {
        self.id = UUID()
        self.dishName = dishName
        self.imageUrls = imageUrls
    }
}
```

### Pattern 4: Edit Sheet with Binding

**What:** Use .sheet(item:) with @Bindable for editing restaurant name in a modal.

**When to use:** When you need to edit a single property of a SwiftData model.

**Trade-offs:**
- ✅ Changes automatically persist (no explicit save needed)
- ✅ SwiftUI binding handles state synchronization
- ✅ Can use .interactiveDismissDisabled() to prevent accidental loss

**Example:**
```swift
struct SessionDetailView: View {
    @Bindable var session: ScanSession
    @State private var showingEditSheet = false

    var body: some View {
        VStack {
            Button("Edit Restaurant") {
                showingEditSheet = true
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRestaurantSheet(session: session)
        }
    }
}

struct EditRestaurantSheet: View {
    @Bindable var session: ScanSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Restaurant Name", text: $session.restaurantName ?? "")
            }
            .navigationTitle("Edit Restaurant")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

## Data Flow

### Scan Flow (Camera → Results → Persistence)

```
[User taps camera button]
    ↓
[CameraManager.capturePhoto()] → AVCapturePhotoOutput
    ↓
[CameraManager publishes capturedImage] → @Published UIImage?
    ↓
[CameraView observes change] → .onChange(of: cameraManager.capturedImage)
    ↓
[CameraView presents ResultsView] → .fullScreenCover(isPresented:)
    ↓
[ResultsView.task] → processImage()
    ↓
[OCRService.recognizeText()] → [String] (text lines)
    ↓
[DishParserService.extractDishes()] → [String] (filtered dish names)
    ↓
[APIService.fetchDishImages()] → [String: [String]] (dish → image URLs)
    ↓
[ResultsView.saveScanSession()] → modelContext.insert(session)
    ↓
[SwiftData persists to disk]
    ↓
[HistoryView @Query auto-updates] ← Reactive UI update
```

### History Flow (Load → Display → Navigate)

```
[HistoryView appears]
    ↓
[@Query executes] → Fetch all ScanSession sorted by timestamp
    ↓
[List renders SessionRow for each]
    ↓
[User taps row]
    ↓
[NavigationLink(value: session)]
    ↓
[.navigationDestination triggers] → SessionDetailView(session: session)
    ↓
[SessionDetailView displays]
    - Scanned image
    - Restaurant name (editable)
    - List of dishes with images
```

### Edit Flow (Tap → Edit → Persist)

```
[User taps "Edit Restaurant"]
    ↓
[showingEditSheet = true]
    ↓
[.sheet(isPresented:) presents EditRestaurantSheet]
    ↓
[@Bindable var session] → Two-way binding to SwiftData model
    ↓
[User types in TextField] → session.restaurantName updates
    ↓
[SwiftData automatically persists] ← No explicit save needed
    ↓
[User taps "Done"] → dismiss()
    ↓
[Sheet dismisses, SessionDetailView shows updated name]
```

### Key Data Flows

1. **@Environment(\.modelContext):** Injected into views by .modelContainer() modifier in app root. Use for insert/delete/save operations.
2. **@Query reactive updates:** When modelContext.save() or modelContext.insert() is called, any view with @Query automatically re-fetches and re-renders.
3. **@Bindable two-way binding:** Allows TextField to directly modify SwiftData model properties. Changes persist automatically.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k scans | Current approach is perfect. SwiftData handles this easily. |
| 1k-10k scans | Consider pagination in HistoryView using FetchDescriptor with fetchLimit. Add date grouping (Section by day/week). |
| 10k+ scans | Add search indexing. Consider archiving old scans. May need to batch delete or implement data retention policy. |

### Scaling Priorities

1. **First bottleneck:** List rendering with 1k+ items. Solution: Use FetchDescriptor with fetchLimit (e.g., 100 most recent), implement "Load More" button.
2. **Second bottleneck:** Search performance. Solution: Add indexed properties (@Attribute(.indexed)) on restaurantName for faster filtering.
3. **Storage size:** Image data (@Attribute(.externalStorage)) handles large binary data efficiently, but consider image compression or thumbnail generation.

## Anti-Patterns

### Anti-Pattern 1: Creating ModelContext Manually

**What people do:**
```swift
let container = try ModelContainer(for: ScanSession.self)
let context = ModelContext(container)
```

**Why it's wrong:** SwiftUI provides modelContext via environment. Creating manual contexts breaks SwiftData's view update mechanism.

**Do this instead:**
```swift
@Environment(\.modelContext) private var modelContext
```

### Anti-Pattern 2: Not Using .externalStorage for Images

**What people do:**
```swift
@Model
class ScanSession {
    var scanImage: Data? // Stored inline
}
```

**Why it's wrong:** Large binary data stored inline bloats the database and slows queries. Images should be stored externally.

**Do this instead:**
```swift
@Model
class ScanSession {
    @Attribute(.externalStorage) var scanImage: Data?
}
```

### Anti-Pattern 3: Manual Save Calls Everywhere

**What people do:**
```swift
session.restaurantName = "New Name"
try modelContext.save() // Called after every change
```

**Why it's wrong:** SwiftData auto-saves on context changes. Explicit saves are rarely needed and can cause performance issues.

**Do this instead:**
```swift
session.restaurantName = "New Name"
// SwiftData auto-saves. Only call save() if you need to ensure
// persistence before async operation or to catch errors.
```

### Anti-Pattern 4: Filtering in @Query Instead of Computed Property

**What people do:**
```swift
@Query(filter: #Predicate<ScanSession> { session in
    session.restaurantName?.contains(searchText) ?? false
})
var sessions: [ScanSession]
```

**Why it's wrong:** @Query filter is static at initialization. Dynamic filtering (like search) should use computed properties.

**Do this instead:**
```swift
@Query(sort: \ScanSession.timestamp, order: .reverse)
var sessions: [ScanSession]

var filteredSessions: [ScanSession] {
    if searchText.isEmpty { return sessions }
    return sessions.filter { /* search logic */ }
}
```

## Integration Points

### New Component Integration with Existing Architecture

| Integration Point | Pattern | Implementation |
|------------------|---------|----------------|
| **MenuiApp → SwiftData** | Add .modelContainer() | `.modelContainer(for: [ScanSession.self, DishResult.self])` at WindowGroup level |
| **ResultsView → Persistence** | Inject @Environment(\.modelContext) | Add `@Environment(\.modelContext) private var modelContext` property |
| **ResultsView → Save Logic** | Call after API success | Add `saveScanSession()` method called after `fetchDishImages()` succeeds |
| **MainTabView → HistoryView** | Replace PlaceholderView | Swap `PlaceholderView(title: "History")` with `HistoryView()` |
| **HistoryView → Search** | Add .searchable() modifier | Use `@State private var searchText` + `.searchable(text: $searchText)` |
| **SessionDetailView → Edit** | Sheet with @Bindable | Present `EditRestaurantSheet` with `@Bindable var session` parameter |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **Views ↔ SwiftData** | @Query (read), ModelContext (write) | Views directly query/modify models. No repository layer. |
| **ResultsView ↔ HistoryView** | Indirect via SwiftData | No direct communication. Results saves data, History observes via @Query. |
| **CameraView ↔ ResultsView** | Direct (fullScreenCover) | CameraView presents ResultsView with captured image. No persistence interaction. |
| **Services ↔ SwiftData** | None | Services remain stateless. Only views interact with SwiftData. |

## Migration Path (Build Order)

### Phase 1: Data Layer Foundation
1. Create Models/ folder
2. Define ScanSession.swift with @Model macro
3. Define DishResult.swift with @Model macro
4. Add .modelContainer() to MenuiApp.swift
5. **Checkpoint:** Build succeeds, app runs (no UI changes yet)

### Phase 2: Save Integration
6. Modify ResultsView: Add @Environment(\.modelContext)
7. Implement saveScanSession() method
8. Call saveScanSession() after successful API fetch
9. **Checkpoint:** Scans persist (verify via Xcode SwiftData viewer)

### Phase 3: History UI
10. Create HistoryView with @Query
11. Create SessionRow component (list item)
12. Replace PlaceholderView in MainTabView
13. **Checkpoint:** History tab shows saved scans

### Phase 4: Detail & Navigation
14. Create SessionDetailView
15. Add NavigationLink in HistoryView
16. Add .navigationDestination modifier
17. **Checkpoint:** Tap history item shows detail

### Phase 5: Search & Edit
18. Add .searchable() to HistoryView
19. Implement filteredSessions computed property
20. Create EditRestaurantSheet
21. Add edit button + sheet presentation in SessionDetailView
22. **Checkpoint:** Full feature parity

## Known SwiftData Gotchas

### Cascade Delete Issues
- **Issue:** Cascade delete reported as unreliable in some SwiftData versions
- **Mitigation:** Test delete operations thoroughly. Consider manual deletion loop if cascade fails.
- **Reference:** Multiple developer forum reports of cascade delete bugs

### @Query Not Updating
- **Issue:** Views don't refresh when data changes
- **Mitigation:** Ensure @Query is used (not manual fetch). Verify .modelContainer() is at app root, not nested.

### Preview Crashes
- **Issue:** SwiftUI previews crash with SwiftData models
- **Mitigation:** Create in-memory ModelContainer for previews:
```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ScanSession.self, configurations: config)
    return HistoryView()
        .modelContainer(container)
}
```

## Sources

**SwiftData Architecture:**
- [SwiftData Architecture Patterns and Practices - AzamSharp](https://azamsharp.com/2025/03/28/swiftdata-architecture-patterns-and-practices.html)
- [The Art of SwiftData in 2025 - Medium](https://medium.com/@matgnt/the-art-of-swiftdata-in-2025-from-scattered-pieces-to-a-masterpiece-1fd0cefd8d87)
- [Implement SwiftData in SwiftUI using MVVM - Medium](https://medium.com/@dikidwid0/implement-swiftdata-in-swiftui-using-mvvm-architecture-pattern-aa3a9973c87c)
- [Simplified Clean Architecture for SwiftData - Medium](https://medium.com/app-makers/simplified-clean-architecture-for-swiftdata-and-swiftui-new-view-on-clean-architecture-ea250d951bb0)
- [Managing model data in your app - Apple](https://developer.apple.com/documentation/SwiftUI/Managing-model-data-in-your-app)

**Search & Filtering:**
- [SwiftUI Search Bar Best Practices - swiftyplace](https://www.swiftyplace.com/blog/swiftui-search-bar-best-practices-and-examples)
- [How to add a search bar - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-search-bar-to-filter-your-data)
- [Filtering and sorting persistent data - Apple](https://developer.apple.com/documentation/swiftdata/filtering-and-sorting-persistent-data)
- [Dynamically sorting and filtering @Query - Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/dynamically-sorting-and-filtering-query-with-swiftui)

**SwiftUI Patterns:**
- [SwiftUI Navigation in 2026: Finally Fixed - Stackademic](https://blog.stackademic.com/swiftui-navigation-in-2026-finally-fixed-ace2ef63169e)
- [Mastering Navigation in SwiftUI: 2025 Guide - Medium](https://medium.com/@dinaga119/mastering-navigation-in-swiftui-the-2025-guide-to-clean-scalable-routing-bbcb6dbce929)
- [Sheets in SwiftUI explained - SwiftLee](https://www.avanderlee.com/swiftui/presenting-sheets/)
- [Presenting Sheets: Item or Boolean Binding - Swiftjective-C](https://www.swiftjectivec.com/swiftui-sheet-present-item-vs-toggle/)

**Relationships & Cascade Delete:**
- [How to create cascade deletes - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-cascade-deletes-using-relationships)
- [SwiftData and the Mystery of Cascading Deletes - Medium](https://medium.com/@nikolai.nobadi/swiftdata-and-the-mystery-of-cascading-deletes-270530ca3b0c)
- [Relationships with SwiftData, SwiftUI, and @Query - Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/relationships-with-swiftdata-swiftui-and-query)

---
*Architecture research for: Menui iOS app history & persistence integration*
*Researched: 2026-01-20*
