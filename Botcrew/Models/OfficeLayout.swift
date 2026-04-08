// OfficeLayout.swift
// Botcrew

import Foundation

/// Persisted office customizations per project
struct OfficeLayout: Codable {
    /// Agent name → normalized position (0..1 relative to canvas size)
    var spritePositions: [String: NormalizedPoint] = [:]
    /// Agent name → custom colors (overrides default palette)
    var agentColors: [String: AgentColorConfig] = [:]
    /// Agent name → custom sprite pixel art (overrides theme)
    var customSprites: [String: SpriteShapeSet] = [:]
}

struct AgentColorConfig: Codable, Equatable {
    var bodyColorHex: UInt32
    var shirtColorHex: UInt32
}

struct NormalizedPoint: Codable, Equatable {
    var x: Double
    var y: Double
}
