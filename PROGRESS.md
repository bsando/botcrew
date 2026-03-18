# Botcrew — Progress

**Read this at the start of every Claude Code session.** It tells you where the project is and what to do next.

---

## Current state

**Phase**: 3 — Complete
**Status**: Phases 0–3 done. App has functional sidebar with project switching, tab bar with expandable agent clusters and sprite thumbnails, activity feed with event filtering and terminal toggle. 46 tests passing.
**Next action**: Begin Phase 4 — Pixel Office Panel (canvas renderer, sprite clusters, tethers, bidirectional selection).

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
- [ ] Phase 4 — Pixel Office Panel
- [ ] Phase 5 — Sprite Animations
- [ ] Phase 6 — JSONL Process Integration
- [ ] Phase 7 — Polish + MVP Ship

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

Blockers: None
Next: Phase 4 — Pixel Office Panel
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

- [ ] **JSONL path**: Run `find ~/.claude -name "*.jsonl" | head -5` and record the actual path here: `___________`
- [ ] **Spawn vs attach**: Does Botcrew spawn new `claude` processes or attach to existing terminals? (Recommend: spawn for v1)
- [x] **Sprite design**: Blob (Figma v2) — decided, implemented in SpriteThumbnail
- [x] **Agent color assignment**: Fixed role-based palette — decided, using colors from CLAUDE.md
- [x] **Office panel placeholder**: OfficePanelView has a 26px bar (project name + agent dots) + solid rectangle canvas. Clean stub, safe to overwrite in Phase 4.

---

## Known issues / gotchas

- Agent-terminal sync can desync when terminals are rapidly opened/closed. Document but don't block on it — known issue in Pixel Agents too.
- JSONL state detection is heuristic. Agents may briefly show wrong status. Acceptable for v1.
- Figma MCP only works through Claude desktop app, not browser. Use `CLAUDE_CODE_REFERENCE.md` as static reference instead.
