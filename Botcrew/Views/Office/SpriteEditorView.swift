// SpriteEditorView.swift
// Botcrew

import SwiftUI

struct SpriteEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let agentName: String
    let bodyColor: Color

    @State private var shapes: SpriteShapeSet
    @State private var selectedPose: Pose = .body
    @State private var selectedPixelValue: Int = 1

    enum Pose: String, CaseIterable {
        case body = "Idle"
        case type = "Typing"
        case shrug = "Waiting"
        case error = "Error"
    }

    init(agentName: String, bodyColor: Color, initial: SpriteShapeSet) {
        self.agentName = agentName
        self.bodyColor = bodyColor
        _shapes = State(initialValue: initial)
    }

    private var currentGrid: [[Int]] {
        switch selectedPose {
        case .body: shapes.body
        case .type: shapes.type
        case .shrug: shapes.shrug
        case .error: shapes.error
        }
    }

    private let cellSize: CGFloat = 28
    private let gridWidth = 8
    private let gridHeight = 10

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Sprite — \(agentName)")
                .font(.system(size: 15, weight: .semibold))

            // Pose tabs
            Picker("Pose", selection: $selectedPose) {
                ForEach(Pose.allCases, id: \.self) { pose in
                    Text(pose.rawValue).tag(pose)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            HStack(alignment: .top, spacing: 20) {
                // Pixel grid
                VStack(spacing: 0) {
                    ForEach(0..<gridHeight, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<gridWidth, id: \.self) { col in
                                let val = currentGrid[row][col]
                                Rectangle()
                                    .fill(colorForPixel(val))
                                    .frame(width: cellSize, height: cellSize)
                                    .border(Color.white.opacity(0.1), width: 0.5)
                                    .onTapGesture {
                                        setPixel(row: row, col: col)
                                    }
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let col = Int(value.location.x / cellSize)
                            let row = Int(value.location.y / cellSize)
                            if row >= 0, row < gridHeight, col >= 0, col < gridWidth {
                                setPixel(row: row, col: col)
                            }
                        }
                )
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // Tool palette + preview
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PAINT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)

                        ForEach([0, 1, 2, 3, 6], id: \.self) { val in
                            Button {
                                selectedPixelValue = val
                            } label: {
                                HStack(spacing: 8) {
                                    Rectangle()
                                        .fill(colorForPixel(val))
                                        .frame(width: 20, height: 20)
                                        .border(selectedPixelValue == val
                                                ? Color.white : Color.clear, width: 2)
                                        .clipShape(RoundedRectangle(cornerRadius: 2))

                                    Text(labelForPixel(val))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider()

                    // Live preview at actual scale
                    VStack(spacing: 4) {
                        Text("PREVIEW")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)

                        HStack(spacing: 12) {
                            ForEach(Pose.allCases, id: \.self) { pose in
                                let grid = gridForPose(pose)
                                miniPreview(grid: grid)
                            }
                        }
                    }
                }
            }

            HStack {
                Button("Reset to Theme") {
                    shapes = appState.selectedTheme.shapes
                }
                .controlSize(.small)

                Spacer()

                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Save") {
                    if let pid = appState.selectedProjectId {
                        appState.setCustomSprite(projectId: pid, agentName: agentName, shapes: shapes)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private func setPixel(row: Int, col: Int) {
        switch selectedPose {
        case .body: shapes.body[row][col] = selectedPixelValue
        case .type: shapes.type[row][col] = selectedPixelValue
        case .shrug: shapes.shrug[row][col] = selectedPixelValue
        case .error: shapes.error[row][col] = selectedPixelValue
        }
    }

    private func colorForPixel(_ val: Int) -> Color {
        switch val {
        case 0: Color.clear
        case 1: bodyColor
        case 2: Color(red: 26/255, green: 28/255, blue: 44/255)
        case 3: bodyColor.opacity(0.7)
        case 6: Color(hex: 0xFF5F57)
        default: Color.gray
        }
    }

    private func labelForPixel(_ val: Int) -> String {
        switch val {
        case 0: "Erase"
        case 1: "Body"
        case 2: "Eyes"
        case 3: "Accent"
        case 6: "X-Eyes"
        default: "?"
        }
    }

    private func gridForPose(_ pose: Pose) -> [[Int]] {
        switch pose {
        case .body: shapes.body
        case .type: shapes.type
        case .shrug: shapes.shrug
        case .error: shapes.error
        }
    }

    private func miniPreview(grid: [[Int]]) -> some View {
        Canvas { context, size in
            let scale: CGFloat = 2.5
            let gridW = CGFloat(gridWidth)
            let gridH = CGFloat(gridHeight)
            let offsetX = (size.width - gridW * scale) / 2
            let offsetY = (size.height - gridH * scale) / 2

            for (row, cols) in grid.enumerated() {
                for (col, val) in cols.enumerated() {
                    guard val != 0 else { continue }
                    let rect = CGRect(
                        x: offsetX + CGFloat(col) * scale,
                        y: offsetY + CGFloat(row) * scale,
                        width: scale, height: scale
                    )
                    context.fill(Path(rect), with: .color(colorForPixel(val)))
                }
            }
        }
        .frame(width: 24, height: 30)
    }
}
