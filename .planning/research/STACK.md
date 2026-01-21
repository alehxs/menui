# Stack Research

**Domain:** iOS Local Data Persistence & History
**Researched:** 2026-01-20
**Confidence:** HIGH

## Recommended Stack

### Core Persistence Framework

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| SwiftData | iOS 17+ | Declarative data modeling & persistence | Modern Swift-native framework perfectly integrated with SwiftUI, minimal boilerplate, automatic context management via @Query property wrapper. iOS 18.4+ supports all features needed for this project. |

**Rationale for SwiftData over CoreData:**
- **SwiftUI Integration**: @Query property wrapper automatically observes changes, triggers view updates, and manages model context lifecycle
- **Type Safety**: Swift macros (@Model, @Attribute) provide compile-time safety vs CoreData's runtime NSManagedObject
- **Simplicity**: No need for NSPersistentContainer boilerplate, NSFetchRequest configuration, or manual NSManagedObjectContext management
- **Sufficient Features**: Project needs basic CRUD, filtering, sorting - all supported by SwiftData without CoreData's complexity
- **Future-Proof**: Apple's actively developed persistence layer for Swift applications

### Image Storage Strategy

| Technology | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| FileManager + Documents | iOS 17+ | Original menu photo persistence | Store full-resolution UIImage captures to Documents directory as JPEG with timestamp-based filenames |
| SwiftData @Attribute(.externalStorage) | iOS 17+ | Thumbnail generation | Store 200x200px thumbnail as Data in model with .externalStorage for memory optimization |
| AsyncImage with URL cache | iOS 17+ | Display dish images from API | Reuse existing AsyncImage implementation - no changes needed, URLSession handles caching automatically |

**Image Storage Decision Matrix:**

| Image Type | Storage Location | Format | Rationale |
|------------|------------------|--------|-----------|
| Original menu photo | FileManager Documents directory | JPEG (0.8 quality) | User data that should persist, needs full resolution for viewing, backed up by iCloud if enabled |
| Thumbnail for history list | SwiftData with .externalStorage | Data (PNG 200x200) | Memory-optimized loading for scrolling lists, SwiftData loads only when visible |
| Dish images from API | URLSession cache (default) | Remote URLs only | Already cached by URLSession.shared, no persistence needed (can refetch from backend) |

### Search & Filter

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftData #Predicate | iOS 17+ | Filter history by restaurant name, date range | Use for programmatic filtering in FetchDescriptor |
| SwiftUI .searchable() | iOS 15+ | Add search bar to history view | Use for user-facing text search with automatic debouncing |
| FetchDescriptor with sortBy | iOS 17+ | Sort history by date (newest first) | Use instead of Query array .sorted() for performance |

### Supporting Libraries

**None Required** - All functionality achievable with iOS SDK frameworks:
- Foundation (FileManager, Date, UUID)
- SwiftUI (searchable, List, NavigationStack)
- SwiftData (persistence layer)
- UIKit (UIImage bridging for camera)

## Installation

**No external dependencies required.** SwiftData is part of iOS SDK 17.0+.

### Xcode Configuration

1. **Minimum Deployment Target**: Already set to iOS 18.4+ (current project requirement)
2. **SwiftData Framework**: Auto-linked by Xcode 15+, no manual framework addition needed
3. **App Storage Entitlements**: No additional entitlements required for local-only persistence

### Project Setup

