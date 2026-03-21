# Botcrew — Testing Guide

## Running Tests

```bash
# Unit + Integration + Performance tests
xcodebuild test -scheme Botcrew -destination 'platform=macOS' -configuration Debug

# UI tests (launches the app)
xcodebuild test -scheme Botcrew -destination 'platform=macOS' -configuration Debug -only-testing:BotcrewUITests

# Unit tests only
xcodebuild test -scheme Botcrew -destination 'platform=macOS' -configuration Debug -only-testing:BotcrewTests
```

---

## Test Suite Overview

| Suite | File | Count | What it covers |
|---|---|---|---|
| AppStateTests | AppStateTests.swift | 17 | Project/agent CRUD, selection, mock data |
| ModelTests | ModelTests.swift | 8 | Model structs, enums, CaseIterable |
| SpriteDataTests | SpriteDataTests.swift | 4 | Pixel grid dimensions, value validity |
| TabSelectionTests | TabSelectionTests.swift | 11 | Agent selection, cluster expand/collapse |
| FeedTests | FeedTests.swift | 6 | Event filtering, terminal toggle |
| OfficeLayoutTests | OfficeLayoutTests.swift | 12 | Sprite layout, snap states, shapes |
| AnimationTests | AnimationTests.swift | 8 | Bob params, shape selection by status |
| ProcessIntegrationTests | ProcessIntegrationTests.swift | 27 | JSONL parsing, tool mapping, sessions |
| PolishTests | PolishTests.swift | 10 | Empty states, error recovery, ops mode |
| EdgeCaseTests | EdgeCaseTests.swift | ~30 | Malformed JSONL, rapid updates, orphans |
| IntegrationTests | IntegrationTests.swift | ~15 | End-to-end flows, real JSONL format |
| PerformanceTests | PerformanceTests.swift | 7 | Benchmarks: layout, events, parsing |
| BotcrewUITests | BotcrewUITests.swift | ~15 | App launch, sidebar, tabs, feed, panels |

---

## Manual Testing Checklist

Run through these after any significant change. Open the app in Xcode (Cmd+R).

### Window & Chrome
- [ ] App launches at 900x640 minimum
- [ ] Window has dark appearance with translucent material background
- [ ] Traffic lights (close/minimize/maximize) show at 40% opacity
- [ ] Hovering window → traffic lights go to 100% opacity
- [ ] Hovering individual button → shows icon (x, -, arrows)

### Sidebar
- [ ] Three projects visible: botcrew (active), api-server (idle), docs-site (error)
- [ ] Active project has blue selection highlight + border
- [ ] Agent status sub-dots visible under botcrew project
- [ ] Click project → tab bar + feed + office all update
- [ ] Click api-server → shows "No active sessions" empty state
- [ ] Collapse button (sidebar.left icon) collapses to 44px icon-only mode
- [ ] Collapsed mode shows project dots, clicking them switches projects
- [ ] Expand button restores full sidebar
- [ ] "Add Project" button opens sheet
- [ ] Add Project sheet: name field, directory picker, cancel/add buttons
- [ ] Right-click project → "Remove Project" context menu
- [ ] Token card at bottom shows formatted count + cost

### Tab Bar
- [ ] Root tabs visible: orchestrator, ui-builder
- [ ] Root tabs show sprite thumbnails + status pips
- [ ] Click root tab → expands that cluster (shows sub-tabs)
- [ ] Click expanded root tab again → collapses cluster (shows dots)
- [ ] Sub-tabs visible when cluster expanded: writer-1, test-runner, etc.
- [ ] Click sub-tab → selects that agent (parent stays highlighted)
- [ ] docs-site project: error tab has red border + pulsing pip
- [ ] Collapsed clusters show inline sub-status dots

### Activity Feed
- [ ] Select an agent → feed shows that agent's events
- [ ] Event rows show correct icons: (spawn), ↑ (write), ↓ (read), $ (bash), · (thinking), ! (error)
- [ ] Events sorted newest first
- [ ] Feed header shows agent color swatch, name, role badge (root)
- [ ] Status pill shows current status with colored dot
- [ ] Reading status shows animated thinking dots
- [ ] Activity/Terminal toggle buttons work
- [ ] Terminal view shows monospaced text on dark background
- [ ] No agent selected → "Select an agent to view activity"

### Office Panel
- [ ] Default height: 148px (ambient mode)
- [ ] Sprites visible with pixel-art blob bodies
- [ ] Each sprite bobs independently at different phases
- [ ] Writing agents bob faster (0.45s cycle)
- [ ] Idle agents bob slowly (1.3s cycle)
- [ ] Waiting agents show "waiting" amber bubble
- [ ] Typing agents show "writing..." green bubble
- [ ] Active cluster at full opacity, inactive at 45%
- [ ] Error sprites at full opacity regardless of cluster dimming
- [ ] Error sprites: red body flash + pulsing red halo + ! badge
- [ ] Click sprite → selects matching tab (bidirectional sync)
- [ ] Click tab → highlights matching sprite (bidirectional sync)
- [ ] Selected sprite has blue selection ring
- [ ] Dashed tether lines from subs to root (curved upward)
- [ ] Cluster zones with dashed borders and tinted backgrounds
- [ ] Agent name labels below sprites (active cluster only)
- [ ] Status dots (6px) top-right of each sprite

