// SpriteData.swift
// Botcrew

import SwiftUI

// Pixel data from CLAUDE.md blob sprite design (8x10 grid)
// Values: 0=transparent, 1=body, 2=eyes, 3=accent, 6=X-eyes

struct SpriteData {
    // Idle / reading — upright
    static let body: [[Int]] = [
        [0,0,0,1,1,1,0,0],
        [0,0,1,1,1,1,1,0],
        [0,1,1,2,1,2,1,1],
        [0,1,1,1,1,1,1,1],
        [1,1,1,1,1,1,1,1],
        [1,1,3,1,1,3,1,1],
        [1,1,1,1,1,1,1,1],
        [0,1,1,1,1,1,1,0],
        [0,0,1,1,1,1,0,0],
        [0,0,0,1,1,0,0,0],
    ]

    // Typing / writing — hunched forward
    static let type: [[Int]] = [
        [0,0,0,0,1,1,1,0],
        [0,0,0,1,1,1,1,1],
        [0,0,1,1,2,1,2,1],
        [0,0,1,1,1,1,1,1],
        [0,1,1,1,1,1,1,1],
        [1,1,3,1,1,3,1,0],
        [1,1,1,1,1,1,1,0],
        [0,1,1,1,1,1,0,0],
        [0,0,1,1,1,1,0,0],
        [0,0,0,1,1,0,0,0],
    ]

    // Waiting / blocked — arms wide (shrug)
    static let shrug: [[Int]] = [
        [0,0,0,1,1,1,0,0],
        [0,0,1,1,1,1,1,0],
        [0,1,1,2,1,2,1,1],
        [0,1,1,1,1,1,1,1],
        [1,1,1,1,1,1,1,1],
        [3,1,1,1,1,1,1,3],
        [1,1,1,1,1,1,1,1],
        [0,1,1,1,1,1,1,0],
        [0,0,1,1,1,1,0,0],
        [0,0,0,1,1,0,0,0],
    ]

    // Error — X eyes, open mouth
    static let error: [[Int]] = [
        [0,0,0,1,1,1,0,0],
        [0,0,1,1,1,1,1,0],
        [0,1,1,6,1,6,1,1],
        [0,1,1,1,1,1,1,1],
        [1,1,1,1,1,1,1,1],
        [1,1,1,3,3,1,1,1],
        [1,1,1,1,1,1,1,1],
        [0,1,1,1,1,1,1,0],
        [0,0,1,1,1,1,0,0],
        [0,0,0,1,1,0,0,0],
    ]

    static func shape(for status: AgentStatus) -> [[Int]] {
        switch status {
        case .typing: type
        case .waiting: shrug
        case .error: error
        case .reading, .idle: body
        }
    }

    static let gridWidth = 8
    static let gridHeight = 10
}
