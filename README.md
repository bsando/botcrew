# BotCrew

A native macOS app for watching Claude Code multi-agent sessions in real time. See what every agent is doing, track costs, and manage sessions — all from a pixel art office where each sprite is a live agent.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![MIT License](https://img.shields.io/badge/license-MIT-green)

## Install

Download the latest `.dmg` from [Releases](https://github.com/bsando/botcrew/releases), open it, and drag BotCrew to Applications.

> **Requires**: macOS 14 (Sonoma) or later and [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed.

## How it works

BotCrew reads Claude Code's JSONL transcript files. It doesn't modify Claude Code in any way — it's purely observational.

1. **Add a project** — Click + in the sidebar, pick any directory where you use Claude Code
2. **Send a prompt** — Type in the prompt bar at the bottom. BotCrew launches `claude` with stream-json output and shows everything in real time
3. **Watch agents work** — Each agent gets a sprite in the pixel office and a tab in the tab bar. Subagents appear automatically when spawned
4. **Track costs** — Token usage and cost estimates are tracked per-session with model-specific pricing (Sonnet/Opus/Haiku)

You can also **attach to a running session** — click "Attach to Session" in the sidebar to watch a `claude` session that's already running in another terminal. It's read-only and auto-detaches when the session goes idle.

That's it. Add your project, send a prompt, watch the sprites go.

## What you see

```
+----------+--------------------------------------+
|          |  Tab bar (agents)                    |
|          +--------------------------------------+
| Sidebar  |  Activity feed                       |
| Projects |  (tool calls, diffs, output)         |
| + costs  +--------------------------------------+
|          |  Pixel office (sprites = agents)      |
|          +--------------------------------------+
|          |  Prompt input bar                     |
+----------+--------------------------------------+
```

- **Sidebar** — Your projects with status dots, token counts, and cost tracking. Session history for resuming past sessions. Attach to running sessions.
- **Tab bar** — Root agents as large tabs, subagents tucked underneath. Click to switch. Clusters expand/collapse.
- **Activity feed** — Structured tool cards showing file reads/writes with diffs, bash commands with output, and agent spawns. Toggle to raw terminal view with `Cmd+T`.
- **Pixel office** — Animated blob sprites. Typing = hunched + fast bob. Waiting = arms wide. Error = X eyes + red flash. Click a sprite to select that agent's tab.
- **Prompt bar** — Send prompts with permission mode picker (Auto / Supervised / Safe). Prompt templates for common workflows.

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Up/Down` | Switch projects |
| `Cmd+Left/Right` | Switch agents |
| `Cmd+\` | Toggle sidebar |
| `Cmd+T` | Toggle terminal/feed |
| `Cmd+G` | Git panel |
| `Cmd+Shift+Up/Down` | Snap office panel (collapse/ambient/expanded) |

## Features

- **Real-time JSONL tailing** — DispatchSource file watching, no polling
- **Agent hierarchy** — Automatically detects subagent spawns and builds the tree
- **Cost tracking** — Model-specific pricing (Sonnet $3/$15, Opus $15/$75, Haiku $0.80/$4) with correct cache token rates
- **Session resume** — Browse past sessions, resume with `--resume`
- **Permission modes** — Auto (skip all), Supervised (approve each), Safe (read-only tools)
- **Tool approval** — When Claude asks for permission, a banner lets you approve/deny
- **Git integration** — Status, diffs, and commit from the app (`Cmd+G`)
- **Prompt templates** — 6 built-in + custom templates with categories
- **Sound notifications** — Glass/Basso/Pop for session complete, errors, spawns (toggleable)
- **Attach mode** — Watch an already-running `claude` session from another terminal (read-only, auto-detach)
- **Light + dark mode** — Follows system theme; office panel always stays dark
- **State persistence** — Everything saved across launches

## Build from source

```bash
# Prerequisites: Xcode 16+, xcodegen (brew install xcodegen)

git clone https://github.com/bsando/botcrew.git
cd botcrew
xcodegen generate
open Botcrew.xcodeproj   # Cmd+R to run
```

To build headless (no Apple Developer account needed):
```bash
xcodebuild -scheme Botcrew -destination 'platform=macOS' -configuration Debug build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

Run tests:
```bash
xcodebuild -scheme BotcrewTests -destination 'platform=macOS' test
```

Run the built app:
```bash
open ~/Library/Developer/Xcode/DerivedData/Botcrew-*/Build/Products/Debug/BotCrew.app
```

## License

MIT
