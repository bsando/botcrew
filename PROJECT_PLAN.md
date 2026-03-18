# Botcrew — Project Plan

Native macOS app for visualizing and managing Claude Code multi-agent sessions. Pixel art office, activity feeds, bidirectional tab/sprite sync.

**Status**: Design complete → Build phase  
**Stack**: SwiftUI, SpriteKit/Canvas, Foundation Process  
**Reference**: Figma prototype (React/TypeScript) in `CLAUDE_CODE_REFERENCE.md`

---

## Phases

### Phase 0 — Scaffold (Week 1)
*Goal: app opens, window exists, no crashes. Claude Code handles all of this including Xcode project creation.*

- [ ] Create Xcode project — write `project.pbxproj` and required scaffolding directly:
  - App name: `Botcrew`, Bundle ID: `com.redwoodfog.botcrew`
  - SwiftUI lifecycle, macOS 14+ deployment target, Swift 5.10
- [ ] Run `./scripts/create_stubs.sh` to generate all Swift file stubs
- [ ] `BotcrewApp.swift`: `@main`, `WindowGroup`, `.frame(minWidth: 900, minHeight: 640)`
- [ ] `AppState.swift`: `@Observable` class — `selectedProjectId`, `selectedAgentId`, `activeClusterId`, `openTerminalIds`
- [ ] `ContentView.swift`: `HSplitView` → sidebar (168px fixed) + main column
- [ ] Mock data structs matching types in `CLAUDE_CODE_REFERENCE.md`
- [ ] `.preferredColorScheme(.dark)` on window
- [ ] Window background: `.background(.ultraThinMaterial)` with dark overlay `rgba(25,25,30,0.4)`
- [ ] `MacFrame` titlebar with interactive traffic lights (see `MacFrame.tsx` in `CLAUDE_CODE_REFERENCE.md`):
  - Default: 40% opacity all three dots
  - Window hover: 100% opacity
  - Individual button hover: show icon (×, —, ↕) at 100%, others 40%, 150ms animation
- [ ] Verify: `xcodebuild -scheme Botcrew -destination 'platform=macOS' build` passes 0 errors

**Deliverable**: `xcodebuild` passes. App launches. Sidebar + placeholder with macOS chrome visible.

---

### Phase 1 — Sidebar + Projects (Week 1–2)
*Goal: project switching works end-to-end with mock data.*

- [ ] `Project` model (id, name, path, status, agentCount, cost)
- [ ] `SidebarView`: project list, active highlight, status dot
- [ ] Add/remove project (sheet with directory picker)
- [ ] Project switching → clears tab strip, resets office
- [ ] Token/cost card at sidebar bottom (mock values)
- [ ] Collapsed sidebar state (icon-only, 44px)

**Deliverable**: Click projects → UI updates throughout.

---

### Phase 2 — Tab Bar + Agent Hierarchy (Week 2)
*Goal: tab clusters expand/collapse, selection syncs everywhere.*

- [ ] `Agent` model (id, name, parentId, status, bodyColor, shirtColor, anim)
- [ ] `TabBarView`: root tabs + sub-tab strips per cluster
- [ ] Cluster expand/collapse (only active cluster shows subtabs)
- [ ] Collapsed cluster: root tab + inline sub-status dots
- [ ] Tab selection state in `AppState`
- [ ] Sprite thumbnail canvases in tabs (12×16 root, 10×14 sub)
- [ ] Tab ↔ sprite bidirectional selection hook (prep for Phase 4)

**Deliverable**: Full tab bar interaction with mock agents.

---

### Phase 3 — Activity Feed (Week 2–3)
*Goal: feed shows structured events, terminal view toggles in.*

