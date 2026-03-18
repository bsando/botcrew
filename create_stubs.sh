#!/bin/bash
# Run this from the repo root to create all Swift file stubs before handing off to Claude Code.
# Claude Code will fill these in rather than invent paths.
#
# Usage: chmod +x scripts/create_stubs.sh && ./scripts/create_stubs.sh

set -e

APP="Botcrew"
mkdir -p "$APP/App"
mkdir -p "$APP/Models"
mkdir -p "$APP/Views/Sidebar"
mkdir -p "$APP/Views/TabBar"
mkdir -p "$APP/Views/Feed"
mkdir -p "$APP/Views/Office"
mkdir -p "$APP/Services"
mkdir -p "$APP/Assets"
mkdir -p scripts

files=(
  "$APP/App/BotcrewApp.swift"
  "$APP/App/AppState.swift"
  "$APP/App/ContentView.swift"
  "$APP/Models/Project.swift"
  "$APP/Models/Agent.swift"
  "$APP/Models/ActivityEvent.swift"
  "$APP/Views/Sidebar/SidebarView.swift"
  "$APP/Views/Sidebar/TokenCard.swift"
  "$APP/Views/TabBar/TabBarView.swift"
  "$APP/Views/TabBar/RootTabView.swift"
  "$APP/Views/TabBar/SubTabView.swift"
  "$APP/Views/Feed/ActivityFeedView.swift"
  "$APP/Views/Feed/FeedHeaderView.swift"
  "$APP/Views/Feed/EventRowView.swift"
  "$APP/Views/Feed/TerminalView.swift"
  "$APP/Views/Office/OfficePanelView.swift"
  "$APP/Views/Office/OfficeCanvasView.swift"
  "$APP/Views/Office/DragDividerView.swift"
  "$APP/Views/Office/SpriteRenderer.swift"
  "$APP/Services/ClaudeCodeProcess.swift"
  "$APP/Services/JSONLWatcher.swift"
  "$APP/Services/AgentStateParser.swift"
  "$APP/Assets/SpriteData.swift"
)

for f in "${files[@]}"; do
  if [ ! -f "$f" ]; then
    filename=$(basename "$f" .swift)
    cat > "$f" << EOF
// $filename.swift
// Botcrew
//
// TODO: Implement this file. See PROJECT_PLAN.md for task checklist
// and CLAUDE.md for architecture details.

import SwiftUI

// MARK: - $filename
EOF
    echo "created $f"
  else
    echo "exists  $f (skipped)"
  fi
done

echo ""
echo "✓ File stubs created. Open Botcrew.xcodeproj and add these files to the Xcode target."
echo "  File > Add Files to 'Botcrew'... → select the Botcrew/ directory."
