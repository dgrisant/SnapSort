# SnapSort

A lightweight macOS menu bar app that automatically organizes your screenshots.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Auto-organize** - Screenshots are automatically moved from Desktop to an organized folder
- **Instant Move** - Optional setting to skip the macOS thumbnail preview for immediate organization
- **Smart Detection** - Automatically detects your macOS screenshot save location
- **Menu Bar App** - Runs quietly in your menu bar, no dock icon
- **Lightweight** - Minimal resource usage with efficient file system monitoring

## Installation

### Direct Download
1. Download the latest release from [Releases](https://github.com/dgrisant/SnapSort/releases)
2. Move `SnapSort.app` to your Applications folder
3. Launch SnapSort
4. Grant necessary permissions when prompted

### Build from Source
```bash
git clone https://github.com/dgrisant/SnapSort.git
cd SnapSort
xcodebuild -project SnapSort.xcodeproj -scheme SnapSort -configuration Release build
```

## Usage

1. **Enable/Disable** - Toggle screenshot organization on/off
2. **Instant Move** - Enable to skip the macOS thumbnail preview (screenshots move immediately)
3. **Open Screenshots Folder** - Quick access to your organized screenshots
4. **Quit** - Exit the app

### Default Behavior
- **Watch Folder:** Your macOS screenshot location (Desktop by default)
- **Destination:** `~/Pictures/Screenshots/`
- **File Prefixes:** Screenshot, Screen Shot, Screen Recording, mac_

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building from source)

## License

MIT License - see [LICENSE](LICENSE) for details.