```swift
// Add to MenuiApp.swift
import SwiftData

@main
struct MenuiApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: ScanSession.self)
    }
}
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SwiftData | CoreData | If you need heavyweight migrations, complex predicates with subqueries, or fetched results controllers. Not needed for this project. |
| FileManager Documents | SwiftData .externalStorage for originals | NEVER - iOS 18 has memory leak bug where .externalStorage loads unnecessarily, and original photos are too large (2-5MB) for database storage |
| SwiftUI .searchable() | Custom search TextField + onChange | If you need search behavior incompatible with .searchable() placement (not the case here) |
| @Query | Manual FetchDescriptor + modelContext.fetch() | If you need to fetch outside of SwiftUI views (e.g., in async tasks). For view-driven queries, @Query is superior. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| CoreData for new SwiftUI projects | Requires NSManagedObjectContext boilerplate, NSFetchRequest configuration, manual KVO observation. 20-year-old API designed for Objective-C, not Swift. | SwiftData - designed for Swift concurrency and SwiftUI property wrappers |
| Storing images as Data in SwiftData models WITHOUT .externalStorage | Loads entire image data into memory even when not displayed, causes memory bloat on large datasets | Use .externalStorage attribute OR store in FileManager and save file path only |
| .externalStorage for original photos in iOS 18 | [Known iOS 18 bug](https://developer.apple.com/forums/thread/761522) - properties marked .externalStorage load unnecessarily, consuming excessive memory | FileManager Documents directory with file path stored in model |
| UserDefaults for structured data | Limited to Property List types, no querying, 4MB practical limit, synchronous I/O blocks main thread | SwiftData for structured queryable data |
| Realm | Third-party dependency, requires CocoaPods/SPM, migration complexity if switching, not optimized for SwiftUI @Query patterns | SwiftData - first-party, zero dependencies, native SwiftUI integration |
| JSON files in Documents | Manual serialization, no indexing, no querying, full file reads for partial data access | SwiftData provides indexed queries and lazy loading |

## Stack Patterns by Use Case

### Pattern 1: History List (Read Performance Priority)

**Use:**
- @Query with FetchDescriptor and #Predicate for filtering
- Thumbnail from SwiftData with .externalStorage
- FetchDescriptor.sortBy for date ordering

**Because:**
- @Query automatically observes changes and updates view
- Thumbnails load on-demand as user scrolls (memory efficient)
- Sorting via FetchDescriptor is SQL-level, faster than Swift array .sorted()

### Pattern 2: Scan Detail View (Full Image Display)

**Use:**
- FileManager to load original photo from Documents directory
- SwiftData relationship to fetch associated dishes
- Existing AsyncImage for dish images (remote URLs)

**Because:**
- Full resolution photo only loads when detail view appears
- Relationship loading is lazy, dishes fetch when accessed
- No changes needed to existing dish image display logic

### Pattern 3: Search & Filter (Dynamic Query)

**Use:**
- .searchable() modifier on history List
- Computed property that creates filtered @Query predicate
- SwiftUI @State for search text and filter selections

**Because:**
- .searchable() provides native search UI with keyboard handling
- Predicate rebuilds automatically when search text changes
- No manual view refresh needed, SwiftUI observes @Query changes

## SwiftData Model Design

### Data Model Structure

```swift
import SwiftData
import Foundation

@Model
final class ScanSession {
    var id: UUID
    var timestamp: Date
    var restaurantName: String
    var originalPhotoPath: String  // FileManager path, not Data
    @Attribute(.externalStorage) var thumbnail: Data?  // 200x200 PNG

    @Relationship(deleteRule: .cascade) var dishes: [Dish]

    init(timestamp: Date, restaurantName: String, originalPhotoPath: String, thumbnail: Data?) {
        self.id = UUID()
        self.timestamp = timestamp
        self.restaurantName = restaurantName
        self.originalPhotoPath = originalPhotoPath
        self.thumbnail = thumbnail
        self.dishes = []
    }
}

@Model
final class Dish {
    var name: String
    var imageUrls: [String]  // Remote URLs from API, store as String array

    @Relationship(inverse: \ScanSession.dishes) var session: ScanSession?

    init(name: String, imageUrls: [String]) {
        self.name = name
        self.imageUrls = imageUrls
    }
}
```

**Design Decisions:**
- **originalPhotoPath as String, not Data**: Avoids iOS 18 .externalStorage bug, keeps database lightweight
- **thumbnail with .externalStorage**: Small enough (40KB PNG) to benefit from lazy loading without iOS 18 bug impact
- **imageUrls as [String]**: API returns URLs, no need to download and store images locally (backend has caching)
- **Cascade delete**: Deleting session removes associated dishes automatically
- **UUID for id**: Stable identifier for SwiftUI List, Identifiable conformance
- **No @Unique**: Multiple scans can have same restaurant name, timestamp is unique enough

### File System Paths

```swift
// Original photos
Documents/MenuPhotos/
  2026-01-20_14-30-45_UUID.jpg
  2026-01-20_15-22-10_UUID.jpg

