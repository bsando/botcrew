// DragDividerView.swift
// Botcrew

import SwiftUI

struct DragDividerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var dragStartHeight: CGFloat = 0

    var body: some View {
        ZStack {
            // Background fill for the entire divider area
            Rectangle()
                .fill(Theme.separator(colorScheme).opacity(isHovered ? 0.75 : 0.25))

            // Top edge line
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.separator(colorScheme).opacity(isHovered ? 2.5 : 1.25))
                    .frame(height: 1)
                Spacer()
            }

            // Grab handle — three small dots
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Theme.iconDefault(colorScheme).opacity(isHovered ? 1.0 : 0.45))
                        .frame(width: 4, height: 4)
                }
            }

            // Snap buttons on hover (replace dots)
            if isHovered {
                HStack(spacing: 16) {
                    snapButton("chevron.up.2", snap: .expanded, label: "Expand")
                    snapButton("minus", snap: .ambient, label: "Ambient")
                    snapButton("chevron.down.2", snap: .collapsed, label: "Collapse")
                }
                .transition(.opacity)
            }
        }
        .frame(height: 26)
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
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.iconDefault(colorScheme))
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
