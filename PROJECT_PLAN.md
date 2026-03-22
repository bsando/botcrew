# Botcrew — Project Plan

Native macOS app for visualizing and managing Claude Code multi-agent sessions. Pixel art office, activity feeds, bidirectional tab/sprite sync.

**Status**: Post-MVP polish — all 7 phases + 5 features + light mode + session restore + sound notifications
**Stack**: SwiftUI, SpriteKit/Canvas, Foundation Process  
**Reference**: Figma prototype (React/TypeScript) in `CLAUDE_CODE_REFERENCE.md`

---

## Phases

### Phase 0 — Scaffold (Week 1)
*Goal: app opens, window exists, no crashes. Claude Code handles all of this including Xcode project creation.*

- [x] Create Xcode project — via xcodegen (project.yml), Bundle ID: `com.redwoodfog.botcrew`, macOS 14+, Swift 5.10
- [x] Run `./scripts/create_stubs.sh` to generate all Swift file stubs
- [x] `BotcrewApp.swift`: `@main`, `WindowGroup`, `.frame(minWidth: 900, minHeight: 640)`
- [x] `AppState.swift`: `@Observable` class — `selectedProjectId`, `selectedAgentId`, `activeClusterId`, `openTerminalIds`
- [x] `ContentView.swift`: `HSplitView` → sidebar (168px fixed) + main column
- [x] Mock data structs matching types in `CLAUDE_CODE_REFERENCE.md`
- [x] `.preferredColorScheme(.dark)` on window
- [x] Window background: `.background(.ultraThinMaterial)` with dark overlay `rgba(25,25,30,0.4)`
- [x] `MacFrame` titlebar with interactive traffic lights
- [x] Verify: `xcodebuild` passes 0 errors
- [x] Unit test target (BotcrewTests) with AppState, Model, and SpriteData tests

**Deliverable**: `xcodebuild` passes. App launches. Sidebar + placeholder with macOS chrome visible.

---

### Phase 1 — Sidebar + Projects (Week 1–2)
*Goal: project switching works end-to-end with mock data.*

- [x] `Project` model (id, name, path, status, agents, events, tokenCount, cost)
- [x] `SidebarView`: project list, active highlight, status dot, agent sub-dots
- [x] Add/remove project (AddProjectSheet with NSOpenPanel directory picker)
- [x] Project switching → clears tab strip, resets office (selectProject clears agent/cluster/terminals)
- [x] Token/cost card at sidebar bottom (formatted from selected project)
- [x] Collapsed sidebar state (CollapsedSidebarView, icon-only, 44px)

**Deliverable**: Click projects → UI updates throughout.

---

### Phase 2 — Tab Bar + Agent Hierarchy (Week 2)
*Goal: tab clusters expand/collapse, selection syncs everywhere.*

- [x] `Agent` model (id, name, parentId, status, bodyColor, shirtColor, spawnTime)
- [x] `TabBarView`: scrollable root tabs + sub-tab strips per cluster
- [x] Cluster expand/collapse (toggleCluster — only active cluster shows subtabs)
- [x] Collapsed cluster: root tab + inline sub-status dots
- [x] Tab selection state in `AppState` (selectAgent, rootAgents, subAgents)
- [x] Sprite thumbnail canvases in tabs (SpriteThumbnail: 12×16 root, 10×14 sub)
- [x] Tab ↔ sprite bidirectional selection hook (prep for Phase 4)

**Deliverable**: Full tab bar interaction with mock agents.

---

### Phase 3 — Activity Feed (Week 2–3)
*Goal: feed shows structured events, terminal view toggles in.*

- [x] `ActivityEvent` model (timestamp, type, agentId, file, meta)
- [x] `ActivityFeedView`: event list with icon, text, sub-text (lazy scrolling)
- [x] Event type icons: spawn (⬡), write (↑), read (↓), bash ($), thinking (·), error (!)
- [x] Feed header: colored swatch, agent name, role badge, status pill
- [x] Thinking state: animated dots (ThinkingDots component)
- [x] Activity/Terminal toggle in feed header
- [x] Terminal view: raw text output (mock static content)
- [x] Feed scoped to selected agent (eventsForSelectedAgent filtered + sorted)

**Deliverable**: Click tab → see that agent's activity feed.

---

### Phase 4 — Pixel Office Panel (Week 3–4)
*Goal: sprites render, animate, and sync with tabs.*

