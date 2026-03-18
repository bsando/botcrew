// DragDividerView.swift
// Botcrew

import SwiftUI

struct DragDividerView: View {
    @State private var isHovered = false

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(isHovered ? 0.12 : 0.04))
            .frame(height: 6)
            .onHover { hovering in
                isHovered = hovering
            }
            .cursor(.resizeUpDown)
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
