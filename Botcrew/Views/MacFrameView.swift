// MacFrameView.swift
// Botcrew

import SwiftUI

struct MacFrameView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            Text("BotCrew")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary(colorScheme))

            Spacer()
        }
        .frame(height: 36)
        .background(
            colorScheme == .dark
                ? Color(white: 40/255, opacity: 0.95)
                : Color(white: 240/255, opacity: 0.95)
        )
    }
}
