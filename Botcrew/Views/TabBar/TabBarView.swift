// TabBarView.swift
// Botcrew

import SwiftUI

struct TabBarView: View {
    @Environment(AppState.self) private var appState
    @State private var editingAgentId: UUID?
    @State private var editText: String = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                if appState.rootAgents.isEmpty {
                    Text("No agents")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.horizontal, 16)
                } else {
                    ForEach(appState.rootAgents) { root in
                        let subs = appState.subAgents(for: root.id)
                        let isExpanded = appState.activeClusterId == root.id

                        HStack(spacing: 2) {
                            let isEditingRoot = editingAgentId == root.id

                            RootTabView(
                                agent: root,
                                subAgents: subs,
                                isExpanded: isExpanded,
                                isSelected: appState.selectedAgentId == root.id,
                                isEditing: isEditingRoot,
                                editText: $editText,
                                onCommitRename: { commitRename(root.id) }
                            )
                            .onTapGesture {
                                guard !isEditingRoot else { return }
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    appState.toggleCluster(root.id)
                                }
                            }
                            .onDoubleClick(disabled: isEditingRoot) { startEditing(root) }
                            .contextMenu {
                                Button("Rename") { startEditing(root) }
                            }

                            if isExpanded {
                                ForEach(subs) { sub in
                                    let isEditingSub = editingAgentId == sub.id

                                    SubTabView(
                                        agent: sub,
                                        isSelected: appState.selectedAgentId == sub.id,
                                        isEditing: isEditingSub,
                                        editText: $editText,
                                        onCommitRename: { commitRename(sub.id) }
                                    )
                                    .onTapGesture {
                                        guard !isEditingSub else { return }
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            appState.selectAgent(sub.id)
                                        }
                                    }
                                    .onDoubleClick(disabled: isEditingSub) { startEditing(sub) }
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
        .background(Color(white: 40/255, opacity: 0.8))
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

// MARK: - Double Click Modifier

struct DoubleClickModifier: ViewModifier {
    let isDisabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if !isDisabled {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, perform: action)
                    .allowsHitTesting(true)
            }
        }
    }
}

extension View {
    func onDoubleClick(disabled: Bool = false, perform action: @escaping () -> Void) -> some View {
        modifier(DoubleClickModifier(isDisabled: disabled, action: action))
    }
}
