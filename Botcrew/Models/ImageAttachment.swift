// ImageAttachment.swift
// Botcrew

import AppKit

/// An image attached to a prompt, ready to be sent as a base64 content block.
struct ImageAttachment: Identifiable {
    let id: UUID
    let thumbnail: NSImage
    let base64Data: String
    let mediaType: String
    let fileName: String?
    let fileSize: Int

    init(id: UUID = UUID(), thumbnail: NSImage, base64Data: String, mediaType: String, fileName: String? = nil, fileSize: Int) {
        self.id = id
        self.thumbnail = thumbnail
        self.base64Data = base64Data
        self.mediaType = mediaType
        self.fileName = fileName
        self.fileSize = fileSize
    }
}
