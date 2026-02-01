# SnapSort Developer Guide

This guide provides comprehensive documentation for developers working on SnapSort.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Build & Run](#build--run)
5. [Configuration](#configuration)
6. [Adding New Features](#adding-new-features)
7. [Testing](#testing)
8. [Debugging](#debugging)
9. [Release Process](#release-process)

---

## Architecture Overview

SnapSort is a native macOS menu bar application built with SwiftUI. It uses a service-oriented architecture with clear separation of concerns.

```
┌─────────────────────────────────────────────────────────┐
│                      SwiftUI Layer                       │
│  ┌─────────────────┐  ┌─────────────────────────────┐   │
│  │  SnapSortApp    │  │      MenuBarView            │   │
│  │  (MenuBarExtra) │  │  (User Interface)           │   │
│  └────────┬────────┘  └──────────────┬──────────────┘   │
│           │                          │                   │
├───────────┼──────────────────────────┼───────────────────┤
│           ▼                          ▼                   │
│  ┌─────────────────────────────────────────────────┐    │
│  │              AppSettings (ObservableObject)      │    │
│  │         - UserDefaults persistence               │    │
│  │         - Security-scoped bookmarks              │    │
│  │         - System preference integration          │    │
│  └─────────────────────────────────────────────────┘    │
│                          │                               │
├──────────────────────────┼───────────────────────────────┤
│                          ▼                               │
│  ┌─────────────────────────────────────────────────┐    │
│  │                 Service Layer                    │    │
│  │  ┌───────────────┐  ┌─────────────────────────┐ │    │
│  │  │FileWatcher    │  │ScreenshotMover          │ │    │
│  │  │Service        │──│Service                  │ │    │
│  │  │(FSEvents)     │  │(Move Logic)             │ │    │
│  │  └───────────────┘  └─────────────────────────┘ │    │
│  │  ┌───────────────┐  ┌─────────────────────────┐ │    │
│  │  │Notification   │  │LaunchAtLogin            │ │    │
│  │  │Service        │  │Service                  │ │    │
│  │  └───────────────┘  └─────────────────────────┘ │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                    Utilities Layer                       │
│  ┌─────────────────────────────────────────────────┐    │
│  │  FileValidator - Magic byte image validation     │    │
│  └─────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### Design Principles

1. **Singleton Services** - Core services use shared instances for app-wide state
2. **Observable Pattern** - SwiftUI bindings via `@Published` and `ObservableObject`
3. **Async File Operations** - All file I/O on background queues
4. **Fail Gracefully** - Never crash on file system errors

---

## Project Structure

```
SnapSort/
├── SnapSort.xcodeproj/
│   └── project.pbxproj          # Xcode project configuration
├── SnapSort/
│   ├── App/
│   │   ├── SnapSortApp.swift    # @main entry point, MenuBarExtra
│   │   └── AppDelegate.swift    # NSApplicationDelegate, lifecycle
│   ├── Models/
│   │   ├── AppSettings.swift    # Settings, UserDefaults, bookmarks
│   │   └── MovedFile.swift      # File tracking model
│   ├── Services/
│   │   ├── FileWatcherService.swift      # FSEvents directory monitoring
│   │   ├── ScreenshotMoverService.swift  # File detection & moving
│   │   ├── NotificationService.swift     # User notifications
│   │   └── LaunchAtLoginService.swift    # SMAppService wrapper
│   ├── Views/
│   │   ├── MenuBarView.swift             # Main menu UI
│   │   └── PreferencesWindow.swift       # Settings window (reserved)
│   ├── Utilities/
│   │   └── FileValidator.swift           # Image validation
│   ├── Info.plist                        # App configuration
│   └── SnapSort.entitlements             # Sandbox & permissions
├── docs/
│   └── DEVELOPER_GUIDE.md                # This file
├── .gitignore
├── README.md
├── LICENSE
└── PROJECT_PLAN.md                       # Feature roadmap
```

---

## Core Components

### SnapSortApp.swift

The main entry point using SwiftUI's `@main` attribute.

```swift
@main
struct SnapSortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var screenshotMover = ScreenshotMoverService.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appSettings)
                .environmentObject(screenshotMover)
        } label: {
            Image(systemName: appSettings.isEnabled ? "photo.on.rectangle.angled" : "photo")
        }
        .menuBarExtraStyle(.menu)
    }
}
```

**Key Points:**
- Uses `MenuBarExtra` for menu bar presence (macOS 13+)
- `.menuBarExtraStyle(.menu)` for native menu behavior
- Environment objects for dependency injection

### AppSettings.swift

Central configuration management with persistence.

```swift
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var isEnabled: Bool
    @Published var quickMoveEnabled: Bool
    @Published var watchFolderURL: URL?
    @Published var destinationFolderURL: URL?
    @Published var filePrefixes: [String]
    @Published var showNotifications: Bool
    @Published var launchAtLogin: Bool
}
```

**Responsibilities:**
- Persist settings to `UserDefaults`
- Manage security-scoped bookmarks for folder access
- Auto-configure defaults on first launch
- Toggle macOS screenshot thumbnail preview

### FileWatcherService.swift

Efficient directory monitoring using FSEvents.

```swift
class FileWatcherService {
    weak var delegate: FileWatcherDelegate?
    private var eventStream: FSEventStreamRef?

    func start() {
        // Create FSEventStream with callback
        // Schedule on dispatch queue
    }

    func stop() {
        // Stop and invalidate stream
    }
}
```

**Key Points:**
- Uses `FSEventStreamSetDispatchQueue` (not deprecated RunLoop method)
- Latency: 0.5 seconds for balance of responsiveness and efficiency
- Filters for file creation/modification events only

### ScreenshotMoverService.swift

Core business logic for detecting and moving screenshots.

```swift
class ScreenshotMoverService: ObservableObject, FileWatcherDelegate {
    static let shared = ScreenshotMoverService()

    @Published var isWatching = false
    @Published var movedCount = 0

    func startWatching() { }
    func stopWatching() { }
    func processFile(at url: URL) { }
    func moveFile(at sourceURL: URL) { }
}
```

**Processing Flow:**
1. File detected by `FileWatcherService`
2. Check if filename matches configured prefixes
3. Validate file is an image (magic bytes)
4. Wait for delay (0.5s quick mode, 4s normal mode)
5. Move to destination with conflict resolution
6. Send notification if enabled

---

## Build & Run

### Prerequisites

- macOS 13.0+
- Xcode 15.0+
- Apple Developer account (for signing)

### Development Build

```bash
# Clone repository
git clone https://github.com/dgrisant/SnapSort.git
cd SnapSort

# Build debug version
xcodebuild -project SnapSort.xcodeproj \
           -scheme SnapSort \
           -configuration Debug \
           build

# Run the app
open ~/Library/Developer/Xcode/DerivedData/SnapSort-*/Build/Products/Debug/SnapSort.app
```

### Release Build

```bash
xcodebuild -project SnapSort.xcodeproj \
           -scheme SnapSort \
           -configuration Release \
           build
```

### Quick Commands

```bash
# Kill running instance and rebuild
pkill -x SnapSort; xcodebuild -project SnapSort.xcodeproj -scheme SnapSort build

# Check for build errors only
xcodebuild -project SnapSort.xcodeproj -scheme SnapSort build 2>&1 | grep -E "(error:|warning:|BUILD)"
```

---

## Configuration

### Info.plist Settings

| Key | Value | Purpose |
|-----|-------|---------|
| `LSUIElement` | `YES` | Hide dock icon (menu bar only) |
| `LSMinimumSystemVersion` | `13.0` | Minimum macOS version |
| `CFBundleIdentifier` | `com.snapsort.app` | Bundle identifier |

### Entitlements

Current entitlements (non-sandboxed for direct download):

```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
```

For App Store (sandboxed):
```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
</dict>
```

### UserDefaults Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `isEnabled` | Bool | `true` | Main on/off toggle |
| `quickMoveEnabled` | Bool | `false` | Skip thumbnail preview |
| `watchFolderBookmark` | Data | nil | Security-scoped bookmark |
| `destinationFolderBookmark` | Data | nil | Security-scoped bookmark |
| `filePrefixes` | [String] | See below | Filename prefixes to match |
| `showNotifications` | Bool | `true` | Show move notifications |
| `launchAtLogin` | Bool | `false` | Start at login |

Default prefixes: `["Screenshot", "Screen Shot", "Screen Recording", "mac_"]`

---

## Adding New Features

### Step 1: Create Feature Branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/your-feature-name
```

### Step 2: Implement the Feature

1. **Add settings** in `AppSettings.swift` if needed
2. **Create service** in `Services/` if complex logic
3. **Update UI** in `MenuBarView.swift`
4. **Add utilities** in `Utilities/` if reusable

### Step 3: Follow Patterns

**Adding a new setting:**
```swift
// In AppSettings.swift

// 1. Add key
private enum Keys {
    static let myNewSetting = "myNewSetting"
}

// 2. Add published property
@Published var myNewSetting: Bool {
    didSet {
        defaults.set(myNewSetting, forKey: Keys.myNewSetting)
    }
}

// 3. Initialize in init()
self.myNewSetting = defaults.bool(forKey: Keys.myNewSetting)
```

**Adding a new service:**
```swift
// In Services/MyNewService.swift

class MyNewService: ObservableObject {
    static let shared = MyNewService()

    @Published var someState: Bool = false

    private init() { }

    func doSomething() {
        // Implementation
    }
}
```

### Step 4: Test & Commit

```bash
# Build and test
xcodebuild -project SnapSort.xcodeproj -scheme SnapSort build

# Commit with descriptive message
git add .
git commit -m "Add feature: description

- Detail 1
- Detail 2

Co-Authored-By: Your Name <email>"
```

### Step 5: Create Pull Request

```bash
git push origin feature/your-feature-name
gh pr create --base dev --title "Feature: Your Feature" --body "Description"
```

---

## Testing

### Manual Test Cases

| Test | Steps | Expected |
|------|-------|----------|
| Basic move | Take screenshot (⌘+Shift+4) | File moves to Screenshots folder |
| Instant mode | Enable Instant Move, take screenshot | No thumbnail, immediate move |
| Disable | Toggle off, take screenshot | File stays on Desktop |
| Notification | Enable notifications, take screenshot | Notification appears |
| Quit | Click Quit | App terminates |

### Edge Cases to Test

- Screenshot while destination folder doesn't exist
- Rapid consecutive screenshots
- Very large screenshot (5K display)
- Screenshot during app startup
- Disk full scenario
- Permission denied scenario

### Performance Testing

Use Instruments to check for:
- Memory leaks
- CPU usage during idle
- File system activity

---

## Debugging

### Common Issues

**App doesn't appear in menu bar:**
- Check `LSUIElement` is `YES` in Info.plist
- Verify app is actually running: `pgrep -x SnapSort`

**Screenshots not moving:**
- Check Console.app for errors
- Verify watch folder path: `defaults read com.snapsort.app`
- Check file prefix matches

**Instant Move not working:**
- Verify setting applied: `defaults read com.apple.screencapture show-thumbnail`
- May need to toggle off/on

### Logging

Add debug logging:
```swift
#if DEBUG
print("[SnapSort] Debug message: \(variable)")
#endif
```

View logs:
```bash
log stream --predicate 'subsystem == "com.snapsort.app"' --level debug
```

---

## Release Process

### 1. Version Bump

Update in `Info.plist`:
- `CFBundleShortVersionString` (e.g., "1.1")
- `CFBundleVersion` (e.g., "2")

### 2. Build Release

```bash
xcodebuild -project SnapSort.xcodeproj \
           -scheme SnapSort \
           -configuration Release \
           -archivePath ./build/SnapSort.xcarchive \
           archive
```

### 3. Code Sign & Notarize

```bash
# Export for distribution
xcodebuild -exportArchive \
           -archivePath ./build/SnapSort.xcarchive \
           -exportPath ./build \
           -exportOptionsPlist ExportOptions.plist

# Notarize
xcrun notarytool submit ./build/SnapSort.app --wait
```

### 4. Create Release

```bash
# Merge to prod, then main
git checkout prod
git merge dev
git push origin prod

git checkout main
git merge prod
git push origin main

# Tag release
git tag -a v1.1 -m "Release v1.1"
git push origin v1.1

# Create GitHub release
gh release create v1.1 ./build/SnapSort.zip --title "v1.1" --notes "Release notes"
```

---

## Code Style

### Swift Style Guide

- Use Swift's official API design guidelines
- 4 spaces for indentation
- Max line length: 120 characters
- Use `// MARK: -` for section organization

### Commit Messages

```
Type: Short description (50 chars max)

Longer description if needed. Wrap at 72 characters.

- Bullet points for multiple changes
- Another change

Co-Authored-By: Name <email>
```

Types: `Add`, `Fix`, `Update`, `Remove`, `Refactor`, `Docs`

---

## Resources

- [Apple Human Interface Guidelines - Menu Bar](https://developer.apple.com/design/human-interface-guidelines/menu-bar-extras)
- [FSEvents Programming Guide](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [App Sandbox Design Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/)
