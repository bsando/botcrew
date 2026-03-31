// ActivityFeedView.swift
// Botcrew

import SwiftUI

struct ActivityFeedView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            FeedHeaderView()

            Divider()
                .opacity(0.08)

            if appState.showTerminal {
                TerminalView()
            } else {
                feedContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.contentBg(colorScheme))
    }

    @ViewBuilder
    private var feedContent: some View {
        let events = appState.showAllAgentsFeed
            ? appState.eventsForAllAgents
            : appState.eventsForSelectedAgent

        if events.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                if appState.showAllAgentsFeed {
                    Text("No activity in this project yet")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                } else if appState.selectedAgentId == nil {
                    Text("Select an agent to view activity")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                } else {
                    Text("No activity yet")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(events) { event in
                        if appState.showAllAgentsFeed {
                            // In cross-agent mode, show agent badge on each event
                            CrossAgentToolCard(event: event)
                        } else {
                            ToolCardView(event: event)
                        }

                        Divider()
                            .padding(.leading, 40)
                            .opacity(0.06)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Cross-Agent Tool Card (wraps ToolCardView with agent badge)

struct CrossAgentToolCard: View {
    let event: ActivityEvent
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var agent: Agent? {
        appState.selectedProject?.agents.first { $0.id == event.agentId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Agent badge
            if let agent = agent {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(agent.bodyColor)
                        .frame(width: 6, height: 6)
                    Text(agent.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(agent.bodyColor.opacity(0.8))
                }
                .padding(.leading, 12)
                .padding(.top, 4)
                .onTapGesture {
                    appState.selectAgent(agent.id)
                    appState.showAllAgentsFeed = false
                }
            }

            ToolCardView(event: event)
        }
    }
}