- [x] `OfficePanelView` wrapper with draggable height divider
- [x] Three snap states: collapsed (26px), ambient (148px), expanded (270px)
- [x] Snap buttons on divider hover (expand/ambient/collapse)
- [ ] Panel height persisted per project (`@AppStorage`) — deferred, using in-memory state
- [x] Collapsed bar: project name + cluster dot groups + restore button
- [x] `OfficeCanvasView`: Canvas pixel renderer with GeometryReader layout
- [x] Sprite pixel data port — all 4 shapes (body, type, shrug, error) with shape(for:) mapping
- [x] Draw sprites at correct cluster positions (root back-center at 35%, subs fanned at 70%)
- [x] Dashed tether lines (root → subs, quadratic curve upward)
- [x] Faint cluster zone rects (dashed border, tinted bg per agent color)
- [x] Status dots (6px, color by status, top-right of sprite)
- [x] Active cluster full opacity, inactive 45% (error sprites always full opacity)
- [x] Selection ring on selected sprite (blue #0A84FF, 1.5px stroke)
- [x] Sprite click → `AppState.selectAgent` → tab syncs (invisible tap targets)
- [x] Tab selection → sprite highlights (bidirectional via shared selectedAgentId)

**Deliverable**: Animated office, click sprite = select tab, click tab = highlight sprite.

---

### Phase 5 — Sprite Animations (Week 4)
*Goal: sprites express state through body language.*

- [x] Animation loop via `TimelineView(.animation)` driving continuous Canvas redraws
- [x] Bob animation: `sin(t * freq + phase) * amplitude`, per-agent phase from UUID hash
  - Typing: 0.45s cycle, ±1.5px
  - Idle: 1.3s cycle, ±0.6px
  - Waiting: 2.0s cycle, ±0.9px
- [x] Sprite shape selection by animation state (done in Phase 4 via `SpriteData.shape(for:)`)
- [x] "writing..." bubble (green, typing state)
- [x] "waiting" bubble (amber, waiting state)
- [ ] Spawn animation: scale 0→1 over 0.4s + hop — deferred to Phase 7
- [x] Error state: red body flash 12Hz + pulsing halo (1.5s radial gradient) + ! badge
- [x] Error at full opacity even in dimmed cluster (done in Phase 4)
- [x] Tab pip pulse animation (PulsingPip component, error border on tabs)

**Deliverable**: All agents animating correctly, error state unmissable.

---

### Phase 6 — JSONL Process Integration (Week 5–6)
*Goal: real Claude Code sessions drive the UI.*

- [x] `ClaudeCodeProcess`: wraps `Foundation.Process`, pipes stdout/stderr, zsh login shell for PATH
- [x] One process per project tab, never killed on tab switch
- [x] Ring buffer per process (last 2000 lines of stdout)
- [x] Terminal view reads from ring buffer (live, auto-scrolls)
- [x] `JSONLWatcher`: `DispatchSource` file watcher on Claude Code transcript dir
  - Path: `~/.claude/projects/<path-hash>/<session-uuid>.jsonl`
- [x] Parse tool use events:
  - `Write` / `Edit` → typing animation
  - `Read` / `Grep` / `Glob` → reading animation
  - `Bash` → typing (active work)
  - `Agent` / `Task` spawn → waiting + new subagent
  - Idle timer (>2s no events) → idle
  - Error detection → error state
- [x] Parse `usage` fields → token count + cost estimate
- [x] Reconstruct agent hierarchy from subagent JSONL files
- [x] Auto-add new subagent tabs as they spawn (with color palette cycling)

**Deliverable**: Open a real Claude Code session → see it in Botcrew live.

---

### Phase 7 — Polish + MVP Ship (Week 6–7)
*Goal: stable, daily-driveable.*

- [x] Expanded panel ops mode (sprites top, terminals bottom, internal divider)
- [x] Multi-terminal grid: 1 terminal full width, 2 side-by-side, 3–4 as 2×2
- [x] Session restore: reopen app → auto-detect recent JSONL sessions and reconstruct state
- [x] Error recovery UI: click errored sprite → auto-open terminal
- [x] Empty states: no projects, no agents, new project setup flow
- [ ] App icon: pixel art botcrew logo (blob robots at desks) — deferred to v2
- [ ] Menu bar item (optional): aggregate status across all projects — deferred to v2
- [x] Performance: office canvas stays at 60fps with 8+ agents (tested)

**Deliverable**: v0.1 — daily driver for your own Claude Code workflow.

---

### Post-MVP Feature Sprint

Five features added after Phase 7 to make Botcrew a one-stop Claude Code management tool:

- [x] **Structured Feed** — ToolCardView with collapsible cards, diff blocks, code blocks, SF Symbol icons
- [x] **Session History** — Browse and resume past JSONL sessions via SessionScanner
- [x] **Cost Dashboard** — Daily chart (SwiftUI Charts), per-project breakdown, token tracking
- [x] **Git Integration** — Status, diff viewer, commit form via GitService (⌘G)
- [x] **Prompt Templates** — 6 built-in + custom templates with categories and search

Additional post-MVP additions:
- [x] Prompt input bar with permission mode picker (auto/supervised/safe)
- [x] Tool approval banner for permission denials
- [x] Stream-JSON protocol support in ClaudeCodeProcess
- [x] Inline renaming for agents, subagents, and projects
- [x] State persistence (projects, settings, cost history)
- [x] Keyboard shortcuts (⌘↑↓ projects, ⌘←→ agents, ⌘\ sidebar, ⌘T terminal, ⌘G git)
- [x] Improved contrast across all UI elements
- [x] Session restore on relaunch (auto-detect recent JSONL sessions)
- [x] Sound notifications (session complete, error, subagent spawn)
- [x] Light mode (centralized Theme system, ~300 color replacements across 20 files)
- [x] Performance optimization (throttled terminal buffer flush, non-observed storage)

---

## File structure

```
Botcrew/
├── App/
│   ├── BotcrewApp.swift            # Entry point, window, commands
│   ├── AppState.swift              # Central state + persistence + process mgmt
│   ├── ContentView.swift           # Main layout + BotcrewCommands
│   └── Theme.swift                 # Adaptive color tokens (light/dark mode)
├── Models/
│   ├── Project.swift               # Project + SavedProject (Codable)
│   ├── Agent.swift                 # Agent model + status enum
│   ├── ActivityEvent.swift         # Feed events with structured tool data
│   ├── CostRecord.swift            # Per-session cost tracking
│   ├── GitStatus.swift             # Git file changes + info
│   ├── PromptTemplate.swift        # Built-in + custom templates
│   ├── SessionInfo.swift           # Past session metadata
│   └── ToolApproval.swift          # Permission denial handling
├── Views/
│   ├── Sidebar/
│   │   ├── SidebarView.swift       # Project list with inline renaming
│   │   ├── TokenCard.swift         # Token/cost display (clickable → dashboard)
│   │   ├── CostDashboardView.swift # Cost chart + breakdown sheet
│   │   └── SessionHistoryView.swift # Past sessions list with resume
│   ├── TabBar/
│   │   ├── TabBarView.swift        # Root/sub tabs with renaming
│   │   ├── RootTabView.swift       # Root tab with sprite thumbnail
│   │   └── SubTabView.swift        # Sub tab with sprite thumbnail
│   ├── Feed/
│   │   ├── ActivityFeedView.swift  # Scoped event list
│   │   ├── FeedHeaderView.swift    # Agent info + toggle
│   │   ├── ToolCardView.swift      # Collapsible tool cards with diffs
│   │   ├── EventRowView.swift      # Legacy event row (replaced by ToolCardView)
│   │   ├── TerminalView.swift      # Raw process output
│   │   ├── PromptInputBar.swift    # Prompt field + permission mode + templates
│   │   ├── PromptTemplateSheet.swift # Template browser + custom creation
│   │   └── ToolApprovalBanner.swift  # Permission denial approve/deny
│   ├── Office/
│   │   ├── OfficePanelView.swift   # Panel wrapper + collapsed bar
│   │   ├── OfficeCanvasView.swift  # Canvas pixel renderer
│   │   ├── DragDividerView.swift   # Snap divider between feed/office
│   │   └── SpriteRenderer.swift    # Sprite drawing helpers
│   └── Git/
│       └── GitPanelView.swift      # Git status, diff, commit sheet
├── Services/
│   ├── ClaudeCodeProcess.swift     # Process lifecycle + stream-JSON protocol
│   ├── JSONLWatcher.swift          # DispatchSource transcript watching
│   ├── AgentStateParser.swift      # Event parsing → agent state
│   ├── SessionScanner.swift        # Past JSONL session scanning
│   ├── GitService.swift            # Git CLI operations via Process
│   └── SoundService.swift          # System sound notifications
└── Assets/
    └── SpriteData.swift            # Pixel arrays (blob sprites)
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

## Resolved questions

1. **JSONL path**: `~/.claude/projects/<path-hash>/<session-uuid>.jsonl` — path hash is project path with `/` → `-`
2. **Process attach vs spawn**: Spawn — Botcrew launches Claude Code sessions via Foundation.Process
3. **Sprite design**: Blob (Figma v2) — implemented
4. **Agent colors**: Fixed role-based palette with dynamic cycling for subagents within a session
