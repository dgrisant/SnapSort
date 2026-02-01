import Foundation
import Combine

// MARK: - Organization Enums

enum FolderOrganization: String, CaseIterable, Identifiable {
    case flat = "flat"                      // No subfolders (current behavior)
    case yearMonthDay = "yearMonthDay"      // 2026/02/01/
    case yearMonth = "yearMonth"            // 2026/02/
    case yearMonthDayFlat = "yearMonthDayFlat"  // 2026-02-01/

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flat: return "Flat (no subfolders)"
        case .yearMonthDay: return "Year / Month / Day"
        case .yearMonth: return "Year / Month"
        case .yearMonthDayFlat: return "Year-Month-Day"
        }
    }

    var example: String {
        switch self {
        case .flat: return "Screenshots/image.png"
        case .yearMonthDay: return "Screenshots/2026/02/01/image.png"
        case .yearMonth: return "Screenshots/2026/02/image.png"
        case .yearMonthDayFlat: return "Screenshots/2026-02-01/image.png"
        }
    }

    func subpath(for date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        switch self {
        case .flat:
            return ""
        case .yearMonthDay:
            return String(format: "%04d/%02d/%02d", year, month, day)
        case .yearMonth:
            return String(format: "%04d/%02d", year, month)
        case .yearMonthDayFlat:
            return String(format: "%04d-%02d-%02d", year, month, day)
        }
    }
}