- [ ] `ActivityEvent` model (timestamp, type, agentId, file, meta)
- [ ] `ActivityFeedView`: event list with icon, text, sub-text
- [ ] Event type icons: spawn (⬡), write (↑), read (↓), bash ($), thinking (·)
- [ ] Feed header: colored swatch, agent name, role, status pill
- [ ] Thinking state: animated dots
- [ ] Activity/Terminal toggle in feed header
- [ ] Terminal view: raw text output (mock static content for now)
- [ ] Feed scoped to selected agent

**Deliverable**: Click tab → see that agent's activity feed.

---

### Phase 4 — Pixel Office Panel (Week 3–4)
*Goal: sprites render, animate, and sync with tabs.*

- [ ] `OfficePanelView` wrapper with draggable height divider
- [ ] Three snap states: collapsed (26px), ambient (148px), expanded (270px)
- [ ] Snap buttons on divider hover
- [ ] Panel height persisted per project (`@AppStorage`)
- [ ] Collapsed bar: project name + cluster dot groups
- [ ] `OfficeCanvasView`: Canvas/SpriteKit pixel renderer
- [ ] Sprite pixel data port from `SpriteDesigns.tsx` blob design → Swift arrays
- [ ] Draw sprites at correct cluster positions (root back-center, subs fanned front)
- [ ] Dashed tether lines (root → subs, quadratic curve)
- [ ] Faint cluster zone rects (dashed border, tinted bg)
- [ ] Status dots (6px, color by status)
- [ ] Active cluster full opacity, inactive 45%
- [ ] Selection ring on selected sprite
- [ ] Sprite click → `AppState.selectedAgent` → tab syncs
- [ ] Tab selection → sprite highlights (bidirectional ✓)

**Deliverable**: Animated office, click sprite = select tab, click tab = highlight sprite.

---

### Phase 5 — Sprite Animations (Week 4)
*Goal: sprites express state through body language.*

- [ ] Animation loop via `CADisplayLink` or `TimelineView`
- [ ] Bob animation: `sin(t * freq + phase) * amplitude`
  - Typing: 0.45s cycle, ±1.5px
  - Idle: 1.3s cycle, ±0.6px
  - Waiting: 2.0s cycle, ±0.9px
- [ ] Sprite shape selection by animation state:
  - Typing → TYPE shape (hunched forward)
  - Waiting → SHRUG shape (arms wide)
  - Error → ERROR shape (X eyes)
  - Others → BODY shape
- [ ] "writing..." bubble (typing state)
- [ ] "waiting" bubble (amber, waiting state)
- [ ] Spawn animation: scale 0→1 over 0.4s + hop
- [ ] Error state: red body flash 12Hz + pulsing halo + ! badge
- [ ] Error at full opacity even in dimmed cluster
- [ ] Tab pip pulse animation (CSS-equivalent via `withAnimation`)

**Deliverable**: All agents animating correctly, error state unmissable.

---

### Phase 6 — JSONL Process Integration (Week 5–6)
*Goal: real Claude Code sessions drive the UI.*

- [ ] `ClaudeCodeProcess`: wraps `Foundation.Process`, pipes stdout
- [ ] One process per project tab, never killed on tab switch
- [ ] Ring buffer per process (last N lines of stdout)
- [ ] Terminal view reads from ring buffer (live)
- [ ] `JSOLWatcher`: `DispatchSource` file watcher on Claude Code transcript dir
  - Path: `~/.claude/projects/<hash>/` (verify actual path)
- [ ] Parse tool use events:
  - `write_file` / `create_file` → typing animation
  - `read_file` / `list_files` → reading animation (slow bob, BODY shape)
  - `bash` → bash bubble
  - `Task` spawn → new subagent (spawn animation)
  - Idle timer (>2s no events) → idle
  - Error string detection → error state
- [ ] Parse `usage` fields → token count + cost estimate
- [ ] Reconstruct agent hierarchy from Task spawn events
- [ ] Auto-add new subagent tabs as they spawn

**Deliverable**: Open a real Claude Code session → see it in Botcrew live.

---

