// TokenCard.swift
// Botcrew

import SwiftUI

struct TokenCard: View {
    @Environment(AppState.self) private var appState

    private var tokenText: String {
        guard let project = appState.selectedProject, project.tokenCount > 0 else { return "—" }
        if project.tokenCount >= 1000 {
            return String(format: "%.1fk", Double(project.tokenCount) / 1000)
        }
        return "\(project.tokenCount)"
    }

    private var costText: String {
        guard let project = appState.selectedProject, project.estimatedCost > 0 else { return "—" }
        return String(format: "$%.2f", project.estimatedCost)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SESSION")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.66)
                .foregroundStyle(.white.opacity(0.25))

            HStack {
                Text("Tokens")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text(tokenText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }

            HStack {
                Text("Cost")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text(costText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(12)
        .background(Color(white: 1, opacity: 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
