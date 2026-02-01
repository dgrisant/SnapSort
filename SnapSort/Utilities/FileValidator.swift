import Foundation
import UniformTypeIdentifiers

struct FileValidator {
    // Common image file signatures (magic bytes)
    private static let imageSignatures: [(extension: String, bytes: [UInt8])] = [
        ("png", [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]), // PNG
        ("jpg", [0xFF, 0xD8, 0xFF]), // JPEG
        ("gif", [0x47, 0x49, 0x46, 0x38]), // GIF
        ("bmp", [0x42, 0x4D]), // BMP
        ("webp", [0x52, 0x49, 0x46, 0x46]), // RIFF (WebP container)
        ("tiff", [0x49, 0x49, 0x2A, 0x00]), // TIFF (little endian)
        ("tiff", [0x4D, 0x4D, 0x00, 0x2A]), // TIFF (big endian)
        ("heic", [0x00, 0x00, 0x00]), // HEIC (requires more complex detection)
    ]

    /// Validates if a file is a valid image by checking its magic bytes
    static func isValidImage(at url: URL) -> Bool {
        // First check file extension
        let validExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff", "tif", "heic", "heif"]
        let fileExtension = url.pathExtension.lowercased()

        guard validExtensions.contains(fileExtension) else {
            return false
        }

        // Then verify with magic bytes
        return verifyMagicBytes(at: url)
    }

    /// Checks the file's magic bytes to verify it's actually an image
    private static func verifyMagicBytes(at url: URL) -> Bool {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return false
        }

        defer {
            try? fileHandle.close()
        }

        // Read the first 12 bytes for signature detection
        guard let headerData = try? fileHandle.read(upToCount: 12),
              headerData.count >= 2 else {
            return false
        }

        let bytes = Array(headerData)

        // Check against known image signatures
        for signature in imageSignatures {
            if bytes.count >= signature.bytes.count {
                let headerBytes = Array(bytes.prefix(signature.bytes.count))
                if headerBytes == signature.bytes {
                    return true
                }
            }
        }

        // Special check for HEIC/HEIF (ftyp box check)
        if bytes.count >= 12 {
            // HEIC files have 'ftyp' at offset 4
            let ftypBytes: [UInt8] = [0x66, 0x74, 0x79, 0x70] // "ftyp"
            if Array(bytes[4..<8]) == ftypBytes {
                return true
            }
        }

        return false
    }

    /// Gets the UTType for a file URL
    static func getFileType(for url: URL) -> UTType? {
        guard let resourceValues = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
              let typeIdentifier = resourceValues.typeIdentifier else {
            return nil
        }
        return UTType(typeIdentifier)
    }

    /// Checks if the file is an image based on UTType
    static func isImageType(_ url: URL) -> Bool {
        guard let type = getFileType(for: url) else { return false }
        return type.conforms(to: .image)
    }
}
