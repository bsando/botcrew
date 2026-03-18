# Botcrew — CLAUDE.md

A native macOS app (SwiftUI) for managing Claude Code multi-agent sessions. Pixel art office with animated sprites representing each agent. Feed-primary, ambient office panel below.

---

## What this app does

Botcrew solves three problems:
1. **No visibility** into what subagents are doing or their hierarchy
2. **Context loss** when switching between repos/sessions
3. **No cost tracking** across sessions

It reads Claude Code's JSONL transcript files (no modification to Claude Code needed) and presents a unified view: project sidebar, agent tabs, activity feed, and a pixel art office at the bottom where each sprite = one agent.

---

## Environment

```
macOS: 14.x (Sonoma) or later
Xcode: 16.x
Swift: 5.10
Deployment target: macOS 14.0
Window size: 900×640 (default), matches Figma prototype max-w-[900px]
```

---

## Commands

```bash
# Build (headless — use to verify no compile errors after writing Swift)
xcodebuild -scheme Botcrew -destination 'platform=macOS' -configuration Debug build

# Open project
open Botcrew.xcodeproj

# Find Claude Code JSONL transcripts (run once, record path in PROGRESS.md)
find ~/.claude -name "*.jsonl" | head -10

# Check Claude Code is installed
which claude

# Watch transcript directory for file changes (manual test)
ls -la ~/.claude/projects/
```

Always run `xcodebuild` after writing Swift to catch compile errors immediately. Don't accumulate multiple files of unverified code.

```bash
# Run tests
xcodebuild -scheme BotcrewTests -destination 'platform=macOS' test

# Regenerate Xcode project after changing project.yml
xcodegen generate
```

---

## Testing

Unit test target: `BotcrewTests` (in `BotcrewTests/` directory). Uses `@testable import Botcrew`.

**What to test (by phase):**

| Phase | Test scope | Why |
|---|---|---|
| 1 — Sidebar | Project add/remove, switching, status transitions | State management correctness |
| 2 — Tabs | Cluster expand/collapse, tab selection, bidirectional sync | Complex selection state |
| 3 — Feed | Event filtering by agent, ordering | Data flow correctness |
| 4 — Office | Sprite position math, cluster layout | Pixel-precise rendering |
| 6 — JSONL | Parser input/output, event detection, hierarchy reconstruction | Highest value — heuristic logic breaks silently |

**What NOT to test:**
- SwiftUI views — verify visually by running the app
- SpriteKit/Canvas rendering — same, visual verification
- Process lifecycle — integration-level, hard to mock

**Rules:**
- Run tests after each phase is complete
- Add tests alongside new model/state/parser code, not after
- Test files go in `BotcrewTests/` with the naming convention `<Thing>Tests.swift`
- Use factory helpers (e.g. `makeAgent()`, `makeProject()`) to avoid boilerplate in tests

---



### Tech stack
- **Platform**: macOS, SwiftUI
- **Office canvas**: SpriteKit or Canvas API for pixel rendering
- **Process management**: Foundation `Process` + pipes (one persistent process per tab)
- **JSONL watching**: `DispatchSource` file system events (no polling)
- **Git integration**: shell-out to git CLI (`git status --porcelain`, `git log`)
- **Token tracking**: parse `usage` fields from Claude Code JSONL

### Figma prototype reference
Figma generated a React/TypeScript prototype (v2: macOS Big Sur+ design) as a reference implementation. Key components map to SwiftUI as follows:

| React component (Figma) | SwiftUI equivalent |
|---|---|
| `MacFrame.tsx` | `WindowGroup` + custom chrome with `.ultraThinMaterial` |
| `Sidebar.tsx` | `List` with `.sidebar` list style + vibrancy |
| `TabBar.tsx` | Custom `HStack` tab strip |
| `OfficePanel.tsx` | `Canvas` / `SpriteKit` scene |
| `ActivityFeed.tsx` | `ScrollView` + `LazyVStack` + `.regularMaterial` bg |
| `AgentDetailsModal.tsx` | `.sheet` with detents |
| `SpriteDesigns.tsx` | Pixel data as Swift arrays |
| `theme.css` | SwiftUI `ShapeStyle` + `Color` extensions |

### macOS Big Sur+ design language (v2)
The v2 Figma prototype uses authentic macOS aesthetics throughout. Match these in SwiftUI:

**Translucency / materials**
- Window: `.ultraThinMaterial` or `rgba(40,40,40,0.85)` dark / `rgba(246,246,246,0.8)` light
- Sidebar: `.sidebar` list style (automatic vibrancy) or `rgba(30,30,30,0.7)` dark
- Titlebar: `rgba(40,40,40,0.95)` dark — gradient top-to-bottom subtle
- Content panels: `rgba(30,30,30,0.6)` dark / `rgba(255,255,255,0.6)` light
- Activity feed: `backdrop-filter: blur(20px)` → `.regularMaterial`

