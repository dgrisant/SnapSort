import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let watchFolderBookmark = "watchFolderBookmark"
        static let destinationFolderBookmark = "destinationFolderBookmark"
        static let filePrefixes = "filePrefixes"
        static let showNotifications = "showNotifications"
        static let launchAtLogin = "launchAtLogin"
        static let quickMoveEnabled = "quickMoveEnabled"
    }

    // MARK: - Published Properties
    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Keys.isEnabled)
            if isEnabled {
                ScreenshotMoverService.shared.startWatching()
            } else {
                ScreenshotMoverService.shared.stopWatching()
            }
        }
    }

    @Published var watchFolderURL: URL? {
        didSet {
            if let url = watchFolderURL {
                saveBookmark(for: url, key: Keys.watchFolderBookmark)
            } else {
                defaults.removeObject(forKey: Keys.watchFolderBookmark)
            }
        }
    }

    @Published var destinationFolderURL: URL? {
        didSet {
            if let url = destinationFolderURL {
                saveBookmark(for: url, key: Keys.destinationFolderBookmark)
            } else {
                defaults.removeObject(forKey: Keys.destinationFolderBookmark)
            }
        }
    }

    @Published var filePrefixes: [String] {
        didSet {
            defaults.set(filePrefixes, forKey: Keys.filePrefixes)
        }
    }

    @Published var showNotifications: Bool {
        didSet {
            defaults.set(showNotifications, forKey: Keys.showNotifications)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LaunchAtLoginService.shared.setEnabled(launchAtLogin)
        }
    }

    @Published var quickMoveEnabled: Bool {
        didSet {
            defaults.set(quickMoveEnabled, forKey: Keys.quickMoveEnabled)
            // Toggle macOS screenshot thumbnail preview
            setScreenshotThumbnailEnabled(!quickMoveEnabled)
        }
    }

    /// Controls the macOS screenshot thumbnail preview
    private func setScreenshotThumbnailEnabled(_ enabled: Bool) {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "defaults write com.apple.screencapture show-thumbnail -bool \(enabled ? "true" : "false")"]
        task.launch()
        task.waitUntilExit()
    }

    // MARK: - Initialization
    private init() {
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.filePrefixes = defaults.stringArray(forKey: Keys.filePrefixes) ?? ["Screenshot", "Screen Shot", "Screen Recording", "mac_"]
        self.showNotifications = defaults.object(forKey: Keys.showNotifications) as? Bool ?? true
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.quickMoveEnabled = defaults.bool(forKey: Keys.quickMoveEnabled) // Default false

        // Apply screenshot thumbnail setting on startup
        if quickMoveEnabled {
            setScreenshotThumbnailEnabled(false)
        }

        // Load security-scoped bookmarks or use defaults
        self.watchFolderURL = loadBookmark(for: Keys.watchFolderBookmark)
        self.destinationFolderURL = loadBookmark(for: Keys.destinationFolderBookmark)

        // Auto-configure with sensible defaults if not set
        if watchFolderURL == nil {
            watchFolderURL = Self.getScreenshotLocation()
        }

        if destinationFolderURL == nil {
            setupDefaultDestination()
        }
    }

    private func setupDefaultDestination() {
        guard let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else { return }

        let screenshotsURL = picturesURL.appendingPathComponent("Screenshots")

        // Create the folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: screenshotsURL.path) {
            try? FileManager.default.createDirectory(at: screenshotsURL, withIntermediateDirectories: true)
        }

        destinationFolderURL = screenshotsURL
    }

    // MARK: - Security-Scoped Bookmarks
    private func saveBookmark(for url: URL, key: String) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            defaults.set(bookmarkData, forKey: key)
        } catch {
            print("Failed to save bookmark for \(url): \(error)")
        }
    }

    private func loadBookmark(for key: String) -> URL? {
        guard let bookmarkData = defaults.data(forKey: key) else { return nil }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Re-save the bookmark if it's stale
                saveBookmark(for: url, key: key)
            }

            return url
        } catch {
            print("Failed to load bookmark: \(error)")
            return nil
        }
    }

    // MARK: - Bookmark Access
    func startAccessingWatchFolder() -> Bool {
        return watchFolderURL?.startAccessingSecurityScopedResource() ?? false
    }

    func stopAccessingWatchFolder() {
        watchFolderURL?.stopAccessingSecurityScopedResource()
    }

    func startAccessingDestinationFolder() -> Bool {
        return destinationFolderURL?.startAccessingSecurityScopedResource() ?? false
    }

    func stopAccessingDestinationFolder() {
        destinationFolderURL?.stopAccessingSecurityScopedResource()
    }

    // MARK: - Computed Properties
    var isConfigured: Bool {
        return watchFolderURL != nil && destinationFolderURL != nil
    }

    func matchesPrefix(_ filename: String) -> Bool {
        return filePrefixes.contains { filename.hasPrefix($0) }
    }

    // MARK: - Screenshot Location Detection
    /// Gets the user's configured screenshot save location from macOS preferences
    static func getScreenshotLocation() -> URL {
        // Try to read from macOS screencapture preferences
        if let locationString = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let url = URL(fileURLWithPath: locationString)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // Fall back to Desktop
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    }
}