// SwiftData database (managed by system)
Library/Application Support/default.store
Library/Application Support/default.store-shm
Library/Application Support/default.store-wal
Library/Application Support/.default.store_SUPPORT/
```

**Path Strategy:**
- **MenuPhotos subdirectory**: Organize photos separately from other potential Documents files
- **Timestamp + UUID naming**: Timestamp for human readability, UUID for uniqueness
- **JPEG format**: iOS camera captures are JPEG, maintain format for compatibility

## Version Compatibility

| SwiftData Feature | iOS Version | Notes |
|------------------|-------------|-------|
| @Model macro | iOS 17.0+ | Core functionality, stable across all iOS 17+ |
| @Attribute(.externalStorage) | iOS 17.0+ | [iOS 18.0-18.2 memory leak bug](https://developer.apple.com/forums/thread/761522), mitigated by using only for small thumbnails |
| #Predicate macro | iOS 17.0+ | Type-safe predicate construction |
| @Query property wrapper | iOS 17.0+ | Automatic context observation |
| FetchDescriptor | iOS 17.0+ | Programmatic query construction |
| #Unique macro | iOS 18.0+ | NOT NEEDED for this project |
| #Expression macro | iOS 18.0+ | NOT NEEDED for this project |
| Custom data stores | iOS 18.0+ | NOT NEEDED for this project |

**iOS 18.4+ Compatibility:**
- All required SwiftData features are stable and available
- .externalStorage bug remains unfixed as of iOS 18.4, workaround: use FileManager for large files
- No iOS 18.4-specific SwiftData features needed for this project

## Known Issues & Mitigations

### iOS 18 .externalStorage Memory Leak

**Issue:** Properties marked with @Attribute(.externalStorage) load unnecessarily when parent object loads, consuming excessive memory.

**Affected Code:**
```swift
@Model class ScanSession {
    @Attribute(.externalStorage) var originalPhoto: Data?  // BAD - loads even when not displayed
}
```

**Mitigation:**
```swift
@Model class ScanSession {
    var originalPhotoPath: String  // GOOD - store path, load via FileManager only when needed
    @Attribute(.externalStorage) var thumbnail: Data?  // OK - small size (40KB) acceptable
}
```

**Source:** [Apple Developer Forums - SwiftData on iOS 18 extreme memory](https://developer.apple.com/forums/thread/761522)

### SwiftData Auto-Save Frequency Reduced in iOS 18

**Issue:** Auto-save doesn't trigger as frequently as iOS 17, may lose data if app crashes before save.

**Mitigation:**
```swift
// Explicit save after critical operations
try? modelContext.save()
```

**When to Explicit Save:**
- After completing scan (saving ScanSession)
- After editing restaurant name
- After deleting sessions

**Source:** [Apple Developer Forums - iOS 18 SwiftData issues](https://developer.apple.com/forums/thread/757521)

## Performance Optimization Guidelines

### Query Performance

| Operation | Slow Approach | Fast Approach |
|-----------|---------------|---------------|
| Count items | `sessions.count` on @Query array | `modelContext.fetchCount(FetchDescriptor<ScanSession>())` |
| Filter by date | `sessions.filter { $0.timestamp > date }` | `@Query(filter: #Predicate { $0.timestamp > date })` |
| Sort by date | `sessions.sorted { $0.timestamp > $1.timestamp }` | `FetchDescriptor(sortBy: [SortDescriptor(\\.timestamp, order: .reverse)])` |

### Memory Management

1. **Use .externalStorage for thumbnails** - SwiftData loads only when view displays thumbnail
2. **Store original photo paths, not Data** - Load full resolution only in detail view
3. **Don't store remote dish images** - Keep URLs only, let URLSession cache handle image data
4. **Limit @Query results** - Use FetchDescriptor with fetchLimit if displaying recent N sessions

### Recommended Thresholds

- **Thumbnail size**: 200x200 pixels, PNG format, ~40KB per thumbnail
- **Original photo**: JPEG quality 0.8, ~2-5MB per photo
- **Query limit for initial load**: Fetch 50 most recent sessions, pagination if needed
- **Search debounce**: 300ms (built into .searchable() modifier)

## Sources

### HIGH Confidence (Official Documentation & Developer Forums)
- [SwiftData Official Documentation](https://developer.apple.com/documentation/swiftdata) - Framework overview, API reference (WebFetch attempted, requires JavaScript)
- [WWDC24 Session 10137: What's New in SwiftData](https://developer.apple.com/videos/play/wwdc2024/10137/) - iOS 18 features, #Unique macro, custom data stores
- [Apple Developer Forums - SwiftData iOS 18 Memory Issues](https://developer.apple.com/forums/thread/761522) - .externalStorage bug confirmation
- [Apple Developer Forums - Best Practices for Storing Images](https://developer.apple.com/forums/thread/761801) - Image storage recommendations
- [HackingWithSwift - SwiftData vs Core Data](https://www.hackingwithswift.com/quick-start/swiftdata/swiftdata-vs-core-data) - Feature comparison
- [FatBobMan - Key Considerations Before Using SwiftData](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) - Limitations, performance, cloud sync realities

### MEDIUM Confidence (Community Best Practices, 2025-2026)
- [Core Data vs SwiftData in 2025](https://distantjob.com/blog/core-data-vs-swiftdata/) - Decision matrix
- [SwiftData Image Storage](https://tanaschita.com/20231127-swift-data-images/) - .externalStorage patterns
- [HackingWithSwift - Optimize SwiftData Performance](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-optimize-the-performance-of-your-swiftdata-apps) - FetchDescriptor best practices
- [HackingWithSwift - Filter SwiftData with Predicates](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-filter-swiftdata-results-with-predicates) - #Predicate usage
- [SwiftUI Searchable Modifier](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-search-bar-to-filter-your-data) - Search implementation
- [iOS File System Guide](https://tanaschita.com/20221010-quick-guide-on-the-ios-file-system/) - Documents vs Caches directory

### LOW Confidence (Unverified WebSearch Results)
- Multiple Medium blog posts on SwiftData patterns - practical examples but not authoritative
- Stack Overflow SwiftData discussions - community solutions, verify before use

---
*Stack research for: Menui History & Persistence*
*Researched: 2026-01-20*
*Milestone: Local scan history with search/filter*