### Phase 7 — Polish + MVP Ship (Week 6–7)
*Goal: stable, daily-driveable.*

- [ ] Expanded panel ops mode (sprites top, terminals bottom, internal divider)
- [ ] Multi-terminal grid: 1 terminal full width, 2 side-by-side, 3–4 as 2×2
- [ ] Session restore: reopen app → reconnect to running processes
- [ ] Error recovery UI: click errored sprite → auto-open terminal
- [ ] Empty states: no projects, no agents, new project setup flow
- [ ] App icon: pixel art botcrew logo (blob robots at desks)
- [ ] Menu bar item (optional): aggregate status across all projects
- [ ] Performance: office canvas stays at 60fps with 8+ agents

**Deliverable**: v0.1 — daily driver for your own Claude Code workflow.

---

## Data models (Swift)

```swift
struct Project: Identifiable {
    let id: UUID
    var name: String
    var path: URL
    var status: ProjectStatus  // active, idle, error
    var agents: [Agent]
    var tokenCount: Int
    var estimatedCost: Double
}

struct Agent: Identifiable {
    let id: UUID
    var name: String
    var parentId: UUID?         // nil = root orchestrator
    var status: AgentStatus     // typing, reading, waiting, idle, error
    var bodyColor: Color
    var shirtColor: Color
    var spawnTime: Date
}

enum AgentStatus {
    case typing, reading, waiting, idle, error
}

struct ActivityEvent: Identifiable {
    let id: UUID
    let agentId: UUID
    let timestamp: Date
    let type: EventType
    var file: String?
    var meta: String?
}

enum EventType {
    case spawn, write, read, bash, thinking, error
}

class AppState: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProjectId: UUID?
    @Published var selectedAgentId: UUID?
    @Published var activeClusterId: UUID?   // which root cluster is expanded in tab bar
    @Published var openTerminalIds: [UUID] = []  // up to 4
}
```

---

## File structure

```
Botcrew/
├── CLAUDE.md                     ← you are here
├── PROJECT_PLAN.md               ← this file
├── CLAUDE_CODE_REFERENCE.md      ← Figma React prototype reference
├── Botcrew.xcodeproj/
└── Botcrew/
    ├── App/
    │   ├── BotcrewApp.swift
    │   ├── AppState.swift
    │   └── ContentView.swift
    ├── Models/
    │   ├── Project.swift
    │   ├── Agent.swift
    │   └── ActivityEvent.swift
    ├── Views/
    │   ├── Sidebar/
    │   │   ├── SidebarView.swift
    │   │   └── TokenCard.swift
    │   ├── TabBar/
    │   │   ├── TabBarView.swift
    │   │   ├── RootTabView.swift
    │   │   └── SubTabView.swift
    │   ├── Feed/
    │   │   ├── ActivityFeedView.swift
    │   │   ├── FeedHeaderView.swift
    │   │   ├── EventRowView.swift
    │   │   └── TerminalView.swift
    │   └── Office/
    │       ├── OfficePanelView.swift
    │       ├── OfficeCanvasView.swift
    │       ├── DragDividerView.swift
    │       └── SpriteRenderer.swift
    ├── Services/
    │   ├── ClaudeCodeProcess.swift   ← process lifecycle + ring buffer
    │   ├── JSONLWatcher.swift         ← transcript file watching
    │   └── AgentStateParser.swift    ← event parsing → agent state
    └── Assets/
        └── SpriteData.swift          ← pixel arrays ported from SpriteDesigns.tsx
```

---

## Reference: Figma prototype v2 components

The React/TypeScript prototype in `CLAUDE_CODE_REFERENCE.md` (v2) uses macOS Big Sur+ design. Key things to port:

**macOS materials** (`MacFrame.tsx`, `theme.css`):
- Window: `backdrop-filter: blur(40px)` → SwiftUI `.ultraThinMaterial`
- Sidebar: `backdrop-filter: blur(20px)` → SwiftUI `.sidebar` list style
- Panels: `backdrop-filter: blur(20px)` → SwiftUI `.regularMaterial`
- Use SwiftUI materials wherever possible — they auto-adapt to light/dark and match system vibrancy