**SF Pro font stack**
```swift
// Use system font — SF Pro loads automatically on macOS
Font.system(size: 13, weight: .medium, design: .default)
// Never hardcode "SF Pro" — use .system()
```

**Interactive traffic lights** (from `MacFrame.tsx`)
- Default: 40% opacity
- Window hover → 100% opacity (all three)
- Individual hover → show icons:
  - Close (red): × symbol
  - Minimize (yellow): — line
  - Maximize (green): ↕ arrows
- Transition: 150ms ease

**Selection colors**
- Active: `rgba(10, 132, 255, 0.15)` background + `rgba(10, 132, 255, 0.3)` border
- System blue: `#0A84FF` (dark mode) / `#007AFF` (light mode)

**Typography scale**
- Section headers: 11px, semibold, uppercase, letter-spacing 0.06em
- Body: 13px, regular/medium
- Padding: generous — 16–24px (not 8–12px)

### Sprite pixel data
Figma prototype uses "blob" design. 8×10 grid, value map:
- `0` = transparent
- `1` = body color (per-agent)
- `2` = eyes (dark `#1a1c2c`)
- `3` = accent (mouth/arms)
- `6` = X eyes (error state)

```
BODY shape (idle/reading):
[0,0,0,1,1,1,0,0]
[0,0,1,1,1,1,1,0]
[0,1,1,2,1,2,1,1]
[0,1,1,1,1,1,1,1]
[1,1,1,1,1,1,1,1]
[1,1,3,1,1,3,1,1]
[1,1,1,1,1,1,1,1]
[0,1,1,1,1,1,1,0]
[0,0,1,1,1,1,0,0]
[0,0,0,1,1,0,0,0]

TYPE shape (writing):     SHRUG shape (waiting):    ERROR shape:
head shifts forward       arms extend wide          X eyes, open mouth
```

---

## Layout structure

```
┌─────────────────────────────────────────────────┐
│  Titlebar (36px)                                │
├──────────┬──────────────────────────────────────┤
│          │  Tab bar (38px)                      │
│          │  [root ▾ sub sub sub] [root dots]    │
│ Sidebar  ├──────────────────────────────────────┤
│ (168px)  │  Feed header (36px)                  │
│          │  Activity feed (flex 1)              │
│ Projects │                                      │
│ + tokens ├──────────────────────────────────────┤
│          │  Drag divider (6px)                  │
│          ├──────────────────────────────────────┤
│          │  Office panel (snap: 0/148/270px)    │
│          │  [bar 26px] [canvas flex 1]          │
└──────────┴──────────────────────────────────────┘
```

---

## Information hierarchy

- **Sidebar** = projects (slow-moving). Active project → replaces entire tab strip + office.
- **Tabs** = agents within active project (fast-moving). Root tabs + sub-tabs per cluster.
- **Feed** = activity for selected agent.
- **Office** = ambient pixel office. Every sprite = one tab. Fully bidirectional sync.

---

## Tab bar behavior

- **Root tab**: larger, shows sprite thumbnail + status pip + name. Always visible.
- **Sub tabs**: smaller, tucked under root. Only visible when that cluster is expanded (active).
- **Collapsed cluster**: root tab only, with sub-status dots inline (e.g. `● ● ◐`).
- Clicking a root tab → expands that cluster, collapses others.
- Clicking a sub tab → selects that agent, parent root stays highlighted.
- Clicking a sprite in office → selects matching tab (bidirectional).

---

## Office panel

### Three snap states
| State | Height | Behavior |
|---|---|---|
| Collapsed | 26px | Bar only. Dots + project name. Click to restore. |
| Ambient (default) | 148px | Sprites visible, labels, bubbles. Primary mode. |
| Expanded | 270px | Ops mode: sprites top half, terminals bottom half. |

- Draggable divider between feed and office. Snaps on release.
- Snap buttons on divider hover (▾▾ ─ ▴▴).
- Height remembered per project.

### Cluster layout
- Each root agent has a desk cluster (faint dashed zone with tint).
- Root sprite at back-center, subagents fanned in front row.
- Dashed tether lines connect subs → root (curving upward).
- Active cluster: full opacity. Inactive: 45% opacity, no labels.

### Expanded (ops mode)
- Top half: sprites (larger scale).
- Bottom half: terminal output, same multi-terminal grid as main feed.
- Internal draggable divider between sprite zone and terminal zone.

---

## Sprite animations

| State | Animation | Trigger |
|---|---|---|
| Typing/writing | Hunched forward (TYPE shape), fast bob 0.45s. "writing..." bubble. | File writes in JSONL |
| Reading/thinking | Upright (BODY shape), slow sway side-to-side. | File reads / generation |
| Waiting/blocked | Arms-wide (SHRUG shape), slow loop. Amber "waiting" bubble. | Blocked on subagent |
| Idle/done | Upright (BODY shape), very slow gentle bob. | Session complete |
| Error | X eyes (ERROR shape), red body flash 12Hz, red halo pulse. | Error in transcript |
| Spawn | Scale 0→1 over 0.4s, ends with small hop. | New agent spawned |

