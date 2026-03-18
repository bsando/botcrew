// TokenCard.swift
// Botcrew

import SwiftUI

struct TokenCard: View {
    @Environment(AppState.self) private var appState

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
                Text("—")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }

            HStack {
                Text("Cost")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("—")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(12)
        .background(Color(white: 1, opacity: 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
