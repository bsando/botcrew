// TabBarView.swift
// Botcrew

import SwiftUI

struct TabBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var editingAgentId: UUID?
    @State private var editText: String = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                if appState.rootAgents.isEmpty {
                    Text("No agents")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                        .padding(.horizontal, 16)
                } else {
                    ForEach(appState.rootAgents) { root in
                        let subs = appState.subAgents(for: root.id)
                        let isExpanded = appState.activeClusterId == root.id

                        HStack(spacing: 2) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    appState.toggleCluster(root.id)
                                }
                            } label: {
                                RootTabView(
                                    agent: root,
                                    subAgents: subs,
                                    isExpanded: isExpanded,
                                    isSelected: appState.selectedAgentId == root.id,
                                    isEditing: editingAgentId == root.id,
                                    editText: $editText,
                                    onCommitRename: { commitRename(root.id) }
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Rename") { startEditing(root) }
                            }

                            if isExpanded {
                                ForEach(subs) { sub in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            appState.selectAgent(sub.id)
                                        }
                                    } label: {
                                        SubTabView(
                                            agent: sub,
                                            isSelected: appState.selectedAgentId == sub.id,
                                            isEditing: editingAgentId == sub.id,
                                            editText: $editText,
                                            onCommitRename: { commitRename(sub.id) }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Rename") { startEditing(sub) }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.tabBarBg(colorScheme))
    }

    private func startEditing(_ agent: Agent) {
        editText = agent.name
        editingAgentId = agent.id
    }

    private func commitRename(_ agentId: UUID) {
        appState.renameAgent(agentId, to: editText)
        editingAgentId = nil
    }
}
