# Botcrew — Progress

**Read this at the start of every Claude Code session.** It tells you where the project is and what to do next.

---

## Current state

**Phase**: 7 — Complete (v0.1 MVP)
**Status**: All 7 phases done. Expanded ops mode with multi-terminal grid, error recovery UI, empty states for no-project and no-agent flows. 103 tests passing.
**Next action**: Manual testing, then real-world usage as daily driver.

---

## What's been done

- [x] Full design session — layout, sprites, animations, error states, tab behavior
- [x] Figma prototype v1 + v2 (React/TypeScript, macOS Big Sur design) — see `CLAUDE_CODE_REFERENCE.md`
- [x] `CLAUDE.md` — architecture, component map, sprite data, color tokens, commands, environment
- [x] `PROJECT_PLAN.md` — 7-phase build plan with task checklists
- [x] `DECISIONS.md` — full decision log with rationale
- [x] `PROGRESS.md` — this file
- [x] `scripts/create_stubs.sh` — creates all 23 Swift file stubs

## Build phases

- [x] Phase 0 — Scaffold (Xcode project, window, layout skeleton)
- [x] Phase 1 — Sidebar + Projects
- [x] Phase 2 — Tab Bar + Agent Hierarchy
- [x] Phase 3 — Activity Feed
- [x] Phase 4 — Pixel Office Panel
- [x] Phase 5 — Sprite Animations
- [x] Phase 6 — JSONL Process Integration
- [x] Phase 7 — Polish + MVP Ship

---

## Session log

### Session 1 — 2026-03-17

```
Started: Phase 0
Completed: Phases 0–3

Phase 0 — Scaffold:
  - Ran create_stubs.sh (23 Swift file stubs)
  - Created project.yml for xcodegen, generated Botcrew.xcodeproj
  - BotcrewApp.swift, AppState.swift, ContentView.swift (HSplitView layout)
  - MacFrameView.swift (interactive traffic lights)
  - Placeholder views for sidebar, tabs, feed, office, divider
  - All 3 model files (Project, Agent, ActivityEvent with enums)
  - BotcrewTests target with 19 initial tests

Phase 1 — Sidebar + Projects:
  - AppState: selectProject, removeProject, addProject, Color(hex:)
  - SidebarView: project list with active highlight, agent status dots, context menu
  - AddProjectSheet with NSOpenPanel directory picker
  - CollapsedSidebarView (44px icon-only mode)
  - TokenCard wired to selected project (formatted tokens + cost)
  - Mock data factory: 3 projects (active/idle/error)
  - 9 new tests (28 total)

Phase 2 — Tab Bar + Agent Hierarchy:
  - AppState: selectAgent, toggleCluster, rootAgents, subAgents
  - TabBarView: scrollable, expandable root/sub-tab clusters
  - RootTabView: sprite thumbnail (12x16), status pip, collapsed sub-dots
  - SubTabView: smaller thumbnail (10x14), selection highlight
  - SpriteThumbnail: Canvas renderer using SpriteData blob grid
  - Added second root cluster to mock data (5 agents total)
  - 12 new tests (40 total)

Phase 3 — Activity Feed:
  - Project model: added events field
  - AppState: eventsForSelectedAgent (filtered + sorted), showTerminal
  - FeedHeaderView: agent swatch, status pill, thinking dots, Activity/Terminal toggle
  - EventRowView: type icons (⬡ ↑ ↓ $ · !), colored labels, timestamps
  - ActivityFeedView: scoped to selected agent, lazy scrolling
  - TerminalView: mock terminal output
  - 13 mock events across all agents
  - 6 new tests (46 total)

Phase 4 — Pixel Office Panel:
  - SpriteData: all 4 blob shapes (body, type, shrug, error) + shape(for:) mapping
  - AppState: officePanelHeight, OfficePanelSnap enum, snapOfficePanel(to:)
  - DragDividerView: drag gesture with snap-on-release, snap buttons on hover
  - OfficePanelView: bar with cluster dot groups, restore button when collapsed
  - OfficeCanvasView: full Canvas renderer with GeometryReader
    - Cluster layout: roots at 35% height, subs fanned at 70%
    - Cluster zones: dashed border + tinted bg per agent color
    - Tether lines: quadratic curves from subs to root
    - Sprites: pixel-rendered from SpriteData grids at 3.5x scale
    - Status dots (6px), selection ring (blue), name labels
    - Active cluster full opacity, inactive 45%, error always full
    - Bidirectional: click sprite → selectAgent → tab syncs
  - 12 new tests (58 total)

Phase 5 — Sprite Animations:
  - TimelineView(.animation) driving continuous Canvas redraws
  - BobParams per status: typing 0.45s/±1.5px, idle 1.3s/±0.6px, waiting 2.0s/±0.9px
  - Per-agent phase offset from UUID hash (sprites bob independently)
  - Error: 12Hz red body flash + pulsing halo (1.5s radial gradient) + ! badge
  - "writing..." bubble (green) and "waiting" bubble (amber)
  - Tether lines follow animated sprite positions
  - PulsingPip component: tab status pips pulse on error
  - Error border on root/sub tabs when any agent in cluster has error
  - 8 new AnimationTests (66 total)

Blockers: None
Next: Phase 6 — JSONL Process Integration
```

