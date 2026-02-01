# Claude Findings & Development Log

> **Purpose:** This document tracks all code changes, build failures, issues encountered, and solutions found during development. Claude should update this file when making significant changes or encountering problems.

---

## 🔄 Session State (READ THIS FIRST AFTER COMPACT)

> **IMPORTANT:** After conversation compacting, Claude MUST re-read this file to restore context.

### Last Updated: 2026-02-01 09:55 AM

### Current Status
- **Branch:** `dev`
- **Version:** v1.0 (complete and working)
- **App State:** Fully functional, running from Xcode DerivedData

### What Was Just Completed
- [x] Initial app implementation (all 11 Swift files)
- [x] Fixed MenuBarExtra button click issues (switched to `.menu` style)
- [x] Fixed Preferences window issues (removed, auto-configure instead)
- [x] Added "Instant Move" feature (disables macOS thumbnail preview)
- [x] Fixed shell command execution for toggling screenshot settings
- [x] Created Git repo with main/prod/dev branches
- [x] Pushed to GitHub: https://github.com/dgrisant/SnapSort
- [x] Created PROJECT_PLAN.md with full feature roadmap
- [x] Created this CLAUDE_FINDINGS.md file

### What's Next
- [ ] Phase 1.1: Date-Based Folders
- [ ] Phase 1.1: Smart Rename
- See PROJECT_PLAN.md for full roadmap

### Active Issues
- None currently

### Key Files to Know
| File | Purpose |
|------|---------|
| `SnapSort/App/SnapSortApp.swift` | Main entry, MenuBarExtra |
| `SnapSort/Models/AppSettings.swift` | All settings, quickMoveEnabled |
| `SnapSort/Services/ScreenshotMoverService.swift` | File watching & moving |
| `SnapSort/Views/MenuBarView.swift` | Menu UI |
| `PROJECT_PLAN.md` | Feature roadmap |

### Build & Run
```bash
cd ~/Desktop/SnapSort
xcodebuild -project SnapSort.xcodeproj -scheme SnapSort -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/SnapSort-*/Build/Products/Debug/SnapSort.app
```

---

## Instructions for Claude

### When to Update This File
1. **After fixing a build error** - Document the error and solution
2. **After resolving a runtime issue** - Document symptoms and fix
3. **When making architectural changes** - Explain the why and how
4. **When discovering macOS quirks** - Document for future reference
5. **When a feature doesn't work as expected** - Document the issue and workaround
6. **Before/after conversation compact** - Update Session State section

### Entry Format
```markdown
### [DATE] - Brief Title

**Issue:** Description of the problem
**Cause:** Root cause analysis
**Solution:** What fixed it
**Files Changed:** List of modified files
**Lessons Learned:** Key takeaways
```

---

## Development Log

---

### 2026-02-01 - Initial Project Setup

**Summary:** Created SnapSort macOS menu bar app from scratch.

**Key Decisions:**
- Used `MenuBarExtra` with `.menu` style for native menu behavior
- Disabled sandbox for direct download (enables system settings modification)
- Auto-configure Desktop as watch folder, ~/Pictures/Screenshots as destination
- Used FSEvents via `FileWatcherService` for efficient file monitoring

**Files Created:**
- `SnapSortApp.swift` - App entry point with MenuBarExtra
- `AppDelegate.swift` - Lifecycle management
- `AppSettings.swift` - UserDefaults + settings
- `MovedFile.swift` - File tracking model
- `FileWatcherService.swift` - FSEvents wrapper
- `ScreenshotMoverService.swift` - Move logic
- `NotificationService.swift` - User notifications
- `LaunchAtLoginService.swift` - SMAppService wrapper
- `FileValidator.swift` - Image validation
- `MenuBarView.swift` - Menu UI
- `PreferencesWindow.swift` - Settings UI (unused currently)

---

### 2026-02-01 - MenuBarExtra Button Click Issues

**Issue:** Buttons in MenuBarExtra with `.window` style were not responding to clicks.

**Cause:** `.buttonStyle(.plain)` combined with custom button views in a window-style MenuBarExtra doesn't properly handle click events. The hit testing area was incorrect.

**Attempts That Failed:**
1. Using `Button` with `.buttonStyle(.plain)` - clicks not registered
2. Using `onTapGesture` with `contentShape(Rectangle())` - still not working
3. Creating custom `MenuRowButton` with hover states - still not working

**Solution:** Changed from `.menuBarExtraStyle(.window)` to `.menuBarExtraStyle(.menu)` which uses native macOS menu items. This provides reliable click handling at the cost of less UI customization.

**Files Changed:**
- `SnapSortApp.swift` - Changed menu style
- `MenuBarView.swift` - Simplified to use standard SwiftUI menu components

**Lessons Learned:**
- `.menu` style is more reliable for standard menu bar apps
- `.window` style is better for complex custom UIs but requires careful hit testing
- Native menu items always work; custom views may not

---

### 2026-02-01 - Preferences Window Not Opening

**Issue:** The Preferences button in the menu was not opening the Settings window.

**Cause:** Multiple issues:
1. `NSApp.sendAction(Selector(("showSettingsWindow:")))` selector not working reliably
2. `@Environment(\.openSettings)` only available in macOS 14+
3. `SettingsLink` only available in macOS 14+

