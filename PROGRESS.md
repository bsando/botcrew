# Botcrew — Progress

**Read this at the start of every Claude Code session.** It tells you where the project is and what to do next.

---

## Current state

**Phase**: 0 — Ready to start  
**Status**: Repo created with all planning files. Hand off to Claude Code.  
**Next action**: Tell Claude Code — *"Read CLAUDE.md, PROGRESS.md, and PROJECT_PLAN.md. Then implement Phase 0 in full, including creating the Xcode project. Verify with xcodebuild before marking done."*

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

- [ ] Phase 0 — Scaffold (Xcode project, window, layout skeleton)
- [ ] Phase 1 — Sidebar + Projects
- [ ] Phase 2 — Tab Bar + Agent Hierarchy
- [ ] Phase 3 — Activity Feed
- [ ] Phase 4 — Pixel Office Panel
- [ ] Phase 5 — Sprite Animations
- [ ] Phase 6 — JSONL Process Integration
- [ ] Phase 7 — Polish + MVP Ship

---

## Session log

### Session 1 — [date]
*Update this section at the start of each session with what you accomplished.*

```
Started: Phase 0
Completed: [list tasks finished]
Blockers: [anything that stopped progress]
Next: [exact next task]
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
