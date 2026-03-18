# Botcrew — Progress

**Read this at the start of every Claude Code session.** It tells you where the project is and what to do next.

---

## Current state

**Phase**: 0 — Complete
**Status**: Xcode project builds with 0 errors. App launches with sidebar + main column layout, macOS dark chrome, traffic lights, tab bar, feed placeholder, office panel placeholder, drag divider.
**Next action**: Begin Phase 1 — Sidebar + Projects (project list, add/remove, switching, token card with real mock data).

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
- [ ] Phase 1 — Sidebar + Projects
- [ ] Phase 2 — Tab Bar + Agent Hierarchy
- [ ] Phase 3 — Activity Feed
- [ ] Phase 4 — Pixel Office Panel
- [ ] Phase 5 — Sprite Animations
- [ ] Phase 6 — JSONL Process Integration
- [ ] Phase 7 — Polish + MVP Ship

---

## Session log

### Session 1 — 2025-03-17

```
Started: Phase 0
Completed:
  - Ran create_stubs.sh (23 Swift file stubs)
  - Created project.yml for xcodegen
  - Generated Botcrew.xcodeproj via xcodegen
  - Implemented BotcrewApp.swift (@main, WindowGroup, dark mode, .ultraThinMaterial, hiddenTitleBar)
  - Implemented AppState.swift (@Observable, selectedProjectId/AgentId/ClusterId)
  - Implemented ContentView.swift (HSplitView: 168px sidebar + main column)
  - Implemented MacFrameView.swift (36px titlebar, interactive traffic lights with hover states)
  - Implemented SidebarView.swift (project list with status dots, section headers)
  - Implemented TokenCard.swift (session cost/token placeholders)
  - Implemented TabBarView.swift (placeholder)
  - Implemented ActivityFeedView.swift (placeholder)
  - Implemented OfficePanelView.swift (26px bar + canvas area with correct colors)
  - Implemented DragDividerView.swift (hover highlight, resize cursor)
  - Implemented all 3 model files (Project, Agent, ActivityEvent with enums)
  - All service/sprite stubs compile (empty classes/structs)
  - xcodebuild passes with 0 errors
Blockers: None
Next: Phase 1 — Sidebar + Projects
```

---

## Open questions (resolve before Phase 6)

- [ ] **JSONL path**: Run `find ~/.claude -name "*.jsonl" | head -5` and record the actual path here: `___________`
- [ ] **Spawn vs attach**: Does Botcrew spawn new `claude` processes or attach to existing terminals? (Recommend: spawn for v1)
- [ ] **Sprite design**: Blob (Figma v2) or humanoid (design session)? Both pixel data sets exist.
- [ ] **Agent color assignment**: Fixed role-based palette or dynamically assigned per session?

---

## Known issues / gotchas

- Agent-terminal sync can desync when terminals are rapidly opened/closed. Document but don't block on it — known issue in Pixel Agents too.
- JSONL state detection is heuristic. Agents may briefly show wrong status. Acceptable for v1.
- Figma MCP only works through Claude desktop app, not browser. Use `CLAUDE_CODE_REFERENCE.md` as static reference instead.
