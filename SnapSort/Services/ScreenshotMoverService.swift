import Foundation
import Combine

class ScreenshotMoverService: ObservableObject {
    static let shared = ScreenshotMoverService()

    @Published var isWatching = false
    @Published var movedCount = 0

    private var fileWatchers: [FileWatcherService] = []
    private var pendingFiles: Set<String> = []
    private let processingQueue = DispatchQueue(label: "com.snapsort.processing")

    private init() {}

    func startWatching() {
        guard !isWatching else { return }

        let settings = AppSettings.shared
        guard settings.isConfigured else {
            NSLog("[SnapSort] Cannot start watching - not configured")
            return
        }

        // Start accessing security-scoped resources
        _ = settings.startAccessingWatchFolder()
        _ = settings.startAccessingDestinationFolder()

        // Build list of folders to watch
        var foldersToWatch: [URL] = []

        // Always watch the destination folder (where macOS should save screenshots)
        if let destURL = settings.destinationFolderURL {
            foldersToWatch.append(destURL)
        }

        // Also watch Desktop as fallback (Cmd+Shift+5 sometimes ignores the location setting)
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            if !foldersToWatch.contains(desktopURL) {
                foldersToWatch.append(desktopURL)
            }
        }

        // Watch each folder
        for folderURL in foldersToWatch {
            NSLog("[SnapSort] Starting to watch: %@", folderURL.path)
            let watcher = FileWatcherService(path: folderURL.path)
            watcher.delegate = self
            watcher.start()
            fileWatchers.append(watcher)
        }

        NSLog("[SnapSort] Destination folder: %@", settings.destinationFolderURL?.path ?? "nil")

        DispatchQueue.main.async {
            self.isWatching = true
        }