**Interactive traffic lights** (`MacFrame.tsx`):
```swift
// Replicate the hover behavior:
// Default: 40% opacity on all three dots
// Window hover: 100% opacity
// Button hover: show icon (×, —, ↕), full opacity that button, others 40%
@State var hoveredButton: TrafficLight? = nil
```

**Sprite rendering** (`OfficePanel.tsx` lines 700–822):
- `drawSprite(cx, cy, anim, color, color, bobY, S)` → port to `SpriteRenderer.swift`
- `bob(anim, phase)` → `sin(t * freq + phase) * amp`
- Desk drawing, status dot, selection ring, hover ring, typing/waiting bubbles

**Sprite pixel data** (`SpriteDesigns.tsx`):
- Blob design: BODY, TYPE, SHRUG, ERROR shapes
- 8×10 grid, value map: 0=transparent, 1=body, 2=eyes, 3=accent, 6=X-eyes

**Status colors** (`OfficePanel.tsx` line 733):
- typing: `#34d399`
- reading: `#60a5fa`
- waiting: `#fbbf24`
- error: `#FF5F57` (add — not in prototype yet)

**Selection style** (`theme.css`):
- Active row: `rgba(10, 132, 255, 0.15)` bg + `rgba(10, 132, 255, 0.3)` border
- System blue: `#0A84FF` dark / `#007AFF` light

**Typography** (`MacFrame.tsx` inline styles):
- Font: `-apple-system, BlinkMacSystemFont, "SF Pro Display"` → `.system()` in SwiftUI
- Title: 13px medium → `Font.system(size: 13, weight: .medium)`
- Section labels: 11px semibold uppercase → `Font.system(size: 11, weight: .semibold).uppercaseSmallCaps()`

**Component props interfaces** (`types.ts`):
- `Agent.status`: `'typing' | 'reading' | 'waiting'` → add `'idle' | 'error'`
- `ActivityItem.action`: `'read' | 'write'` → expand to full event type enum

---

## Human vs AI task split

| Task | Owner | Notes |
|---|---|---|
| Create GitHub repo + push files | Human | Done before handing off |
| Xcode project creation | Claude Code | Write `project.pbxproj` directly |
| Code signing identity | Human | Add your Apple ID in Xcode → Signing & Capabilities if needed |
| Swift model definitions | Claude Code | Port from TypeScript types |
| SwiftUI view scaffolding | Claude Code | Layout, mock data wiring |
| Sprite pixel data port | Claude Code | Direct array translation from `SpriteDesigns.tsx` |
| Canvas sprite renderer | Claude Code | Port from `OfficePanel.tsx` |
| JSONL transcript path | Human | Run `find ~/.claude -name "*.jsonl" \| head -5`, record in `PROGRESS.md` |
| Process lifecycle | Claude Code | Foundation.Process + pipes |
| JSONL watcher + parser | Claude Code | DispatchSource + heuristic parsing |
| App icon pixel art | Claude Code | Blob robots at desks — generate as PNG asset |
| TestFlight / distribution | Human | Apple Developer account required |
| Design decisions / UX calls | Human | Reference `DECISIONS.md` |

---

## Open questions before Phase 6

1. **JSONL path**: What is the actual transcript file path on your machine? Run `find ~/.claude -name "*.jsonl" | head -5` to find it.
2. **Process attach vs spawn**: Does Botcrew spawn new `claude` processes, or attach to existing ones running in terminal? Spawn is cleaner for v1.
3. **Sprite design**: Figma went with blob sprites. Stick with blob or go back to humanoid pixel sprites from our design session? Both pixel data sets exist.
4. **Agent colors**: Fixed palette (role-based) or assigned dynamically per session?
