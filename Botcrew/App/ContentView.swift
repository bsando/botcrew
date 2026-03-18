// ContentView.swift
// Botcrew

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HSplitView {
            if !appState.isSidebarCollapsed {
                SidebarView()
                    .frame(width: 168)
                    .background(Color(white: 30/255, opacity: 0.7))
            } else {
                CollapsedSidebarView()
                    .frame(width: 44)
                    .background(Color(white: 30/255, opacity: 0.7))
            }

            VStack(spacing: 0) {
                MacFrameView()

                TabBarView()
                    .frame(height: 38)

                Divider()
                    .opacity(0.08)

                ActivityFeedView()
                    .frame(maxHeight: .infinity)

                DragDividerView()

                OfficePanelView()
                    .frame(height: appState.officePanelHeight)
            }
        }
    }
}
