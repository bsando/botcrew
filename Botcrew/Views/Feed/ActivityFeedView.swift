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
        let events = appState.eventsForSelectedAgent
        if events.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                if appState.selectedAgentId == nil {
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
                        ToolCardView(event: event)

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