        // Process any existing files that match in all watched folders
        processExistingFiles(in: foldersToWatch)
    }

    func stopWatching() {
        for watcher in fileWatchers {
            watcher.stop()
        }
        fileWatchers.removeAll()

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

    // MARK: - Reorganize Existing Files

    /// Reorganizes existing screenshots in the destination folder according to current settings
    /// Returns the number of files reorganized
    func reorganizeExistingFiles(completion: @escaping (Int) -> Void) {
        let settings = AppSettings.shared
        guard let destinationURL = settings.destinationFolderURL else {
            completion(0)
            return
        }

        processingQueue.async {
            let fileManager = FileManager.default
            var reorganizedCount = 0

            // Get all files in the root of destination folder (not in subfolders)
            guard let contents = try? fileManager.contentsOfDirectory(
                at: destinationURL,
                includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                DispatchQueue.main.async { completion(0) }
                return
            }

            for fileURL in contents {
                // Skip directories
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                   resourceValues.isDirectory == true {
                    continue
                }

                // Check if file matches our prefixes
                let filename = fileURL.lastPathComponent
                guard settings.matchesPrefix(filename) else { continue }

                // Validate it's an image
                guard FileValidator.isValidImage(at: fileURL) else { continue }

                // Get file creation date
                let fileDate: Date
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date {
                    fileDate = creationDate
                } else {
                    fileDate = Date()
                }

                // Get proper destination folder
                guard let properFolder = settings.getDestinationFolder(for: fileDate) else { continue }

                // Skip if already in the correct folder
                if fileURL.deletingLastPathComponent().path == properFolder.path {
                    continue
                }

                // Generate new filename
                var newFilename = settings.generateFilename(for: filename, date: fileDate)
                var newDestination = properFolder.appendingPathComponent(newFilename)

                // Handle conflicts
                var counter = 1
                let nameWithoutExtension = (newFilename as NSString).deletingPathExtension
                let fileExtension = (newFilename as NSString).pathExtension

                while fileManager.fileExists(atPath: newDestination.path) {
                    newFilename = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
                    newDestination = properFolder.appendingPathComponent(newFilename)
                    counter += 1
                }

                // Move the file
                do {
                    try fileManager.moveItem(at: fileURL, to: newDestination)
                    reorganizedCount += 1
                    print("[SnapSort] Reorganized: \(filename) → \(properFolder.lastPathComponent)/\(newFilename)")
                } catch {
                    print("[SnapSort] Failed to reorganize \(filename): \(error)")
                }
            }

            DispatchQueue.main.async {
                if reorganizedCount > 0 {
                    self.movedCount += reorganizedCount

                    if settings.showNotifications {
                        NotificationService.shared.sendNotification(
                            title: "Screenshots Reorganized",
                            body: "\(reorganizedCount) file\(reorganizedCount == 1 ? "" : "s") organized into date folders"
                        )
                    }
                }
                completion(reorganizedCount)
            }
        }
    }

    private func processExistingFiles(in folders: [URL]) {
        processingQueue.async { [weak self] in
            let fileManager = FileManager.default

            for watchURL in folders {
                NSLog("[SnapSort] Processing existing files in: %@", watchURL.path)

                guard let contents = try? fileManager.contentsOfDirectory(
                    at: watchURL,
                    includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    NSLog("[SnapSort] Failed to read directory contents for %@", watchURL.path)
                    continue
                }

                NSLog("[SnapSort] Found %d items in %@", contents.count, watchURL.lastPathComponent)
                for fileURL in contents {
                    self?.processFile(at: fileURL)
                }
            }
        }
    }

    private func processFile(at url: URL, retryCount: Int = 0) {
        let filename = url.lastPathComponent
        let maxRetries = 3

        // Skip if already being processed
        guard !pendingFiles.contains(filename) else {
            NSLog("[SnapSort] Skipping %@ - already being processed", filename)
            return
        }

        // Check if file matches our prefixes
        guard AppSettings.shared.matchesPrefix(filename) else {
            NSLog("[SnapSort] Skipping %@ - doesn't match prefixes", filename)
            return
        }

        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("[SnapSort] Skipping %@ - file doesn't exist", filename)
            return
        }

        // Wait for file to be stable (not being written)
        guard isFileStable(at: url) else {
            if retryCount < maxRetries {
                NSLog("[SnapSort] File %@ not stable yet, retry %d/%d", filename, retryCount + 1, maxRetries)
                processingQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.processFile(at: url, retryCount: retryCount + 1)
                }
            } else {
                NSLog("[SnapSort] File %@ never became stable, giving up", filename)
            }
            return
        }

        // Validate it's an image
        guard FileValidator.isValidImage(at: url) else {
            if retryCount < maxRetries {
                NSLog("[SnapSort] File %@ failed validation, retry %d/%d", filename, retryCount + 1, maxRetries)
                processingQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.processFile(at: url, retryCount: retryCount + 1)
                }
            } else {
                NSLog("[SnapSort] File %@ failed validation after %d retries", filename, maxRetries)
            }
            return
        }

        pendingFiles.insert(filename)
        NSLog("[SnapSort] Processing %@", filename)

        // Delay before moving:
        // - Quick mode: 1.0s (moves before preview dismisses, but after file is written)
        // - Normal mode: 4s (waits for macOS preview to dismiss)
        let delay: Double = AppSettings.shared.quickMoveEnabled ? 1.0 : 4.0

        processingQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.moveFile(at: url)
            self?.pendingFiles.remove(filename)
        }
    }

    /// Checks if a file has finished being written by comparing sizes over time
    private func isFileStable(at url: URL) -> Bool {
        let fileManager = FileManager.default

        guard let attrs1 = try? fileManager.attributesOfItem(atPath: url.path),
              let size1 = attrs1[.size] as? Int64 else {
            return false
        }

        // Wait a bit and check again
        Thread.sleep(forTimeInterval: 0.2)

        guard let attrs2 = try? fileManager.attributesOfItem(atPath: url.path),
              let size2 = attrs2[.size] as? Int64 else {
            return false
        }

        // File is stable if size hasn't changed and is > 0
        return size1 == size2 && size1 > 0
    }

    private func moveFile(at sourceURL: URL) {
        let settings = AppSettings.shared
        let fileManager = FileManager.default
        let now = Date()
        let originalFilename = sourceURL.lastPathComponent

        // Verify source file still exists
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            NSLog("[SnapSort] Source file no longer exists: %@", originalFilename)
            return
        }

        // Get file creation date for organization (or use current date)
        let fileDate: Date
        if let attributes = try? fileManager.attributesOfItem(atPath: sourceURL.path),
           let creationDate = attributes[.creationDate] as? Date {
            fileDate = creationDate
        } else {
            fileDate = now
        }

        // Get destination folder with date-based organization
        guard let destinationFolder = settings.getDestinationFolder(for: fileDate) else {
            NSLog("[SnapSort] Failed to get destination folder for %@", originalFilename)
            return
        }

        // Generate new filename based on naming format
        var newFilename = settings.generateFilename(for: originalFilename, date: fileDate)
        var destinationURL = destinationFolder.appendingPathComponent(newFilename)

        // Handle filename conflicts
        var counter = 1
        let nameWithoutExtension = (newFilename as NSString).deletingPathExtension
        let fileExtension = (newFilename as NSString).pathExtension

        while fileManager.fileExists(atPath: destinationURL.path) {
            newFilename = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
            destinationURL = destinationFolder.appendingPathComponent(newFilename)
            counter += 1
        }

        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            NSLog("[SnapSort] SUCCESS Moved: %@ → %@/%@", originalFilename, destinationFolder.lastPathComponent, newFilename)

            DispatchQueue.main.async { [weak self] in
                self?.movedCount += 1

                // Track the moved file
                let movedFile = MovedFile(originalName: originalFilename, destinationPath: destinationURL.path)
                RecentFilesManager.shared.addFile(movedFile)

                // Send notification if enabled
                if settings.showNotifications {
                    NotificationService.shared.sendNotification(
                        title: "Screenshot Organized",
                        body: "\(originalFilename) → \(newFilename)"
                    )
                }
            }
        } catch {
            NSLog("[SnapSort] FAILED to move %@: %@", originalFilename, error.localizedDescription)
        }
    }
}

// MARK: - FileWatcherDelegate
extension ScreenshotMoverService: FileWatcherDelegate {
    func fileWatcher(_ watcher: FileWatcherService, didDetectNewFile url: URL) {
        NSLog("[SnapSort] FSEvent detected file: %@", url.lastPathComponent)
        processingQueue.async { [weak self] in
            self?.processFile(at: url)
        }
    }
}
