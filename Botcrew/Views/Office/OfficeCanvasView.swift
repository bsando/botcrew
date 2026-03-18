// OfficeCanvasView.swift
// Botcrew

import SwiftUI

// Layout data for a positioned sprite in the office
struct SpriteLayout: Identifiable {
    let id: UUID
    let agent: Agent
    let center: CGPoint
    let isRoot: Bool
    let rootCenter: CGPoint? // for tether line (subs only)
}

struct OfficeCanvasView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GeometryReader { geo in
            let layouts = computeLayouts(in: geo.size)

            Canvas { context, size in
                drawClusters(context: &context, layouts: layouts, size: size)
            }
            .overlay {
                // Invisible tap targets for each sprite
                ForEach(layouts) { sprite in
                    Color.clear
                        .frame(width: 40, height: 50)
                        .contentShape(Rectangle())
                        .position(sprite.center)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                appState.selectAgent(sprite.id)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Layout computation

    private func computeLayouts(in size: CGSize) -> [SpriteLayout] {
        let roots = appState.rootAgents
        guard !roots.isEmpty else { return [] }

        var layouts: [SpriteLayout] = []
        let clusterCount = CGFloat(roots.count)
        let clusterWidth = size.width / clusterCount

        for (i, root) in roots.enumerated() {
            let clusterCenterX = clusterWidth * (CGFloat(i) + 0.5)
            let rootY = size.height * 0.35
            let rootCenter = CGPoint(x: clusterCenterX, y: rootY)

            layouts.append(SpriteLayout(
                id: root.id, agent: root, center: rootCenter,
                isRoot: true, rootCenter: nil
            ))

            let subs = appState.subAgents(for: root.id)
            let subY = size.height * 0.7
            let subSpacing: CGFloat = 50
            let totalSubWidth = CGFloat(subs.count - 1) * subSpacing
            let subStartX = clusterCenterX - totalSubWidth / 2

            for (j, sub) in subs.enumerated() {
                let subCenter = CGPoint(
                    x: subStartX + CGFloat(j) * subSpacing,
                    y: subY
                )
                layouts.append(SpriteLayout(
                    id: sub.id, agent: sub, center: subCenter,
                    isRoot: false, rootCenter: rootCenter
                ))
            }
        }

        return layouts
    }

    // MARK: - Drawing

    private func drawClusters(context: inout GraphicsContext, layouts: [SpriteLayout], size: CGSize) {
        let roots = appState.rootAgents
        let clusterWidth = roots.isEmpty ? size.width : size.width / CGFloat(roots.count)
        let pixelScale: CGFloat = 3.5

        for (i, root) in roots.enumerated() {
            let isActive = appState.activeClusterId == root.id
            let clusterOpacity = isActive ? 1.0 : 0.45

            // Draw cluster zone rect (faint dashed border + tinted bg)
            let zoneRect = CGRect(
                x: clusterWidth * CGFloat(i) + 8,
                y: 8,
                width: clusterWidth - 16,
                height: size.height - 16
            )
            drawClusterZone(context: &context, rect: zoneRect, color: root.bodyColor, opacity: clusterOpacity)

            // Get sprites for this cluster
            let clusterLayouts = layouts.filter { layout in
                layout.agent.id == root.id || layout.agent.parentId == root.id
            }

            // Draw tether lines (subs → root)
            for layout in clusterLayouts where !layout.isRoot {
                if let rootCenter = layout.rootCenter {
                    drawTether(context: &context, from: layout.center, to: rootCenter, opacity: clusterOpacity)
                }
            }

            // Draw sprites
            for layout in clusterLayouts {
                let isError = layout.agent.status == .error
                let spriteOpacity = isError ? 1.0 : clusterOpacity
                let isSelected = appState.selectedAgentId == layout.agent.id

                drawSprite(
                    context: &context,
                    center: layout.center,
                    agent: layout.agent,
                    scale: pixelScale,
                    opacity: spriteOpacity
                )

                // Status dot (6px, top-right of sprite)
                drawStatusDot(context: &context, center: layout.center, status: layout.agent.status, scale: pixelScale, opacity: spriteOpacity)

                // Selection ring
                if isSelected {
                    drawSelectionRing(context: &context, center: layout.center, scale: pixelScale)
                }

                // Agent name label (only for active cluster)
                if isActive {
                    drawNameLabel(context: &context, center: layout.center, name: layout.agent.name, scale: pixelScale, opacity: spriteOpacity)
                }
            }
        }
    }

    private func drawClusterZone(context: inout GraphicsContext, rect: CGRect, color: Color, opacity: Double) {
        let path = Path(roundedRect: rect, cornerRadius: 8)
        context.fill(path, with: .color(color.opacity(0.04 * opacity)))
        context.stroke(
            path,
            with: .color(color.opacity(0.12 * opacity)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )
    }

    private func drawTether(context: inout GraphicsContext, from: CGPoint, to: CGPoint, opacity: Double) {
        var path = Path()
        path.move(to: from)
        // Quadratic curve upward
        let controlPoint = CGPoint(
            x: (from.x + to.x) / 2,
            y: min(from.y, to.y) - 15
        )
        path.addQuadCurve(to: to, control: controlPoint)
        context.stroke(
            path,
            with: .color(Color.white.opacity(0.1 * opacity)),
            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
        )
    }

    private func drawSprite(context: inout GraphicsContext, center: CGPoint, agent: Agent, scale: CGFloat, opacity: Double) {
        let grid = SpriteData.shape(for: agent.status)
        let gridW = CGFloat(SpriteData.gridWidth)
        let gridH = CGFloat(SpriteData.gridHeight)
        let originX = center.x - (gridW * scale) / 2
        let originY = center.y - (gridH * scale) / 2

        for (row, cols) in grid.enumerated() {
            for (col, val) in cols.enumerated() {
                guard val != 0 else { continue }
                let color: Color
                switch val {
                case 2: color = Color(red: 26/255, green: 28/255, blue: 44/255) // eyes
                case 3: color = agent.bodyColor.opacity(0.7) // accent
                case 6: color = Color(hex: 0xFF5F57) // X-eyes (error)
                default: color = agent.bodyColor // body
                }
                let rect = CGRect(
                    x: originX + CGFloat(col) * scale,
                    y: originY + CGFloat(row) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color.opacity(opacity)))
            }
        }
    }

    private func drawStatusDot(context: inout GraphicsContext, center: CGPoint, status: AgentStatus, scale: CGFloat, opacity: Double) {
        let spriteWidth = CGFloat(SpriteData.gridWidth) * scale
        let spriteHeight = CGFloat(SpriteData.gridHeight) * scale
        let dotCenter = CGPoint(
            x: center.x + spriteWidth / 2 - 2,
            y: center.y - spriteHeight / 2 + 2
        )
        let dotColor: Color = switch status {
        case .typing, .reading: Color(hex: 0x28C840)
        case .waiting: Color(hex: 0xFEBC2E)
        case .idle: Color(hex: 0x888780)
        case .error: Color(hex: 0xFF5F57)
        }
        let dotPath = Path(ellipseIn: CGRect(x: dotCenter.x - 3, y: dotCenter.y - 3, width: 6, height: 6))
        context.fill(dotPath, with: .color(dotColor.opacity(opacity)))
    }

    private func drawSelectionRing(context: inout GraphicsContext, center: CGPoint, scale: CGFloat) {
        let spriteWidth = CGFloat(SpriteData.gridWidth) * scale
        let spriteHeight = CGFloat(SpriteData.gridHeight) * scale
        let ringRect = CGRect(
            x: center.x - spriteWidth / 2 - 4,
            y: center.y - spriteHeight / 2 - 4,
            width: spriteWidth + 8,
            height: spriteHeight + 8
        )
        let ringPath = Path(roundedRect: ringRect, cornerRadius: 4)
        context.stroke(
            ringPath,
            with: .color(Color(hex: 0x0A84FF).opacity(0.5)),
            lineWidth: 1.5
        )
    }

    private func drawNameLabel(context: inout GraphicsContext, center: CGPoint, name: String, scale: CGFloat, opacity: Double) {
        let spriteHeight = CGFloat(SpriteData.gridHeight) * scale
        let labelY = center.y + spriteHeight / 2 + 10
        let text = Text(name)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.6 * opacity))
        context.draw(text, at: CGPoint(x: center.x, y: labelY))
    }
}
