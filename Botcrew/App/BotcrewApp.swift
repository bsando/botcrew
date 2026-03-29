// BotcrewApp.swift
// Botcrew

import SwiftUI

@main
struct BotcrewApp: App {
    @State private var appState: AppState = {
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            return AppState.withMockData()
        }
        return AppState()
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 640)
                .background(.ultraThinMaterial)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 640)
        .commands {
            BotcrewCommands(appState: appState)

            CommandGroup(after: .toolbar) {
                Button("Zoom In") {
                    appState.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    appState.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Actual Size") {
                    appState.zoomReset()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}
