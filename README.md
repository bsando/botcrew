# BotCrew

A native macOS app (SwiftUI) for managing Claude Code multi-agent sessions. Pixel art office with animated sprites representing each agent. Feed-primary, ambient office panel below.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green)

## What it does

Botcrew solves three problems with Claude Code multi-agent workflows:

1. **No visibility** into what subagents are doing or their hierarchy
2. **Context loss** when switching between repos/sessions
3. **No cost tracking** across sessions

It reads Claude Code's JSONL transcript files (no modification to Claude Code needed) and presents a unified view: project sidebar, agent tabs, activity feed, and a pixel art office where each sprite = one agent.

## Features

- **Project sidebar** — Add/remove projects, status dots, token/cost tracking
- **Agent tab bar** — Root + sub-agent clusters, expand/collapse, sprite thumbnails, inline renaming
- **Structured activity feed** — Collapsible tool cards with diffs, code blocks, command output
- **Pixel art office** — Animated blob sprites with typing/reading/waiting/idle/error states
- **Prompt input** — Send prompts to Claude Code directly from the app
- **Permission controls** — Auto/supervised/safe permission modes with tool approval UI
- **Session history** — Browse and resume past Claude Code sessions
- **Cost dashboard** — Daily cost chart, per-project breakdown, token tracking
- **Git integration** — Status, diff viewer, and commit support (⌘G)
- **Prompt templates** — Built-in and custom templates for common workflows
- **Session restore** — Auto-detects recent sessions on relaunch, reconstructs agent hierarchy
- **Sound notifications** — System sounds on session complete, error, and subagent spawn
- **Light + dark mode** — Follows system theme with adaptive colors (office panel stays dark)
- **State persistence** — Projects, settings, and cost history saved across launches
- **Keyboard shortcuts** — Full keyboard navigation (⌘↑↓ projects, ⌘←→ agents, ⌘\ sidebar, ⌘T terminal)

## Getting started

### Prerequisites

- macOS 14 (Sonoma) or later
- Xcode 16+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build & run

```bash
# Generate Xcode project
xcodegen generate

# Build (headless)
xcodebuild -scheme Botcrew -destination 'platform=macOS' -configuration Debug build

# Or open in Xcode and hit ⌘R
open Botcrew.xcodeproj
```

### Run tests

```bash
xcodebuild test -scheme Botcrew -destination 'platform=macOS' -configuration Debug
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Titlebar (traffic lights)                      │
├──────────┬──────────────────────────────────────┤
│          │  Tab bar (root + sub-agent clusters)  │
│ Sidebar  ├──────────────────────────────────────┤
│ (168px)  │  Activity feed / Terminal view        │
│          │  Tool approval banner                 │
│ Projects ├──────────────────────────────────────┤
│ + tokens │  Drag divider (snap: 0/148/270px)    │
│ + cost   ├──────────────────────────────────────┤
│          │  Pixel office panel                   │
│          ├──────────────────────────────────────┤
│          │  Prompt input bar                     │
└──────────┴──────────────────────────────────────┘
```

### Key components

| Layer | Purpose |
|---|---|
| `AppState` | `@Observable` central state, persistence, process management |
| `ClaudeCodeProcess` | Foundation.Process wrapper, stream-JSON protocol |
| `JSONLWatcher` | DispatchSource file watching on Claude Code transcripts |
| `AgentStateParser` | JSONL event → agent state heuristics |
| `SessionScanner` | Scans past JSONL sessions for history/resume |
| `GitService` | Shell-out to git CLI for status/diff/commit |

### How it works

1. You add a project directory via the sidebar
2. Send a prompt from the input bar — Botcrew spawns a `claude` process with `--output-format stream-json`
3. JSONL transcript events drive sprite animations and the activity feed in real-time
4. Subagent spawns are detected automatically and appear as new tabs/sprites
5. Token usage and costs are tracked per-session

## File structure

```
Botcrew/
├── App/
│   ├── BotcrewApp.swift          # Entry point, window, commands
│   ├── AppState.swift            # Central state + persistence
│   ├── ContentView.swift         # Main layout + keyboard shortcuts
│   └── Theme.swift               # Adaptive color tokens (light/dark)
├── Models/
│   ├── Project.swift             # Project + SavedProject (Codable)
│   ├── Agent.swift               # Agent model + status enum
│   ├── ActivityEvent.swift       # Feed events with structured tool data
│   ├── CostRecord.swift          # Per-session cost tracking
│   ├── GitStatus.swift           # Git file changes + info
│   ├── PromptTemplate.swift      # Built-in + custom templates
│   ├── SessionInfo.swift         # Past session metadata
│   └── ToolApproval.swift        # Permission denial handling
├── Views/
│   ├── Sidebar/                  # Project list, token card, cost dashboard, session history
│   ├── TabBar/                   # Root/sub tabs with inline renaming
│   ├── Feed/                     # Activity feed, tool cards, prompt bar, templates, approval banner
│   ├── Office/                   # Pixel office canvas, sprites, drag divider
│   └── Git/                      # Git panel (status, diff, commit)
├── Services/
│   ├── ClaudeCodeProcess.swift   # Process lifecycle + stream-JSON parsing
│   ├── JSONLWatcher.swift        # DispatchSource transcript watching
│   ├── AgentStateParser.swift    # Event parsing → agent state
│   ├── SessionScanner.swift      # Past session scanning
│   ├── GitService.swift          # Git CLI operations
│   └── SoundService.swift        # System sound notifications
└── Assets/
    └── SpriteData.swift          # Pixel arrays (blob sprites)
```

## License

Personal project by Brian Sanders.
