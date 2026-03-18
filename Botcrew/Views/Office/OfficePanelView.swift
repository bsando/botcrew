// OfficePanelView.swift
// Botcrew

import SwiftUI

struct OfficePanelView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Office bar (always visible, even collapsed)
            officeBar
                .frame(height: 26)
                .background(Color(red: 15/255, green: 16/255, blue: 32/255))

            // Canvas (hidden when collapsed)
            if appState.officePanelSnap != .collapsed {
                OfficeCanvasView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 25/255, green: 26/255, blue: 46/255))
            }
        }
    }

    private var officeBar: some View {
        HStack(spacing: 6) {
            Text("OFFICE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.66)
                .foregroundStyle(.white.opacity(0.25))

            if let project = appState.selectedProject {
                Text("— \(project.name)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.15))

                // Cluster dot groups
                ForEach(appState.rootAgents) { root in
                    HStack(spacing: 2) {
                        Circle()
                            .fill(agentDotColor(root.status))
                            .frame(width: 5, height: 5)
                        ForEach(appState.subAgents(for: root.id)) { sub in
                            Circle()
                                .fill(agentDotColor(sub.status))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.leading, 4)
                }
            }

            Spacer()

            // Click to restore from collapsed
            if appState.officePanelSnap == .collapsed {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        appState.snapOfficePanel(to: .ambient)
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 12)
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
