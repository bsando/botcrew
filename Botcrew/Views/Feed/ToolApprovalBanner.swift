// ToolApprovalBanner.swift
// Botcrew

import SwiftUI

struct ToolApprovalBanner: View {
    @Environment(AppState.self) private var appState
    let approval: ToolApproval

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0xFEBC2E))

                Text("Permission Required")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if isExpanded {
                Divider().opacity(0.15)

                // Tool denials list
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(approval.denials) { denial in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: toolIcon(denial.toolName))
                                    .font(.system(size: 11))
                                    .foregroundStyle(toolColor(denial.toolName))

                                Text(denial.summary)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .lineLimit(2)
                            }

                            if let detail = denial.detail {
                                Text(detail)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.45))
                                    .lineLimit(6)
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().opacity(0.15)

                // Action buttons
                HStack(spacing: 8) {
                    Spacer()

                    Button("Deny") {
                        appState.denyApproval()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.08))
                    )

                    Button("Allow & Continue") {
                        appState.approveAndContinue()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: 0x0A84FF))
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Color(hex: 0xFEBC2E).opacity(0.08))
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xFEBC2E).opacity(0.3))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func toolIcon(_ name: String) -> String {
        switch name {
        case "Write": "doc.badge.plus"
        case "Edit": "pencil"
        case "Bash": "terminal"
        case "NotebookEdit": "book"
        default: "wrench"
        }
    }

    private func toolColor(_ name: String) -> Color {
        switch name {
        case "Write": Color(hex: 0x34d399)
        case "Edit": Color(hex: 0x60a5fa)
        case "Bash": Color(hex: 0xFEBC2E)
        default: Color.white.opacity(0.55)
        }
    }
}
