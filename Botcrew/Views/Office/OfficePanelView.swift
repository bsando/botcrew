// OfficePanelView.swift
// Botcrew

import SwiftUI

struct OfficePanelView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("OFFICE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(.white.opacity(0.25))

                if let project = appState.selectedProject {
                    Text("— \(project.name)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.15))

                    HStack(spacing: 4) {
                        ForEach(project.agents) { agent in
                            Circle()
                                .fill(agentDotColor(agent.status))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.leading, 4)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(Color(red: 15/255, green: 16/255, blue: 32/255))

            Rectangle()
                .fill(Color(red: 25/255, green: 26/255, blue: 46/255))
        }
    }

    private func agentDotColor(_ status: AgentStatus) -> Color {
        switch status {
        case .typing, .reading: Color(hex: 0x28C840)
        case .waiting: Color(hex: 0xFEBC2E)
        case .idle: Color(hex: 0x888780)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}