enum NamingFormat: String, CaseIterable, Identifiable {
    case original = "original"              // Keep original macOS name
    case compact = "compact"                // 2026-02-01_094532.png
    case sequential = "sequential"          // Screenshot_001.png
    case custom = "custom"                  // {prefix}_{date}_{time}.png

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return "Original (macOS default)"
        case .compact: return "Compact (date_time)"
        case .sequential: return "Sequential (numbered)"
        case .custom: return "Custom prefix"
        }
    }

    var example: String {
        switch self {
        case .original: return "Screenshot 2026-02-01 at 9.45.32 AM.png"
        case .compact: return "2026-02-01_094532.png"
        case .sequential: return "Screenshot_001.png"
        case .custom: return "MyPrefix_2026-02-01_094532.png"
        }
    }
}

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
        // Phase 1: Organization
        static let folderOrganization = "folderOrganization"
        static let namingFormat = "namingFormat"
        static let customPrefix = "customPrefix"
        static let sequentialCounter = "sequentialCounter"
        // Phase 2: Intelligent Sorting
        static let appSortingEnabled = "appSortingEnabled"
        static let appBlacklist = "appBlacklist"
        static let typeSortingEnabled = "typeSortingEnabled"
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

    // MARK: - Phase 1: Organization Settings

    @Published var folderOrganization: FolderOrganization {
        didSet {
            defaults.set(folderOrganization.rawValue, forKey: Keys.folderOrganization)
            // Auto-reorganize existing files when setting changes
            if oldValue != folderOrganization {
                NSLog("[SnapSort] Folder organization changed from %@ to %@, reorganizing files...", oldValue.rawValue, folderOrganization.rawValue)
                ScreenshotMoverService.shared.reorganizeAllFiles { count in
                    NSLog("[SnapSort] Reorganized %d files to new folder structure", count)
                }
            }
        }
    }

    @Published var namingFormat: NamingFormat {
        didSet {
            defaults.set(namingFormat.rawValue, forKey: Keys.namingFormat)
        }
    }

    @Published var customPrefix: String {
        didSet {
            defaults.set(customPrefix, forKey: Keys.customPrefix)
        }
    }

    @Published var sequentialCounter: Int {
        didSet {
            defaults.set(sequentialCounter, forKey: Keys.sequentialCounter)
        }
    }

    // MARK: - Phase 2: Intelligent Sorting Settings

    @Published var appSortingEnabled: Bool {
        didSet {
            defaults.set(appSortingEnabled, forKey: Keys.appSortingEnabled)
        }
    }

    @Published var appBlacklist: [String] {
        didSet {
            defaults.set(appBlacklist, forKey: Keys.appBlacklist)
        }
    }

    @Published var typeSortingEnabled: Bool {
        didSet {
            defaults.set(typeSortingEnabled, forKey: Keys.typeSortingEnabled)
        }
    }

    /// Checks if an app should be excluded from app-based sorting
    func isAppBlacklisted(_ appName: String) -> Bool {
        return appBlacklist.contains { $0.lowercased() == appName.lowercased() }
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

        // Phase 1: Organization settings
        let orgRaw = defaults.string(forKey: Keys.folderOrganization)
        NSLog("[SnapSort] Raw folderOrganization from defaults: %@", orgRaw ?? "nil")
        if let orgRaw = orgRaw, let org = FolderOrganization(rawValue: orgRaw) {
            self.folderOrganization = org
            NSLog("[SnapSort] Loaded folderOrganization: %@", org.rawValue)
        } else {
            self.folderOrganization = .flat
            NSLog("[SnapSort] Using default folderOrganization: flat")
        }

        let nameRaw = defaults.string(forKey: Keys.namingFormat)
        NSLog("[SnapSort] Raw namingFormat from defaults: %@", nameRaw ?? "nil")
        if let nameRaw = nameRaw, let name = NamingFormat(rawValue: nameRaw) {
            self.namingFormat = name
            NSLog("[SnapSort] Loaded namingFormat: %@", name.rawValue)
        } else {
            self.namingFormat = .original
            NSLog("[SnapSort] Using default namingFormat: original")
        }

        self.customPrefix = defaults.string(forKey: Keys.customPrefix) ?? "Screenshot"
        self.sequentialCounter = defaults.integer(forKey: Keys.sequentialCounter)

        // Phase 2: Intelligent Sorting settings
        self.appSortingEnabled = defaults.bool(forKey: Keys.appSortingEnabled) // Default false
        self.appBlacklist = defaults.stringArray(forKey: Keys.appBlacklist) ?? ["Finder", "SnapSort"]
        self.typeSortingEnabled = defaults.bool(forKey: Keys.typeSortingEnabled) // Default false

        // Apply screenshot thumbnail setting on startup
        if quickMoveEnabled {
            setScreenshotThumbnailEnabled(false)
        }

        // Load security-scoped bookmarks or use defaults
        self.watchFolderURL = loadBookmark(for: Keys.watchFolderBookmark)
        self.destinationFolderURL = loadBookmark(for: Keys.destinationFolderBookmark)

        // Auto-configure with sensible defaults if not set
        if destinationFolderURL == nil {
            setupDefaultDestination()
        }

        // Configure macOS to save screenshots directly to our destination folder
        // This eliminates the need for a separate watch folder
        if destinationFolderURL != nil {
            configureScreenshotLocation()
            // Watch the same folder where screenshots are saved
            watchFolderURL = destinationFolderURL
        }
    }

    /// Configures macOS to save screenshots directly to our destination folder
    private func configureScreenshotLocation() {
        guard let destination = destinationFolderURL else { return }

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "defaults write com.apple.screencapture location '\(destination.path)' && killall SystemUIServer 2>/dev/null || true"]
        task.launch()
        task.waitUntilExit()

        NSLog("[SnapSort] Configured macOS screenshot location to: %@", destination.path)
    }

    private func setupDefaultDestination() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let screenshotsURL = documentsURL.appendingPathComponent("Screenshots")

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

    // MARK: - Filename Generation

    /// Generates a new filename based on current naming format settings
    func generateFilename(for originalName: String, date: Date = Date()) -> String {
        let fileExtension = (originalName as NSString).pathExtension
        print("[SnapSort] generateFilename called - namingFormat: \(namingFormat.rawValue)")

        switch namingFormat {
        case .original:
            return originalName

        case .compact:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HHmmss"
            return "\(formatter.string(from: date)).\(fileExtension)"

        case .sequential:
            sequentialCounter += 1
            return String(format: "%@_%03d.%@", customPrefix, sequentialCounter, fileExtension)

        case .custom:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HHmmss"
            return "\(customPrefix)_\(formatter.string(from: date)).\(fileExtension)"
        }
    }

    /// Gets the full destination path including date-based, app-based, and type-based subfolders
    func getDestinationFolder(for date: Date = Date(), appName: String? = nil, screenshotType: ScreenshotType? = nil) -> URL? {
        guard let baseURL = destinationFolderURL else { return nil }

        var fullPath = baseURL

        // Add app subfolder if app sorting is enabled
        if appSortingEnabled, let app = appName, !app.isEmpty, !isAppBlacklisted(app) {
            let sanitizedApp = AppDetectionService.shared.sanitizeForFolderName(app)
            if !sanitizedApp.isEmpty {
                fullPath = fullPath.appendingPathComponent(sanitizedApp)
            }
        }

        // Add type subfolder if type sorting is enabled
        if typeSortingEnabled, let type = screenshotType, type != .unknown {
            fullPath = fullPath.appendingPathComponent(type.folderName)
        }

        // Add date-based subfolder
        let subpath = folderOrganization.subpath(for: date)
        if !subpath.isEmpty {
            fullPath = fullPath.appendingPathComponent(subpath)
        }

        // Create the folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: fullPath.path) {
            try? FileManager.default.createDirectory(at: fullPath, withIntermediateDirectories: true)
        }

        return fullPath
    }

    // MARK: - Screenshot Location Detection
    /// Gets the user's configured screenshot save location from macOS preferences
    static func getScreenshotLocation() -> URL {
        let fileManager = FileManager.default

        // Try to read from macOS screencapture preferences
        if let locationString = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let url = URL(fileURLWithPath: locationString)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }

        // Check for ~/Desktop/Screenshots (common alternative location)
        if let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let desktopScreenshots = desktop.appendingPathComponent("Screenshots")
            if fileManager.fileExists(atPath: desktopScreenshots.path) {
                // Check if this folder has screenshot files (any of our known prefixes)
                if let contents = try? fileManager.contentsOfDirectory(atPath: desktopScreenshots.path),
                   contents.contains(where: { name in
                       name.hasPrefix("Screenshot") || name.hasPrefix("Screen Shot") ||
                       name.hasPrefix("Screen Recording") || name.hasPrefix("mac_") ||
                       name.hasSuffix(".png") || name.hasSuffix(".jpg")
                   }) {
                    return desktopScreenshots
                }
            }
        }

        // Fall back to Desktop
        return fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
    }
}