**Solution:** Removed the Settings scene entirely for v1.0. Auto-configured sensible defaults so Preferences isn't needed for basic operation. Will revisit for future versions.

**Files Changed:**
- `SnapSortApp.swift` - Removed Settings scene
- `MenuBarView.swift` - Removed Preferences button

**Lessons Learned:**
- SwiftUI Settings scene has inconsistent behavior across macOS versions
- For menu bar apps, consider inline settings or a separate Window scene
- Auto-configuration reduces need for manual preferences

---

### 2026-02-01 - Screenshot Thumbnail Preview Delay

**Issue:** macOS shows a 5-second thumbnail preview before saving screenshots to disk. SnapSort couldn't move files until after this delay.

**Cause:** macOS Mojave+ feature shows preview in corner, holding the file until preview dismisses or user interacts.

**Solution:** Added "Instant Move" option that:
1. Runs `defaults write com.apple.screencapture show-thumbnail -bool false`
2. Reduces move delay from 4s to 0.5s

**Initial Implementation Failed:**
- Using `Process` with `executableURL` didn't work from sandboxed app
- Even after removing sandbox, the process wasn't executing

**Working Implementation:**
```swift
let task = Process()
task.launchPath = "/bin/sh"
task.arguments = ["-c", "defaults write com.apple.screencapture show-thumbnail -bool \(enabled)"]
task.launch()
task.waitUntilExit()
```

**Additional Fix Required:**
- `didSet` doesn't fire during `init`, so setting wasn't applied on app startup
- Added explicit call in init: `if quickMoveEnabled { setScreenshotThumbnailEnabled(false) }`

**Files Changed:**
- `AppSettings.swift` - Added quickMoveEnabled setting and shell command execution
- `ScreenshotMoverService.swift` - Variable delay based on quick mode
- `MenuBarView.swift` - Added toggle for Instant Move
- `SnapSort.entitlements` - Disabled sandbox

**Lessons Learned:**
- Sandboxed apps cannot run shell commands
- `didSet` observers don't fire during initialization
- Use `/bin/sh -c` for more reliable command execution
- System preferences may require process restart to take effect

---

### 2026-02-01 - FSEvents Deprecation Warning

**Issue:** `FSEventStreamScheduleWithRunLoop` was deprecated in macOS 13.0.

**Cause:** Apple deprecated RunLoop-based scheduling in favor of dispatch queues.

**Solution:**
```swift
// Old (deprecated):
FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

// New:
FSEventStreamSetDispatchQueue(stream, dispatchQueue)
```

**Files Changed:**
- `FileWatcherService.swift` - Added dispatch queue, replaced RunLoop scheduling

**Lessons Learned:**
- Always use `FSEventStreamSetDispatchQueue` for macOS 13+
- Create a dedicated dispatch queue for file watching

---

## Known Issues & Workarounds

### Issue: App needs restart after changing Instant Move
**Workaround:** The setting is applied immediately, but the toggle state display may not update. Toggle off/on if needed.

### Issue: Screenshots taken during app launch may be missed
**Workaround:** App processes existing files on startup to catch any missed screenshots.

### Issue: Security-scoped bookmarks not used
**Current State:** App accesses Desktop and Pictures directly without bookmarks since sandbox is disabled.
**Future:** Re-enable sandbox for App Store version and implement proper bookmark handling.

---

## Build Error Reference

### Error: `'SettingsLink' is only available in macOS 14.0 or newer`
**Solution:** Wrap in `if #available(macOS 14.0, *)` or use alternative approach.

### Error: `Cannot find 'X' in scope`
**Cause:** Usually means a file isn't included in the Xcode target or there's a circular dependency.
**Solution:** Check project.pbxproj includes all source files, ensure proper import statements.

### Error: `'main' attribute cannot be used in a module that contains top-level code`
**Cause:** Another file has top-level executable code.
**Solution:** Ensure only one `@main` entry point and no top-level code elsewhere.

### Warning: `Metadata extraction skipped. No AppIntents.framework dependency found.`
**Impact:** None - this is informational. App Intents not used in this project.

---

## Performance Notes

- FSEvents latency set to 0.5s for balance of responsiveness and efficiency
- File validation reads only first 12 bytes (magic number check)
- Processing queue is serial to prevent race conditions
- Main thread used only for UI updates

---

## Testing Notes

### Manual Test Cases
1. Take screenshot with ⌘+Shift+3 → should move to Screenshots folder
2. Take screenshot with ⌘+Shift+4 → should move to Screenshots folder
3. Toggle Instant Move on → thumbnail preview should disappear
4. Toggle Instant Move off → thumbnail preview should return
5. Disable SnapSort → screenshots should stay on Desktop
6. Quit and relaunch → settings should persist
7. Take screenshot while disabled → should not move

### Edge Cases to Test
- Screenshot while destination folder is full
- Screenshot to network drive
- Very large screenshot (high-res display)
- Rapid consecutive screenshots
- Screenshot during app startup

---

## Future Considerations

1. **Sandboxing for App Store:** Will need to re-implement file access with security-scoped bookmarks
2. **Multiple monitors:** Test screenshot detection across displays
3. **Localization:** Screenshot prefix varies by language (e.g., "Capture d'écran" in French)
4. **Screen recordings:** Currently detected by prefix, may need separate handling
