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

// Animation parameters per status
struct BobParams {
    let frequency: Double  // cycles per second
    let amplitude: CGFloat // pixels

    static func forStatus(_ status: AgentStatus) -> BobParams {
        switch status {
        case .typing: BobParams(frequency: 1.0 / 0.45, amplitude: 1.5)
        case .reading: BobParams(frequency: 1.0 / 1.0, amplitude: 0.8)
        case .idle: BobParams(frequency: 1.0 / 1.3, amplitude: 0.6)
        case .waiting: BobParams(frequency: 1.0 / 2.0, amplitude: 0.9)
        case .error: BobParams(frequency: 12.0, amplitude: 0.5)
        }
    }
}

struct OfficeCanvasView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffsets: [UUID: CGSize] = [:]

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geo in
                let layouts = computeLayouts(in: geo.size)

                Canvas { context, size in
                    // Apply drag offsets to layouts for rendering
                    let adjustedLayouts = layouts.map { layout -> SpriteLayout in
                        if let offset = dragOffsets[layout.id] {
                            let newCenter = CGPoint(
                                x: layout.center.x + offset.width,
                                y: layout.center.y + offset.height
                            )
                            return SpriteLayout(
                                id: layout.id, agent: layout.agent,
                                center: newCenter, isRoot: layout.isRoot,
                                rootCenter: layout.rootCenter
                            )
                        }
                        return layout
                    }
                    drawClusters(context: &context, layouts: adjustedLayouts, size: size, time: time)
                }
                .overlay {
                    ForEach(layouts) { sprite in
                        let dragOffset = dragOffsets[sprite.id] ?? .zero
                        let displayPos = CGPoint(
                            x: sprite.center.x + dragOffset.width,
                            y: sprite.center.y + dragOffset.height
                        )
                        Color.clear
                            .frame(width: 56, height: 60)
                            .contentShape(Rectangle())
                            .position(displayPos)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffsets[sprite.id] = value.translation
                                    }
                                    .onEnded { value in
                                        let finalX = sprite.center.x + value.translation.width
                                        let finalY = sprite.center.y + value.translation.height
                                        let normalized = NormalizedPoint(
                                            x: Double(finalX / geo.size.width),
                                            y: Double(finalY / geo.size.height)
                                        )
                                        if let pid = appState.selectedProjectId {
                                            appState.setSpritePosition(
                                                projectId: pid,
                                                agentName: sprite.agent.name,
                                                normalizedPos: normalized
                                            )
                                        }
                                        dragOffsets.removeValue(forKey: sprite.id)
                                    }
                            )
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    appState.selectAgent(sprite.id)
                                    if sprite.agent.status == .error {
                                        appState.showTerminal = true
                                    }
                                }
                            )
                    }
                }
            }
        }
    }

    // MARK: - Bob calculation

    private func bobOffset(for agent: Agent, time: Double) -> CGFloat {
        let params = BobParams.forStatus(agent.status)
        let phase = Double(agent.id.hashValue & 0xFFFF) / 65535.0 * .pi * 2
        return CGFloat(sin(time * params.frequency * .pi * 2 + phase)) * params.amplitude
    }

    // MARK: - Layout computation

    private func computeLayouts(in size: CGSize) -> [SpriteLayout] {
        let roots = appState.rootAgents
        guard !roots.isEmpty else { return [] }

        let positions = appState.selectedProject?.officeLayout.spritePositions ?? [:]
        var layouts: [SpriteLayout] = []
        let clusterCount = CGFloat(roots.count)
        let clusterWidth = size.width / clusterCount

        for (i, root) in roots.enumerated() {
            let clusterCenterX = clusterWidth * (CGFloat(i) + 0.5)
            let defaultRootCenter = CGPoint(x: clusterCenterX, y: size.height * 0.35)

            let rootCenter: CGPoint
            if let saved = positions[root.name] {
                rootCenter = CGPoint(x: saved.x * Double(size.width), y: saved.y * Double(size.height))
            } else {
                rootCenter = defaultRootCenter
            }

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
                let subCenter: CGPoint
                if let saved = positions[sub.name] {
                    subCenter = CGPoint(x: saved.x * Double(size.width), y: saved.y * Double(size.height))
                } else {
                    subCenter = CGPoint(x: subStartX + CGFloat(j) * subSpacing, y: subY)
                }
                layouts.append(SpriteLayout(
                    id: sub.id, agent: sub, center: subCenter,
                    isRoot: false, rootCenter: rootCenter
                ))
            }
        }

        return layouts
    }

    // MARK: - Drawing

    private func drawClusters(context: inout GraphicsContext, layouts: [SpriteLayout], size: CGSize, time: Double) {
        let roots = appState.rootAgents
        let clusterWidth = roots.isEmpty ? size.width : size.width / CGFloat(roots.count)
        let pixelScale: CGFloat = 3.5

        for (i, root) in roots.enumerated() {
            let isActive = appState.activeClusterId == root.id
            let clusterOpacity = isActive ? 1.0 : 0.45

            // Draw cluster zone rect
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
                    let bobY = bobOffset(for: layout.agent, time: time)
                    let animatedCenter = CGPoint(x: layout.center.x, y: layout.center.y + bobY)
                    drawTether(context: &context, from: animatedCenter, to: rootCenter, opacity: clusterOpacity)
                }
            }

            // Draw sprites
            for layout in clusterLayouts {
                let isError = layout.agent.status == .error
                let spriteOpacity = isError ? 1.0 : clusterOpacity
                let isSelected = appState.selectedAgentId == layout.agent.id
                let bobY = bobOffset(for: layout.agent, time: time)
                let animatedCenter = CGPoint(x: layout.center.x, y: layout.center.y + bobY)

                // Error halo (pulsing radial gradient)
                if isError {
                    drawErrorHalo(context: &context, center: animatedCenter, scale: pixelScale, time: time)
                }

                // Sprite
                drawSprite(
                    context: &context,
                    center: animatedCenter,
                    agent: layout.agent,
                    scale: pixelScale,
                    opacity: spriteOpacity,
                    time: time
                )

                // Status dot
                drawStatusDot(context: &context, center: animatedCenter, status: layout.agent.status, scale: pixelScale, opacity: spriteOpacity)

                // Error ! badge
                if isError {
                    drawErrorBadge(context: &context, center: animatedCenter, scale: pixelScale)
                }

                // Selection ring
                if isSelected {
                    drawSelectionRing(context: &context, center: animatedCenter, scale: pixelScale)
                }

                // Bubbles (typing/waiting)
                if isActive || isError {
                    drawBubble(context: &context, center: animatedCenter, agent: layout.agent, scale: pixelScale, opacity: spriteOpacity)
                }

                // Agent name label (only for active cluster)
                if isActive {
                    drawNameLabel(context: &context, center: animatedCenter, name: layout.agent.name, scale: pixelScale, opacity: spriteOpacity)
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

    private func drawSprite(context: inout GraphicsContext, center: CGPoint, agent: Agent, scale: CGFloat, opacity: Double, time: Double) {
        let grid = SpriteData.shape(for: agent.status, theme: appState.selectedTheme)
        let gridW = CGFloat(SpriteData.gridWidth)
        let gridH = CGFloat(SpriteData.gridHeight)
        let originX = center.x - (gridW * scale) / 2
        let originY = center.y - (gridH * scale) / 2

        // Error flash: alternate body color with red at 12Hz
        let isErrorFlash = agent.status == .error && sin(time * 12 * .pi * 2) > 0

        for (row, cols) in grid.enumerated() {
            for (col, val) in cols.enumerated() {
                guard val != 0 else { continue }
                let color: Color
                switch val {
                case 2: color = Color(red: 26/255, green: 28/255, blue: 44/255)
                case 3: color = agent.bodyColor.opacity(0.7)
                case 6: color = Color(hex: 0xFF5F57)
                default: color = isErrorFlash ? Color(hex: 0xFF5F57) : agent.bodyColor
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

    private func drawErrorHalo(context: inout GraphicsContext, center: CGPoint, scale: CGFloat, time: Double) {
        let spriteWidth = CGFloat(SpriteData.gridWidth) * scale
        let spriteHeight = CGFloat(SpriteData.gridHeight) * scale
        let pulse = CGFloat(0.3 + 0.2 * sin(time * .pi * 2 / 1.5)) // 1.5s cycle
        let haloRect = CGRect(
            x: center.x - spriteWidth / 2 - 8,
            y: center.y - spriteHeight / 2 - 8,
            width: spriteWidth + 16,
            height: spriteHeight + 16
        )
        let haloPath = Path(ellipseIn: haloRect)
        context.fill(haloPath, with: .color(Color(hex: 0xFF5F57).opacity(Double(pulse) * 0.3)))
    }

    private func drawErrorBadge(context: inout GraphicsContext, center: CGPoint, scale: CGFloat) {
        let spriteHeight = CGFloat(SpriteData.gridHeight) * scale
        let badgeCenter = CGPoint(x: center.x, y: center.y - spriteHeight / 2 - 12)
        // Red pill background
        let badgeRect = CGRect(x: badgeCenter.x - 7, y: badgeCenter.y - 7, width: 14, height: 14)
        let badgePath = Path(ellipseIn: badgeRect)
        context.fill(badgePath, with: .color(Color(hex: 0xFF5F57)))
        // ! text
        let text = Text("!")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.white)
        context.draw(text, at: badgeCenter)
    }

    private func drawBubble(context: inout GraphicsContext, center: CGPoint, agent: Agent, scale: CGFloat, opacity: Double) {
        let spriteWidth = CGFloat(SpriteData.gridWidth) * scale
        let spriteHeight = CGFloat(SpriteData.gridHeight) * scale

        let bubbleText: String
        let bubbleColor: Color

        switch agent.status {
        case .typing:
            bubbleText = "typing..."
            bubbleColor = Color(hex: 0x34d399)
        case .waiting:
            bubbleText = "waiting"
            bubbleColor = Color(hex: 0xfbbf24)
        default:
            return
        }

        let bubbleX = center.x + spriteWidth / 2 + 6
        let bubbleY = center.y - spriteHeight / 2

        // Bubble background
        let text = Text(bubbleText)
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(bubbleColor.opacity(opacity))

        let bgRect = CGRect(x: bubbleX - 2, y: bubbleY - 7, width: CGFloat(bubbleText.count) * 5.5 + 8, height: 14)
        let bgPath = Path(roundedRect: bgRect, cornerRadius: 4)
        context.fill(bgPath, with: .color(Color(white: 0.1, opacity: 0.7 * opacity)))
        context.draw(text, at: CGPoint(x: bgRect.midX, y: bgRect.midY))
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
