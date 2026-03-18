// ActivityFeedView.swift
// Botcrew

import SwiftUI

struct ActivityFeedView: View {
    @Environment(AppState.self) private var appState

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
        .background(Color(white: 30/255, opacity: 0.6))
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
                        .foregroundStyle(.white.opacity(0.35))
                } else {
                    Text("No activity yet")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(events) { event in
                        EventRowView(event: event)

                        Divider()
                            .padding(.leading, 46)
                            .opacity(0.06)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
