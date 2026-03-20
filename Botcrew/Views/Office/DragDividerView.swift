// DragDividerView.swift
// Botcrew

import SwiftUI

struct DragDividerView: View {
    @Environment(AppState.self) private var appState
    @State private var isHovered = false
    @State private var dragStartHeight: CGFloat = 0

    var body: some View {
        ZStack {
            // Visible line (thin)
            Rectangle()
                .fill(Color.white.opacity(isHovered ? 0.12 : 0.04))
                .frame(height: 2)

            // Snap buttons on hover
            if isHovered {
                HStack(spacing: 16) {
                    snapButton("chevron.up.2", snap: .expanded, label: "Expand")
                    snapButton("minus", snap: .ambient, label: "Ambient")
                    snapButton("chevron.down.2", snap: .collapsed, label: "Collapse")
                }
                .transition(.opacity)
            }
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragStartHeight == 0 {
                        dragStartHeight = appState.officePanelHeight
                    }
                    // Dragging up increases panel height
                    let newHeight = dragStartHeight - value.translation.height
                    appState.officePanelHeight = max(26, min(270, newHeight))
                }
                .onEnded { _ in
                    dragStartHeight = 0
                    // Snap to nearest
                    withAnimation(.easeOut(duration: 0.2)) {
                        appState.snapOfficePanel(to: appState.officePanelSnap)
                    }
                }
        )
        .cursor(.resizeUpDown)
    }

    private func snapButton(_ icon: String, snap: AppState.OfficePanelSnap, label: String) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                appState.snapOfficePanel(to: snap)
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