### Status dot
6px circle top-right of sprite:
- `#28C840` — running
- `#FEBC2E` — waiting/blocked
- `#888780` — idle/done
- `#FF5F57` — error (pulses)

---

## Error state (four signals, all passive)

Error sprites render at **full opacity regardless of cluster dimming state**.

1. **Sprite**: ERROR shape + red body flash + red halo pulse (radial gradient, 1.5s cycle)
2. **! badge**: solid red pill above sprite, always full opacity, shows count if multiple
3. **Tab pip**: sub tab pip + parent root tab pip both turn red and pulse
4. **Collapsed bar dot**: agent's dot turns red and pulses even when panel hidden

**Never auto-expand** the cluster on error — purely passive signal.

---

## Agent identity colors

| Role | Body | Shirt | Usage |
|---|---|---|---|
| Root orchestrator | `#c0a8ff` | `#5030a0` | Purple ramp |
| Writer agents | `#80e8a0` | `#0a4020` | Teal/green ramp |
| Test/wait agents | `#ffd080` | `#6a3800` | Amber ramp |
| Doc/utility agents | `#80c8ff` | `#0a3060` | Blue ramp |
| UI builder root | `#ffb090` | `#802010` | Coral ramp |

---

## App chrome colors (v2 — macOS Big Sur)

Dark mode (primary target):

| Token | Hex / value | Usage |
|---|---|---|
| Window bg | `rgba(40,40,40,0.85)` | Main window, backdrop blur 40px |
| Titlebar | `rgba(40,40,40,0.95)` | Gradient top→bottom subtle |
| Sidebar | `rgba(30,30,30,0.7)` | Vibrancy panel, blur 20px |
| Content bg | `rgba(30,30,30,0.6)` | Feed, modal panels |
| Selection active | `rgba(10,132,255,0.15)` | Selected row bg |
| Selection border | `rgba(10,132,255,0.3)` | Selected row border |
| Separator | `rgba(255,255,255,0.08)` | Dividers, borders |
| Office bar | `#0F1020` | Collapsed bar, office bar bg |
| Office floor | `#191A2E` | Canvas background |
| Active tab | `rgba(50,50,65,0.8)` | Selected tab bg |
| Text primary | `rgba(255,255,255,0.85)` | Main text |
| Text secondary | `rgba(255,255,255,0.55)` | Muted text |
| Text tertiary | `rgba(255,255,255,0.25)` | Hints, labels |

SwiftUI material equivalents:
```swift
.background(.ultraThinMaterial)   // window, sidebar
.background(.regularMaterial)     // panels, sheets
.background(.thickMaterial)       // titlebar
```

---

## JSONL parsing (agent state detection)

Claude Code writes JSONL transcripts. No modification needed — purely observational.

```swift
// Watch for file changes
let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fd,
    eventMask: .write,
    queue: .main
)

// Parse tool use events → sprite animation
// "write_file" → typing animation
// "read_file"  → reading animation
// Task tool spawn → new subagent sprite (spawn animation)
// Idle timer    → idle animation
// Error events  → error state
```

Agent hierarchy: reconstruct from `Task` tool spawn events in transcript.
Token counts: parse `usage.input_tokens` + `usage.output_tokens` fields.

---

## MVP scope (v0.1)

In scope:
- [ ] Project sidebar (add/remove, status dots, collapse)
- [ ] Agent tabs (root + sub clusters, expand/collapse, sprite thumbnails)
- [ ] Activity feed (structured events from JSONL)
- [ ] Terminal view (raw output, toggle with feed)
- [ ] Pixel office panel (sprites, tethers, clusters, desks)
- [ ] Sprite animations (typing, waiting, idle, spawn, error)
- [ ] Error state (all four signals)
- [ ] Draggable panel (three snap states, remembered per project)
- [ ] Token/cost tracking (per-session from JSONL)
- [ ] Multi-terminal grid (1–4, 2×2 layout)

Deferred to v2:
- Git panel (file changes, branch, diff)
- Split view (two projects side by side)
- Sound notifications
- Office layout editor
- Custom sprite skins

---

## Key decisions log

See `DECISIONS.md` for the full decision log with rationale. Quick summary:

- **Blob sprites** over humanoid — rounder, more expressive at small sizes
- **macOS Big Sur materials** — `.ultraThinMaterial` / `.regularMaterial`, not flat hex
- **Feed primary, office ambient** — office panel below feed, not replacing it
- **Passive errors** — never auto-expand cluster. Four signals, all passive
- **One process per tab** — never killed on tab switch. Ring buffer per tab
- **JSONL watching** — heuristic state detection, same approach as Pixel Agents VS Code ext
- **Traffic lights** — interactive hover states matching macOS Big Sur exactly
