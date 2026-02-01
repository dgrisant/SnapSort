import Foundation
import Combine

class ScreenshotMoverService: ObservableObject {
    static let shared = ScreenshotMoverService()

    @Published var isWatching = false
    @Published var movedCount = 0

    private var fileWatcher: FileWatcherService?
    private var pendingFiles: Set<String> = []
    private let processingQueue = DispatchQueue(label: "com.snapsort.processing")

    private init() {}

    func startWatching() {
        guard !isWatching else { return }

        let settings = AppSettings.shared
        guard settings.isConfigured,
              let watchURL = settings.watchFolderURL else {
            return
        }

        // Start accessing security-scoped resources
        _ = settings.startAccessingWatchFolder()
        _ = settings.startAccessingDestinationFolder()

        fileWatcher = FileWatcherService(path: watchURL.path)
        fileWatcher?.delegate = self
        fileWatcher?.start()

        DispatchQueue.main.async {
            self.isWatching = true
        }

        // Process any existing files that match
        processExistingFiles()
    }

    func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil

        let settings = AppSettings.shared
        settings.stopAccessingWatchFolder()
        settings.stopAccessingDestinationFolder()

        DispatchQueue.main.async {
            self.isWatching = false
        }
    }

    func restartWatching() {
        stopWatching()
        if AppSettings.shared.isEnabled {
            startWatching()
        }
    }

    private func processExistingFiles() {
        guard let watchURL = AppSettings.shared.watchFolderURL else { return }

        processingQueue.async { [weak self] in
            let fileManager = FileManager.default
            guard let contents = try? fileManager.contentsOfDirectory(
                at: watchURL,
                includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            for fileURL in contents {
                self?.processFile(at: fileURL)
            }
        }
    }

    private func processFile(at url: URL) {
        let filename = url.lastPathComponent

        // Skip if already being processed
        guard !pendingFiles.contains(filename) else { return }

        // Check if file matches our prefixes
        guard AppSettings.shared.matchesPrefix(filename) else { return }

        // Validate it's an image
        guard FileValidator.isValidImage(at: url) else { return }

        pendingFiles.insert(filename)

        // Delay before moving:
        // - Quick mode: 0.5s (moves before preview dismisses)
        // - Normal mode: 4s (waits for macOS preview to dismiss)
        let delay: Double = AppSettings.shared.quickMoveEnabled ? 0.5 : 4.0

        processingQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.moveFile(at: url)
            self?.pendingFiles.remove(filename)
        }
    }

    private func moveFile(at sourceURL: URL) {
        guard let destinationFolder = AppSettings.shared.destinationFolderURL else { return }

        let filename = sourceURL.lastPathComponent
        var destinationURL = destinationFolder.appendingPathComponent(filename)

        // Handle filename conflicts
        let fileManager = FileManager.default
        var counter = 1
        let nameWithoutExtension = sourceURL.deletingPathExtension().lastPathComponent
        let fileExtension = sourceURL.pathExtension

        while fileManager.fileExists(atPath: destinationURL.path) {
            let newName = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
            destinationURL = destinationFolder.appendingPathComponent(newName)
            counter += 1
        }

        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)

            DispatchQueue.main.async { [weak self] in
                self?.movedCount += 1

                // Track the moved file
                let movedFile = MovedFile(originalName: filename, destinationPath: destinationURL.path)
                RecentFilesManager.shared.addFile(movedFile)

                // Send notification if enabled
                if AppSettings.shared.showNotifications {
                    NotificationService.shared.sendNotification(
                        title: "Screenshot Moved",
                        body: "Moved \(filename) to \(destinationFolder.lastPathComponent)"
                    )
                }
            }
        } catch {
            print("Failed to move file: \(error)")
        }
    }
}

// MARK: - FileWatcherDelegate
extension ScreenshotMoverService: FileWatcherDelegate {
    func fileWatcher(_ watcher: FileWatcherService, didDetectNewFile url: URL) {
        processingQueue.async { [weak self] in
            self?.processFile(at: url)
        }
    }
}
