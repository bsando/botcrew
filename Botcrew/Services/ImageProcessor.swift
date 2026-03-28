// ImageProcessor.swift
// Botcrew

import AppKit
import UniformTypeIdentifiers

/// Processes images for attachment: resizing, base64 encoding, thumbnail generation.
enum ImageProcessor {
    static let maxDimension: CGFloat = 2048
    static let maxFileSize = 5 * 1024 * 1024 // 5MB
    static let thumbnailSize: CGFloat = 120

    /// Process an image file from disk
    static func processFile(at url: URL) -> ImageAttachment? {
        let mediaType = self.mediaType(for: url)

        // For non-standard formats or when we want raw bytes, read directly
        guard let image = NSImage(contentsOf: url) else { return nil }

        let resized = resize(image, maxDimension: maxDimension)
        guard let (base64, _) = encodeBase64(resized, mediaType: mediaType) else { return nil }

        // Check size and re-encode as JPEG if too large
        let finalBase64: String
        let finalMediaType: String
        if base64.count * 3 / 4 > maxFileSize {
            if let (jpegBase64, _) = encodeAsJPEG(resized, qualities: [0.8, 0.6, 0.4]) {
                finalBase64 = jpegBase64
                finalMediaType = "image/jpeg"
            } else {
                return nil
            }
        } else {
            finalBase64 = base64
            finalMediaType = mediaType
        }

        let thumbnail = resize(image, maxDimension: thumbnailSize)
        let fileSize = Data(base64Encoded: finalBase64)?.count ?? 0

        return ImageAttachment(
            thumbnail: thumbnail,
            base64Data: finalBase64,
            mediaType: finalMediaType,
            fileName: url.lastPathComponent,
            fileSize: fileSize
        )
    }

    /// Process an NSImage (e.g. from pasteboard)
    static func processImage(_ image: NSImage, fileName: String? = nil) -> ImageAttachment? {
        let resized = resize(image, maxDimension: maxDimension)
        guard let (base64, mediaType) = encodeBase64(resized, mediaType: "image/png") else { return nil }

        let finalBase64: String
        let finalMediaType: String
        if base64.count * 3 / 4 > maxFileSize {
            if let (jpegBase64, _) = encodeAsJPEG(resized, qualities: [0.8, 0.6, 0.4]) {
                finalBase64 = jpegBase64
                finalMediaType = "image/jpeg"
            } else {
                return nil
            }
        } else {
            finalBase64 = base64
            finalMediaType = mediaType
        }

        let thumbnail = resize(image, maxDimension: thumbnailSize)
        let fileSize = Data(base64Encoded: finalBase64)?.count ?? 0

        return ImageAttachment(
            thumbnail: thumbnail,
            base64Data: finalBase64,
            mediaType: finalMediaType,
            fileName: fileName,
            fileSize: fileSize
        )
    }

    /// Detect media type from file extension
    static func mediaType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return "image/png"
        }
    }

    // MARK: - Private

    private static func resize(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        return resized
    }

    private static func encodeBase64(_ image: NSImage, mediaType: String) -> (String, String)? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        let fileType: NSBitmapImageRep.FileType
        switch mediaType {
        case "image/jpeg": fileType = .jpeg
        case "image/gif": fileType = .gif
        default: fileType = .png
        }

        let properties: [NSBitmapImageRep.PropertyKey: Any] = fileType == .jpeg
            ? [.compressionFactor: 0.9]
            : [:]

        guard let data = bitmap.representation(using: fileType, properties: properties) else { return nil }
        return (data.base64EncodedString(), mediaType)
    }

    private static func encodeAsJPEG(_ image: NSImage, qualities: [CGFloat]) -> (String, String)? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        for quality in qualities {
            if let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality]) {
                let base64 = data.base64EncodedString()
                if base64.count * 3 / 4 <= maxFileSize {
                    return (base64, "image/jpeg")
                }
            }
        }
        return nil
    }
}
