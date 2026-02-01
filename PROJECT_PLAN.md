# SnapSort Project Plan

## Overview
SnapSort is a macOS menu bar app that automatically organizes screenshots. This document outlines the development plan for adding advanced organizing features.

---

## Current Features (v1.0) ✅
- [x] Menu bar app (no dock icon)
- [x] Auto-detect macOS screenshot location
- [x] Watch folder for new screenshots
- [x] Move to ~/Pictures/Screenshots
- [x] Instant Move option (skip thumbnail preview)
- [x] Configurable file prefixes
- [x] Enable/Disable toggle
- [x] Quit from menu

---

## Planned Features

### Phase 1: Core Organization ✅
**Target: v1.1** - COMPLETE

#### 1.1 Date-Based Folders ✅
- [x] Organize screenshots into date-based folder structure
- [x] Options:
  - `Year/Month/Day` (e.g., `2026/02/01/`)
  - `Year/Month` (e.g., `2026/02/`)
  - `Year-Month-Day` flat (e.g., `2026-02-01/`)
  - Flat (no subfolders) - current behavior
- [x] Add setting to menu/preferences
- [x] Migrate existing files option ("Reorganize Existing Files" button)

#### 1.2 Smart Rename ✅
- [x] Replace verbose macOS naming with cleaner format
- [x] Naming options:
  - Compact: `2026-02-01_094532.png`
  - Sequential: `Screenshot_001.png`
  - Custom prefix: `{prefix}_{date}_{time}.png`
- [x] Preserve original name option
- [x] Collision handling (append number)

---

### Phase 2: Intelligent Sorting
**Target: v1.2**

#### 2.1 App Detection
- [ ] Detect frontmost app when screenshot is taken
- [ ] Create app-named subfolders: `Screenshots/Safari/`, `Screenshots/Xcode/`
- [ ] Use Accessibility APIs or NSWorkspace
- [ ] Whitelist/blacklist apps
- [ ] Combine with date folders option

#### 2.2 Size/Type Sorting
- [ ] Detect screenshot type:
  - Full screen capture
  - Partial/selection capture
  - Window capture
  - Screen recording
- [ ] Sort into type-based folders
- [ ] Size threshold settings

---

### Phase 3: Maintenance & Cleanup
**Target: v1.3**

#### 3.1 Auto-Cleanup
- [ ] Delete screenshots older than X days
- [ ] Configurable retention: 7, 14, 30, 60, 90 days, or never
- [ ] Move to Trash vs permanent delete
- [ ] Exclude favorited/tagged files
- [ ] Cleanup schedule: daily, weekly, on launch

#### 3.2 Duplicate Detection
- [ ] Detect duplicate screenshots (hash comparison)
- [ ] Options: auto-delete, prompt, ignore
- [ ] Show duplicates in menu for review

---

### Phase 4: Project Management
**Target: v1.4**

#### 4.1 Project Folders
- [ ] Define custom project folders
- [ ] Quick-assign from menu: "Send to → Project A"
- [ ] Keyboard shortcuts for projects
- [ ] Recent projects list
- [ ] Project folder templates

#### 4.2 Tagging System
- [ ] Add color tags to screenshots
- [ ] Filter by tag in Finder
- [ ] Quick-tag from menu
- [ ] Auto-tag rules

---

### Phase 5: Content Intelligence
**Target: v1.5**

#### 5.1 OCR Tagging (Vision Framework)
- [ ] Extract text from screenshots
- [ ] Auto-detect window titles
- [ ] Smart naming based on content
- [ ] Searchable metadata (Spotlight)
- [ ] Language support

#### 5.2 Content Categorization
- [ ] Detect content type: code, text, UI, photo
- [ ] Auto-categorize into folders
- [ ] ML-based classification (Create ML)

---

### Phase 6: Optimization
**Target: v1.6**

#### 6.1 Compression
- [ ] Auto-compress screenshots
- [ ] Format options: PNG, JPG, HEIC, WebP
- [ ] Quality settings (for lossy formats)
- [ ] Size reduction reporting
- [ ] Preserve originals option

#### 6.2 Batch Processing
- [ ] Process existing screenshots
- [ ] Bulk rename
- [ ] Bulk move/organize
- [ ] Progress indicator

---

### Phase 7: Advanced Features
**Target: v2.0**

#### 7.1 Cloud Sync
- [ ] iCloud Drive integration
- [ ] Dropbox support
- [ ] Google Drive support
- [ ] Custom sync folder

#### 7.2 Screenshot History
- [ ] Searchable history view
- [ ] Thumbnail previews
- [ ] Quick actions (open, delete, share)
- [ ] Export history

#### 7.3 Custom Hotkeys
- [ ] Capture + organize in one action
- [ ] Quick-assign to project hotkeys
- [ ] Global hotkey support

---

## Technical Architecture

### Models
```
AppSettings.swift      - User preferences & configuration
OrganizationRule.swift - Rules engine for sorting
Project.swift          - Project folder definitions
Screenshot.swift       - Screenshot metadata model
```

### Services
```
FileWatcherService.swift      - FSEvents monitoring
ScreenshotMoverService.swift  - File moving logic
OrganizationService.swift     - Sorting/organizing logic
OCRService.swift              - Vision framework text extraction
CompressionService.swift      - Image compression
CleanupService.swift          - Auto-delete old files
AppDetectionService.swift     - Frontmost app detection
```

### Views
```
MenuBarView.swift         - Main dropdown menu
PreferencesWindow.swift   - Settings UI (tabbed)
ProjectsView.swift        - Project management UI
HistoryView.swift         - Screenshot history browser
```

---

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Public releases, stable |
| `prod` | Tested features, ready for release |
| `dev`  | Active development |
| `feature/*` | Individual feature branches |

### Workflow
1. Create `feature/feature-name` from `dev`
2. Develop and test feature
3. Merge to `dev` via PR
4. Test in `dev`, then merge to `prod`
5. After QA verification, merge `prod` to `main`
6. Tag release on `main`

---

## Release Schedule

| Version | Features | Target |
|---------|----------|--------|
| v1.0 | Base app | ✅ Complete |
| v1.1 | Date folders, Smart rename | ✅ Complete |
| v1.2 | App detection, Size sorting | Week 3-4 |
| v1.3 | Auto-cleanup, Duplicates | Week 5-6 |
| v1.4 | Projects, Tagging | Week 7-8 |
| v1.5 | OCR, Categorization | Week 9-10 |
| v1.6 | Compression, Batch | Week 11-12 |
| v2.0 | Cloud, History, Hotkeys | Week 13-16 |

---

## Testing Checklist

### For Each Feature
- [ ] Unit tests for service logic
- [ ] UI tests for menu interactions
- [ ] Manual testing on macOS 13, 14, 15
- [ ] Performance testing (large folders)
- [ ] Edge cases (permissions, disk full, etc.)

### Release Checklist
- [ ] All tests passing
- [ ] No memory leaks (Instruments)
- [ ] Code signed
- [ ] Notarized for distribution
- [ ] README updated
- [ ] CHANGELOG updated

---

## Dependencies

- **macOS 13.0+** (Ventura)
- **Swift 5.9+**
- **SwiftUI**
- **Vision Framework** (for OCR)
- **ServiceManagement** (launch at login)
- **UserNotifications**

---

## Notes

- Keep sandbox disabled for direct download version
- Create separate sandboxed version for App Store if needed
- All file operations should be async to prevent UI blocking
- Respect user's Finder tag colors
- Follow Apple HIG for menu bar apps
