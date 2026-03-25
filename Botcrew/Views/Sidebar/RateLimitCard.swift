// RateLimitCard.swift
// Botcrew

import SwiftUI
import Combine

struct RateLimitCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        if let info = appState.rateLimitInfo, !info.isExpired {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("USAGE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.66)
                        .foregroundStyle(Theme.textMuted(colorScheme))
                    Spacer()
                    Circle()
                        .fill(tierColor(info.tier))
                        .frame(width: 6, height: 6)
                    Text(tierLabel(info.tier))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(tierColor(info.tier))
                }

                HStack {
                    Text("Resets in")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                    Spacer()
                    Text(countdownText(to: info.resetsAt))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary(colorScheme))
                }
            }
            .padding(12)
            .background(Theme.cardBg(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onReceive(timer) { now = $0 }
        }
    }

    private func tierColor(_ tier: RateLimitInfo.UsageTier) -> Color {
        switch tier {
        case .allowed: Color(hex: 0x28C840)
        case .overage: Color(hex: 0xFEBC2E)
        case .rateLimited: Color(hex: 0xFF5F57)
        }
    }

    private func tierLabel(_ tier: RateLimitInfo.UsageTier) -> String {
        switch tier {
        case .allowed: "Allowed"
        case .overage: "Overage"
        case .rateLimited: "Limited"
        }
    }

    private func countdownText(to date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: now, to: date)
        let hours = max(0, components.hour ?? 0)
        let minutes = max(0, components.minute ?? 0)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