### Session 2 — 2026-03-17

```
Started: Phase 6
Completed: Phase 6

Phase 6 — JSONL Process Integration:
  - Decision: Spawn (Botcrew launches Claude Code) over Attach (watch existing)
  - Discovered JSONL path: ~/.claude/projects/<path-hash>/<session-uuid>.jsonl
  - Subagents at: <session-uuid>/subagents/agent-<hash>.jsonl
  - ClaudeCodeProcess: Foundation.Process wrapper, zsh -l -c for PATH,
    stdout/stderr pipes with readabilityHandler, 2000-line ring buffer,
    termination handler, start/stop lifecycle
  - AgentStateParser: JSONL line parser, tool use → AgentStatus mapping
    (Write/Edit → typing, Read/Grep → reading, Agent/Task → waiting),
    tool use → EventType mapping, token extraction (input + cache tokens),
    cost estimation ($15/M input, $75/M output), subagent spawn detection,
    file path extraction, error detection
  - JSONLWatcher: DispatchSource file watching (write + extend events),
    tail-style reading (tracks file offset, reads only new bytes),
    subagent directory watcher (scans for new .jsonl files),
    project hash helper (path → -path-hash), latest session finder,
    bulk event reader for initial load
  - AppState additions: processes dict, watchers dict, idle timers,
    agentSessionMap (JSONL path → agentId), startSession() creates root
    agent + launches process + sets up watcher after 1s delay,
    stopSession() terminates process + marks agents idle (preserves error),
    handleJSONLEvent() updates agent status + adds activity events +
    resets 2s idle timer + tracks tokens, handleNewSubagent() creates
    sub-agent with color from palette + auto-expands cluster,
    terminalOutputForSelectedProject, selectedProjectHasSession
  - TerminalView: shows real process output when available, auto-scrolls
    to bottom on new output, falls back to mock when no process running
  - 27 new ProcessIntegrationTests (93 total): parser status/event mapping,
    JSONL line parsing, tool use extraction, subagent detection, token
    counting, cost estimation, process initialization, path hashing,
    session management (start creates root agent, stop marks idle,
    stop preserves error)

Blockers: None
Next: Phase 7 — Polish + MVP Ship
```

### Session 2 (continued) — 2026-03-17

```
Phase 7 — Polish + MVP Ship:
  - Expanded panel ops mode: sprites top half, terminals bottom half,
    internal divider ratio, GeometryReader-based split
  - MultiTerminalGrid: 1 terminal full width, 2 side-by-side, 3-4 as 2×2
    grid, empty state when no terminal open
  - Error recovery UI: clicking errored sprite auto-opens terminal view
  - Empty states: EmptyProjectView (no project selected — folder icon +
    "Add Project" button), EmptyAgentView (project selected but no agents —
    terminal icon + "Start Session" button)
  - ContentView: conditional rendering based on project/agent state
  - 10 new PolishTests (103 total): empty states, error recovery,
    panel snap states, terminal grid, performance with 8+ agents,
    mock data structure validation

Deferred to v2:
  - App icon (pixel art blob robots)
  - Menu bar item (aggregate status)
  - Session restore (reconnect on relaunch)
  - Spawn animation (scale 0→1 over 0.4s)
  - @AppStorage panel height persistence

Blockers: None
Status: v0.1 MVP complete
```

---

## Pre-Phase 4 checklist

- [x] Verify traffic light hover: all 3 at 40% default, window hover → 100%, button hover → icon
- [x] Verify mock data has 2 root agents + 2–3 subs each — fixed: added component-gen sub to ui-builder (now 2 roots × 2 subs each = 6 agents)
- [x] Confirm Project.path stores the NSOpenPanel-selected URL
- [x] Confirm SpriteRenderer.swift is used by SpriteThumbnail (not duplicated logic)
- [x] Run xcodebuild + tests to confirm clean baseline before Phase 4 — 46 tests, 0 failures

---

## Open questions (resolve before Phase 6)

- [x] **JSONL path**: `~/.claude/projects/<path-hash>/<session-uuid>.jsonl` — path hash is project path with `/` → `-`, subagents at `<session-uuid>/subagents/agent-<hash>.jsonl`
- [x] **Spawn vs attach**: Spawn — Botcrew launches Claude Code sessions itself via Foundation.Process
- [x] **Sprite design**: Blob (Figma v2) — decided, implemented in SpriteThumbnail
- [x] **Agent color assignment**: Fixed role-based palette — decided, using colors from CLAUDE.md
- [x] **Office panel placeholder**: OfficePanelView has a 26px bar (project name + agent dots) + solid rectangle canvas. Clean stub, safe to overwrite in Phase 4.

---

## Known issues / gotchas

- Agent-terminal sync can desync when terminals are rapidly opened/closed. Document but don't block on it — known issue in Pixel Agents too.
- JSONL state detection is heuristic. Agents may briefly show wrong status. Acceptable for v1.
- Figma MCP only works through Claude desktop app, not browser. Use `CLAUDE_CODE_REFERENCE.md` as static reference instead.
