// OfficeLayout.swift
// Botcrew

import Foundation

/// Persisted office customizations per project
struct OfficeLayout: Codable {
    /// Agent name → normalized position (0..1 relative to canvas size)
    var spritePositions: [String: NormalizedPoint] = [:]
}

struct NormalizedPoint: Codable, Equatable {
    var x: Double
    var y: Double
}
