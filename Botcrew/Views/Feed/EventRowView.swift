// EventRowView.swift
// Botcrew

import SwiftUI

struct EventRowView: View {
    let event: ActivityEvent

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Event type icon
            Text(eventIcon)
                .font(.system(size: 14))
                .frame(width: 20, height: 20)
                .foregroundStyle(eventColor)

            VStack(alignment: .leading, spacing: 2) {
                // Primary text
                HStack(spacing: 6) {
                    Text(eventTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))

                    if let file = event.file {
                        Text(file)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(eventColor.opacity(0.8))
                    }
                }

                // Meta / sub-text
                if let meta = event.meta {
                    Text(meta)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(2)
                }
            }

            Spacer()

            // Timestamp
            Text(Self.timeFormatter.string(from: event.timestamp))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var eventIcon: String {
        switch event.type {
        case .spawn: "⬡"
        case .write: "↑"
        case .read: "↓"
        case .bash: "$"
        case .thinking: "·"
        case .error: "!"
        }
    }

    private var eventTitle: String {
        switch event.type {
        case .spawn: "Spawn"
        case .write: "Write"
        case .read: "Read"
        case .bash: "Bash"
        case .thinking: "Thinking"
        case .error: "Error"
        }
    }

    private var eventColor: Color {
        switch event.type {
        case .spawn: Color(hex: 0xc0a8ff)
        case .write: Color(hex: 0x34d399)
        case .read: Color(hex: 0x60a5fa)
        case .bash: Color(hex: 0xfbbf24)
        case .thinking: Color(hex: 0x888780)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}
