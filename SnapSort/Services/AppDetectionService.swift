import Foundation
import AppKit

class AppDetectionService {
    static let shared = AppDetectionService()

    private init() {}

    /// Gets the name of the currently frontmost application
    func getFrontmostAppName() -> String? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        return frontApp.localizedName
    }

    /// Gets the bundle identifier of the frontmost application
    func getFrontmostAppBundleId() -> String? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        return frontApp.bundleIdentifier
    }

    /// Sanitizes app name for use as folder name (removes special characters)
    func sanitizeForFolderName(_ appName: String) -> String {
        // Remove or replace characters that are problematic in folder names
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        let sanitized = appName.components(separatedBy: invalidCharacters).joined(separator: "")
        return sanitized.trimmingCharacters(in: .whitespaces)
    }

    /// Gets a clean folder name for the frontmost app
    func getFrontmostAppFolderName() -> String? {
        guard let appName = getFrontmostAppName() else { return nil }
        let folderName = sanitizeForFolderName(appName)
        return folderName.isEmpty ? nil : folderName
    }
}
