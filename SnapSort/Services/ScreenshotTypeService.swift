import Foundation
import AppKit

enum ScreenshotType: String, CaseIterable {
    case fullScreen = "Full Screen"
    case selection = "Selection"
    case window = "Window"
    case recording = "Recording"
    case unknown = "Unknown"

    var folderName: String {
        switch self {
        case .fullScreen: return "Full Screen"
        case .selection: return "Selections"
        case .window: return "Windows"
        case .recording: return "Recordings"
        case .unknown: return "Other"
        }
    }
}

class ScreenshotTypeService {
    static let shared = ScreenshotTypeService()

    private init() {}

    /// Detects the type of screenshot based on dimensions and filename
    func detectType(at url: URL) -> ScreenshotType {
        let filename = url.lastPathComponent.lowercased()

        // Check for screen recordings first
        if filename.contains("screen recording") || url.pathExtension.lowercased() == "mov" {
            return .recording
        }

        // Get image dimensions
        guard let imageSize = getImageSize(at: url) else {
            return .unknown
        }

        // Get screen dimensions
        let screenSizes = getScreenSizes()

        // Check if it matches any screen size (full screen capture)
        for screenSize in screenSizes {
            if isFullScreen(imageSize: imageSize, screenSize: screenSize) {
                return .fullScreen
            }
        }

        // Check for window capture (typically has shadow padding)
        // Window captures usually have dimensions that don't match screen or selection patterns
        if hasWindowShadow(at: url) || isLikelyWindowCapture(imageSize: imageSize, screenSizes: screenSizes) {
            return .window
        }

        // Default to selection for partial captures
        return .selection
    }

    /// Gets the dimensions of an image
    private func getImageSize(at url: URL) -> CGSize? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    /// Gets the sizes of all connected screens
    private func getScreenSizes() -> [CGSize] {
        return NSScreen.screens.map { screen in
            let frame = screen.frame
            let scale = screen.backingScaleFactor
            return CGSize(width: frame.width * scale, height: frame.height * scale)
        }
    }

    /// Checks if image dimensions match a screen size (with small tolerance)
    private func isFullScreen(imageSize: CGSize, screenSize: CGSize) -> Bool {
        let tolerance: CGFloat = 10
        return abs(imageSize.width - screenSize.width) <= tolerance &&
               abs(imageSize.height - screenSize.height) <= tolerance
    }

    /// Checks if the image likely has window shadow (alpha channel with transparency)
    private func hasWindowShadow(at url: URL) -> Bool {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }

        // Window captures with shadows typically have alpha channel
        let hasAlpha = cgImage.alphaInfo != .none && cgImage.alphaInfo != .noneSkipFirst && cgImage.alphaInfo != .noneSkipLast
        return hasAlpha
    }

    /// Heuristic to detect window captures based on size patterns
    private func isLikelyWindowCapture(imageSize: CGSize, screenSizes: [CGSize]) -> Bool {
        // Window captures are usually between 400-2000px in width
        // and have an aspect ratio typical of windows
        let minWindowWidth: CGFloat = 400
        let maxWindowWidth: CGFloat = 2500

        if imageSize.width < minWindowWidth || imageSize.width > maxWindowWidth {
            return false
        }

        // Check if it's not a full screen and has reasonable window-like proportions
        let aspectRatio = imageSize.width / imageSize.height
        return aspectRatio > 0.5 && aspectRatio < 3.0
    }
}
