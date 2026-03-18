# Botcrew — Design & Architecture Decisions

Extracted from design session. Read this before making any architectural or UX choices — if something feels like it should be decided differently, add a new entry rather than silently changing course.

---

## Product

### Name
**Decision**: Botcrew  
**Rationale**: One word, punchy, immediately communicates "crew of bots working together." Doesn't reference Claude specifically, so works if we support other AI coding agents later.

### Target user
**Decision**: Personal tool first, potential App Store release later  
**Rationale**: Built for Brian's own Claude Code workflow. If it proves useful, distribute via App Store alongside ChordEngine.

---

## Layout

### Sidebar = projects, tabs = agents
**Decision**: Sidebar holds projects (slow-moving). Tab bar holds agents within the active project (fast-moving).  
**Rationale**: Projects are the stable context. Agents are what you're actively managing. The UI hierarchy should match the cognitive hierarchy.  
**Alternative considered**: Tabs as projects, sidebar as agents. Rejected — projects change rarely, agents change constantly.

### Feed primary, office ambient
**Decision**: Activity feed occupies the main content area. Pixel office is an ambient panel below it, not the primary view.  
**Rationale**: "I check in every few minutes" usage pattern. Feed gives fast information-dense reads. Office gives ambient signal without requiring navigation.  
**Alternative considered**: Office as primary UI with click-to-navigate. Rejected for v1 — higher cognitive load, more build complexity.

### Office panel snap states
**Decision**: Three snap heights — collapsed (26px bar), ambient (148px default), expanded (270px ops mode).  
**Rationale**: MacBook and external monitor use cases are different. Collapsed = max feed space on small screen. Ambient = daily driver. Expanded = active debugging session.  
**Implementation**: Drag divider snaps on release. Remembered per project in `@AppStorage`.

---

## Tab bar

### Cluster expand/collapse
**Decision**: Only the active cluster shows subtabs. Inactive clusters collapse to root tab + inline status dots.  
**Rationale**: Two root agents with 3 subs each already fills the tab bar. Three roots would require horizontal scroll. Collapse keeps it manageable at any scale.  
**Behavior**: Clicking inactive root expands it and collapses current. Clicking active root selects the root agent itself.

### Bidirectional sync
**Decision**: Tab selection and sprite selection are the same state. Clicking either updates both.  
**Rationale**: Two representations of the same hierarchy should never disagree. One source of truth in `AppState.selectedAgentId`.

### Sprite thumbnails in tabs
**Decision**: Root tabs show 12×16px sprite thumbnail. Sub tabs show 10×14px sprite thumbnail.  
**Rationale**: Connects the tab bar visually to the office panel. You learn to associate sprite color with agent identity across both representations.

---

## Pixel office

### Blob sprites over humanoid
**Decision**: Use blob/creature design (from Figma v2 prototype) over humanoid pixel sprites.  
**Rationale**: Rounder, more expressive at small sizes. More character at 8×10px. Figma prototype already implements this — less work to port.  
**Note**: `SpriteDesigns.tsx` has 8 alternative designs. Blob is active. Others available if we want to switch.

### Cluster zones
**Decision**: Each root agent gets a faint dashed zone rectangle with a tint. Root sprite at back-center, subs fanned in front row.  
**Rationale**: Cluster membership needs to be legible at a glance without reading labels. Spatial grouping + tether lines do this.

### Tether lines
**Decision**: Dashed lines curve upward from each subagent to its root.  
**Rationale**: Communicates parent-child relationship spatially. Quadratic bezier curve feels organic rather than mechanical.

### Inactive cluster dimming
**Decision**: Inactive cluster sprites render at 45% opacity, no labels, no bubbles.  
**Rationale**: Keeps inactive agents visible for ambient health monitoring without competing for attention with the active cluster.

---

## Error state

### Passive errors
**Decision**: Errors never auto-expand a cluster or steal focus.  
**Rationale**: You're often focused in another cluster. An auto-expand would be jarring mid-task. The four passive signals are loud enough to catch in peripheral vision.

### Four error signals
**Decision**: Error state uses four stacked signals — sprite (ERROR shape + red flash), halo (pulsing radial gradient), ! badge (full opacity always), tab pip (red pulse on sub + root).  
**Rationale**: Error must break through dimming when it's in an inactive cluster. A single signal (just the sprite) could be missed at 45% opacity. The halo is additive and bleeds through dimming. The tab pip catches it even with the office panel collapsed.

### Error at full opacity regardless of cluster state
**Decision**: Errored sprites always render at full opacity, even in dimmed inactive clusters.  
**Rationale**: The whole point of the error system is you can't miss it. Dimming an error defeats the purpose.

---

## macOS design language

### macOS Big Sur+ aesthetics
**Decision**: Use translucent materials, SF Pro font stack, generous spacing, interactive traffic lights.  
**Rationale**: Figma v2 prototype established this direction. Botcrew should feel native and polished, not like an Electron app.  
**Implementation**: SwiftUI `.ultraThinMaterial` / `.regularMaterial` wherever possible rather than hardcoded hex colors.

### Dark mode primary
**Decision**: Dark mode is the primary target. Light mode is a v2 concern.  
**Rationale**: The pixel office canvas looks significantly better dark. The agent colors were designed against dark backgrounds.

### Interactive traffic lights
**Decision**: Replicate macOS Big Sur hover behavior — dots at 40% opacity default, full opacity on window hover, icons appear on individual button hover.  
**Rationale**: This is what makes the app feel native vs. a fake chrome. Worth the implementation effort.

---

## Technical

### One process per tab, never killed
**Decision**: Each agent tab wraps a persistent `Foundation.Process`. Never killed on tab switch.  
**Rationale**: Claude Code session state lives in the process. Killing and restarting loses context. Ring buffer per process stores last N lines of stdout for terminal restore.

### JSONL watching, not process injection
**Decision**: Read Claude Code's JSONL transcript files. Don't modify or intercept Claude Code itself.  
**Rationale**: Same approach proven by Pixel Agents (3.6k stars). Purely observational — no risk of breaking Claude Code sessions.

### Heuristic state detection
**Decision**: Agent state (typing/reading/waiting/idle/error) is inferred from JSONL tool events using heuristics and idle timers.  
**Rationale**: Claude Code's JSONL format doesn't emit clean state transition events. Heuristics will occasionally misfire — this is acceptable for v1.  
**Known issue**: Agent-terminal sync can desync when terminals are rapidly opened/closed. Document but don't block on it.

### Spawn vs attach
**Decision** (pending): Does Botcrew spawn new `claude` processes, or attach to existing terminal sessions?  
**Recommended**: Spawn for v1. Cleaner process lifecycle, no dependency on terminal emulator state.  
**Open**: Confirm before Phase 6.

---

## Deferred decisions

- **Git panel**: Deferred to v2. Would show file changes, branch, diff inline.
- **Split view**: Deferred to v2. Two projects side by side.
- **Sound notifications**: Deferred to v2. Chime on agent completion.
- **Custom sprite skins**: Deferred to v2. Per-agent character selection.
- **Office layout editor**: Deferred to v2. Custom furniture, floor tiles.
- **Light mode**: Deferred to v2.
- **Agent color assignment**: Fixed palette (role-based) vs dynamic assignment. Undecided — resolve in Phase 4.
