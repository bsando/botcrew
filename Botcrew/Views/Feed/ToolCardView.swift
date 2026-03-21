// ToolCardView.swift
// Botcrew

import SwiftUI

struct ToolCardView: View {
    let event: ActivityEvent
    @State private var isExpanded = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row (always visible)
            Button {
                if hasExpandableContent {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: eventIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(eventColor)
                        .frame(width: 20, height: 20)

                    Text(eventTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(eventColor)

                    if let file = event.file {
                        Text(shortenPath(file))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }

                    if let meta = event.meta, event.file == nil {
                        Text(meta)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }

                    Spacer()

                    if hasExpandableContent {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.25))
                    }

                    Text(Self.timeFormatter.string(from: event.timestamp))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Expanded detail
            if isExpanded {
                expandedContent
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
    }

    private var hasExpandableContent: Bool {
        switch event.type {
        case .write: event.content != nil || event.oldString != nil
        case .bash: event.command != nil
        case .read: false
        case .error: event.meta != nil
        default: false
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        switch event.type {
        case .write:
            if let oldString = event.oldString, let newString = event.content {
                // Edit: show diff
                DiffBlock(oldString: oldString, newString: newString)
            } else if let content = event.content {
                // Write: show content
                CodeBlock(text: content, color: eventColor)
            }

        case .bash:
            if let cmd = event.command {
                CodeBlock(text: cmd, color: eventColor, label: "command")
            }
            if let output = event.commandOutput {
                CodeBlock(text: output, color: .white.opacity(0.5), label: "output")
            }

        case .error:
            if let meta = event.meta {
                CodeBlock(text: meta, color: eventColor, label: "error")
            }

        default:
            EmptyView()
        }
    }

    private func shortenPath(_ path: String) -> String {
        let components = path.split(separator: "/")
        if components.count <= 3 { return path }
        return ".../" + components.suffix(2).joined(separator: "/")
    }

    private var eventIcon: String {
        switch event.type {
        case .spawn: "sparkle"
        case .write: "doc.badge.arrow.up"
        case .read: "doc.badge.arrow.down"
        case .bash: "terminal"
        case .thinking: "brain"
        case .error: "exclamationmark.triangle"
        }
    }

    private var eventTitle: String {
        switch event.type {
        case .spawn: "Spawn"
        case .write: event.oldString != nil ? "Edit" : "Write"
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

// MARK: - Code Block

struct CodeBlock: View {
    let text: String
    var color: Color = .white.opacity(0.6)
    var label: String?
    private let maxLines = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(color.opacity(0.5))
                    .tracking(0.5)
            }

            let lines = text.components(separatedBy: .newlines)
            let truncated = lines.count > maxLines
            let displayText = truncated
                ? lines.prefix(maxLines).joined(separator: "\n") + "\n... (\(lines.count) lines)"
                : text

            Text(displayText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.04))
                )
        }
        .padding(.top, 2)
    }
}

// MARK: - Diff Block

struct DiffBlock: View {
    let oldString: String
    let newString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Removed lines
            ForEach(Array(oldString.components(separatedBy: .newlines).prefix(8).enumerated()), id: \.offset) { _, line in
                Text("- " + line)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xFF5F57).opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 1)
                    .background(Color(hex: 0xFF5F57).opacity(0.06))
            }

            // Added lines
            ForEach(Array(newString.components(separatedBy: .newlines).prefix(8).enumerated()), id: \.offset) { _, line in
                Text("+ " + line)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: 0x34d399).opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 1)
                    .background(Color(hex: 0x34d399).opacity(0.06))
            }
        }
        .textSelection(.enabled)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.top, 2)
    }
}
