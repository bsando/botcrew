// CostRecord.swift
// Botcrew

import Foundation

struct CostRecord: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let date: Date
    let cost: Double
    let inputTokens: Int
    let outputTokens: Int
    let model: String?
}
