// SpriteData.swift
// Botcrew

import SwiftUI

struct SpriteData {
    static let gridWidth = 8
    static let gridHeight = 10

    /// Resolve the sprite grid for an agent using the given theme
    static func shape(for status: AgentStatus, theme: SpriteTheme = .blobs) -> [[Int]] {
        theme.shapes.shape(for: status)
    }
}
