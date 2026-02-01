import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Metadata keys stored in PNG text chunks
struct ScreenshotMetadataKeys {
    static let appName = "SnapSort:AppName"
    static let screenshotType = "SnapSort:ScreenshotType"
    static let captureDate = "SnapSort:CaptureDate"
    static let version = "SnapSort:MetadataVersion"
}

/// Represents metadata stored in a screenshot
struct ScreenshotMetadata {
    let appName: String?
    let screenshotType: String?  // ScreenshotType.rawValue
    let captureDate: Date
    let metadataVersion: Int

    static let currentVersion = 1

    init(appName: String?, screenshotType: String?, captureDate: Date) {
        self.appName = appName
        self.screenshotType = screenshotType
        self.captureDate = captureDate
        self.metadataVersion = Self.currentVersion
    }
}

/// Service for reading and writing SnapSort metadata to PNG files
class ImageMetadataService {
    static let shared = ImageMetadataService()

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private init() {}

    // MARK: - Write Metadata

    /// Writes SnapSort metadata to a PNG file without recompressing the image
    /// Uses CGImageDestinationCopyImageSource for lossless metadata injection
    func writeMetadata(_ metadata: ScreenshotMetadata, to fileURL: URL) -> Bool {
        // Only process PNG files
        guard fileURL.pathExtension.lowercased() == "png" else {
            NSLog("[SnapSort] Skipping metadata write for non-PNG file: %@", fileURL.lastPathComponent)
            return false
        }

        // Create image source from file
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            NSLog("[SnapSort] Failed to create image source for metadata write: %@", fileURL.path)
            return false
        }

        // Get existing properties
        var existingProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] ?? [:]

        // Get or create PNG dictionary for text chunks
        var pngDict = existingProperties[kCGImagePropertyPNGDictionary as String] as? [String: Any] ?? [:]

        // Add SnapSort metadata to PNG text chunks
        pngDict[ScreenshotMetadataKeys.appName] = metadata.appName ?? ""
        pngDict[ScreenshotMetadataKeys.screenshotType] = metadata.screenshotType ?? ""
        pngDict[ScreenshotMetadataKeys.captureDate] = dateFormatter.string(from: metadata.captureDate)
        pngDict[ScreenshotMetadataKeys.version] = String(metadata.metadataVersion)

        existingProperties[kCGImagePropertyPNGDictionary as String] = pngDict

        // Create temporary destination file
        let tempURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".png")

        guard let destination = CGImageDestinationCreateWithURL(
            tempURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            NSLog("[SnapSort] Failed to create image destination for metadata write")
            return false
        }

        // Copy image source to destination with new properties (no recompression)
        var error: Unmanaged<CFError>?
        let success = CGImageDestinationCopyImageSource(
            destination,
            imageSource,
            existingProperties as CFDictionary,
            &error
        )

        if !success {
            let errorDesc = error?.takeRetainedValue().localizedDescription ?? "unknown error"
            NSLog("[SnapSort] Failed to copy image source: %@", errorDesc)
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }

        // Replace original file with temp file (atomic operation)
        do {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
            NSLog("[SnapSort] Successfully wrote metadata to: %@", fileURL.lastPathComponent)
            return true
        } catch {
            NSLog("[SnapSort] Failed to replace file with metadata: %@", error.localizedDescription)
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
    }

    // MARK: - Read Metadata

    /// Reads SnapSort metadata from a PNG file
    func readMetadata(from fileURL: URL) -> ScreenshotMetadata? {
        // Only process PNG files
        guard fileURL.pathExtension.lowercased() == "png" else {
            return nil
        }

        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            return nil
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let pngDict = properties[kCGImagePropertyPNGDictionary as String] as? [String: Any] else {
            return nil
        }

        // Check for SnapSort metadata version
        guard let versionString = pngDict[ScreenshotMetadataKeys.version] as? String,
              let version = Int(versionString) else {
            return nil  // No SnapSort metadata present
        }

        let appName = pngDict[ScreenshotMetadataKeys.appName] as? String
        let typeString = pngDict[ScreenshotMetadataKeys.screenshotType] as? String
        let dateString = pngDict[ScreenshotMetadataKeys.captureDate] as? String

        let captureDate: Date
        if let dateStr = dateString, let date = dateFormatter.date(from: dateStr) {
            captureDate = date
        } else {
            // Fallback to file creation date
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let creationDate = attrs[.creationDate] as? Date {
                captureDate = creationDate
            } else {
                captureDate = Date()
            }
        }

        return ScreenshotMetadata(
            appName: appName?.isEmpty == true ? nil : appName,
            screenshotType: typeString?.isEmpty == true ? nil : typeString,
            captureDate: captureDate
        )
    }

    // MARK: - Utility

    /// Checks if a file has SnapSort metadata
    func hasSnapSortMetadata(at fileURL: URL) -> Bool {
        return readMetadata(from: fileURL) != nil
    }
}
