// SpriteRenderer.swift
// Botcrew

import SwiftUI

enum SpriteThumbnailSize {
    case root  // 12x16
    case sub   // 10x14

    var width: CGFloat {
        switch self {
        case .root: 12
        case .sub: 10
        }
    }

    var height: CGFloat {
        switch self {
        case .root: 16
        case .sub: 14
        }
    }

    var pixelScale: CGFloat {
        switch self {
        case .root: 1.5
        case .sub: 1.25
        }
    }
}

struct SpriteThumbnail: View {
    let bodyColor: Color
    let size: SpriteThumbnailSize

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size.pixelScale
            let grid = SpriteData.body
            let gridW = CGFloat(grid[0].count)
            let gridH = CGFloat(grid.count)
            let offsetX = (canvasSize.width - gridW * scale) / 2
            let offsetY = (canvasSize.height - gridH * scale) / 2

            for (row, cols) in grid.enumerated() {
                for (col, val) in cols.enumerated() {
                    guard val != 0 else { continue }
                    let color: Color = switch val {
                    case 2: Color(red: 26/255, green: 28/255, blue: 44/255) // eyes
                    case 3: bodyColor.opacity(0.7) // accent
                    default: bodyColor // body
                    }
                    let rect = CGRect(
                        x: offsetX + CGFloat(col) * scale,
                        y: offsetY + CGFloat(row) * scale,
                        width: scale,
                        height: scale
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
