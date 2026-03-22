// TokenCard.swift
// Botcrew

import SwiftUI

struct TokenCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var tokenText: String {
        guard let project = appState.selectedProject, project.tokenCount > 0 else { return "—" }
        if project.tokenCount >= 1000 {
            return String(format: "%.1fk", Double(project.tokenCount) / 1000)
        }
        return "\(project.tokenCount)"
    }

    private var costText: String {
        guard let project = appState.selectedProject, project.estimatedCost > 0 else { return "—" }
        return String(format: "$%.4f", project.estimatedCost)
    }

    var body: some View {
        Button {
            appState.showCostDashboard = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("SESSION")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.66)
                        .foregroundStyle(Theme.textMuted(colorScheme))
                    Spacer()
                    Image(systemName: "chart.bar")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                }

                HStack {
                    Text("Tokens")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                    Spacer()
                    Text(tokenText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary(colorScheme))
                }

                HStack {
                    Text("Cost")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                    Spacer()
                    Text(costText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary(colorScheme))
                }
            }
            .padding(12)
            .background(Theme.cardBg(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: Binding(
            get: { appState.showCostDashboard },
            set: { appState.showCostDashboard = $0 }
        )) {
            CostDashboardView()
                .environment(appState)
        }
    }
}