### Drag Divider
- [ ] Dragging divider resizes office panel
- [ ] Release near 26px → snaps to collapsed
- [ ] Release near 148px → snaps to ambient
- [ ] Release near 270px → snaps to expanded
- [ ] Hover divider → snap buttons appear (collapse/ambient/expand)
- [ ] Click snap buttons → panel animates to target height
- [ ] Cursor changes to resize arrow on hover

### Expanded Panel (Ops Mode)
- [ ] At 270px: sprites on top half, terminals on bottom half
- [ ] Internal divider visible between sprites and terminals
- [ ] Terminal grid shows in bottom section

### Collapsed Panel
- [ ] At 26px: only bar visible with "OFFICE" label + project name
- [ ] Cluster dot groups visible in bar
- [ ] Chevron-up button visible → click restores to ambient

### Error Recovery
- [ ] Click errored sprite → auto-opens terminal view
- [ ] Error agent's events include error event type

### Empty States
- [ ] No project selected → folder icon + "Add Project" button
- [ ] Project with no agents → prompt input bar visible

### Prompt Input Bar
- [ ] Text field visible at bottom of main content area
- [ ] Permission mode badge (colored: red=auto, amber=supervised, green=safe)
- [ ] Click permission badge → picker with mode descriptions
- [ ] Template button → opens popover with template browser
- [ ] Send button sends prompt, shows spinner while working
- [ ] Placeholder text changes based on state (working/follow-up/initial)

### Tool Approval Banner
- [ ] When Claude requests a denied tool → amber banner appears
- [ ] Banner shows tool name, summary, expandable detail
- [ ] "Deny" dismisses the banner
- [ ] "Allow & Continue" re-runs with allowed tools

### Structured Feed (ToolCardView)
- [ ] Events show as collapsible cards with SF Symbol icons
- [ ] Write events show green icon, read blue, bash orange, etc.
- [ ] Click card → expands to show file content, diffs, or command output
- [ ] Diff blocks show red (removed) and green (added) lines

### Session History
- [ ] Right-click project → "Session History..." in context menu
- [ ] Sheet lists past JSONL sessions with date, summary, file size
- [ ] "Resume" button launches claude with --resume

### Cost Dashboard
- [ ] Click token card in sidebar → cost dashboard sheet opens
- [ ] Today and all-time cost cards visible
- [ ] 7-day bar chart renders (SwiftUI Charts)
- [ ] Per-project cost breakdown listed

### Git Integration
- [ ] ⌘G opens git panel sheet
- [ ] Branch name displayed in header
- [ ] Changed files listed with status color (M=yellow, A=green, D=red, ??=gray)
- [ ] Checkboxes for selecting files to commit
- [ ] "Select All" / "Deselect All" toggle works
- [ ] "diff" button on each file shows inline diff
- [ ] Commit message field + commit button (disabled when empty)

### Prompt Templates
- [ ] Template button in prompt bar opens popover
- [ ] 6 built-in templates visible
- [ ] Search field filters templates
- [ ] Category filter pills work
- [ ] Selecting template fills prompt bar text
- [ ] "New Template" form with name, prompt, category

### Inline Renaming
- [ ] Double-click project name in sidebar → editable text field
- [ ] Double-click agent name in tab bar → editable text field
- [ ] Right-click → "Rename" context menu option
- [ ] Press Enter or click away to commit rename
- [ ] Press Escape to cancel

### State Persistence
- [ ] Close and reopen app → projects list preserved
- [ ] Permission mode setting preserved
- [ ] Custom templates preserved
- [ ] Cost history preserved

### Keyboard Shortcuts
- [ ] ⌘↑ → previous project
- [ ] ⌘↓ → next project
- [ ] ⌘← → previous agent
- [ ] ⌘→ → next agent
- [ ] ⌘Return → toggle cluster
- [ ] ⌘\ → toggle sidebar
- [ ] ⌘T → toggle terminal
- [ ] ⌘G → git panel
- [ ] ⌘Shift↑ → expand office panel
- [ ] ⌘Shift↓ → collapse office panel

### Performance
- [ ] Office canvas smooth at 60fps with mock data (6 agents)
- [ ] No visible stuttering when switching between projects
- [ ] Feed scrolls smoothly with many events
- [ ] Tab bar responds instantly to clicks

---

## Integration Testing (Manual)

These require a real Claude Code installation.

### Spawn a Real Session
1. Add a real project directory via the sidebar
2. Click "Start Session" in the empty agent state
3. Verify: root agent "claude" appears in tab bar
4. Verify: terminal view shows real claude output
5. Verify: activity feed populates with tool use events
6. Verify: agent status changes (reading → typing → idle)
7. Verify: token count updates in sidebar

### Subagent Detection
1. Start a session that will spawn subagents (e.g., "run tests and fix failures")
2. Verify: new sub-agent tabs appear automatically
3. Verify: sub-agents have color from palette (green, amber, blue, coral)
4. Verify: tether lines connect subs to root in office
5. Verify: cluster auto-expands when new sub spawns

### Error Handling
1. Trigger an error in a Claude session
2. Verify: sprite turns to ERROR shape with X-eyes
3. Verify: red body flash at 12Hz
4. Verify: pulsing red halo around sprite
5. Verify: ! badge above sprite
6. Verify: tab pip turns red and pulses
7. Verify: clicking errored sprite opens terminal

### Stop Session
1. Stop a running session
2. Verify: agents go to idle status (except errored ones)
3. Verify: project status changes to idle
4. Verify: terminal output preserved (ring buffer)
