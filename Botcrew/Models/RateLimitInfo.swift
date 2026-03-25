// RateLimitInfo.swift
// Botcrew

import Foundation

struct RateLimitInfo: Codable, Equatable {
    let status: String           // "allowed" | "rate_limited"
    let resetsAt: Date
    let rateLimitType: String    // "five_hour"
    let overageStatus: String    // "allowed" | "rate_limited"
    let overageResetsAt: Date
    let isUsingOverage: Bool
    let receivedAt: Date

    enum UsageTier {
        case allowed
        case overage
        case rateLimited
    }

    var tier: UsageTier {
        if status == "rate_limited" { return .rateLimited }
        if isUsingOverage { return .overage }
        return .allowed
    }

    var isExpired: Bool {
        Date() > resetsAt
    }
}
