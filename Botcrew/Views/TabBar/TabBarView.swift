// TabBarView.swift
// Botcrew

import SwiftUI

struct TabBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            if let project = appState.selectedProject, !project.agents.isEmpty {
                let roots = project.agents.filter { $0.parentId == nil }
                ForEach(roots) { agent in
                    Text(agent.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(white: 50/255, opacity: 0.8))
                        )
                        .padding(.leading, 8)
                }
            } else {
                Text("No agents")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 16)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 40/255, opacity: 0.8))
    }
}
