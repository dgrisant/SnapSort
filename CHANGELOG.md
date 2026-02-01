# Changelog

All notable changes to SnapSort will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Date-based folder organization
- Smart file renaming
- App detection and sorting
- Auto-cleanup of old screenshots
- OCR text extraction
- See [PROJECT_PLAN.md](PROJECT_PLAN.md) for full roadmap

---

## [1.0.0] - 2026-02-01

### Added
- Initial release
- Menu bar app with native macOS menu
- Auto-detect macOS screenshot save location
- Auto-configure Desktop as watch folder
- Auto-create ~/Pictures/Screenshots as destination
- File watching using FSEvents
- Screenshot detection by filename prefix
- Configurable prefixes: Screenshot, Screen Shot, Screen Recording, mac_
- Image validation using magic bytes
- File move with conflict resolution
- **Instant Move** option - disables macOS thumbnail preview for immediate organization
- Enable/Disable toggle
- Move counter (files moved this session)
- Quick access to Screenshots folder
- User notifications when files are moved
- Launch at login support (via SMAppService)

### Technical
- SwiftUI MenuBarExtra for menu bar presence
- Non-sandboxed for direct download distribution
- Minimum macOS 13.0 (Ventura)
- Swift 5.9

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.0 | 2026-02-01 | Initial release |

---

## Upgrade Notes

### From Pre-release to 1.0.0
- First public release, no upgrade path needed

---

[Unreleased]: https://github.com/dgrisant/SnapSort/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/dgrisant/SnapSort/releases/tag/v1.0.0
