// BotcrewApp.swift
// BotCrew

import SwiftUI

@main
struct BotcrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
        .defaultSize(width: 1100, height: 700)
        .commands {
            // Disable Cmd+N (no multi-window)
            CommandGroup(replacing: .newItem) {}

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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Close extra windows — WindowGroup sometimes restores multiples
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let windows = NSApplication.shared.windows.filter { $0.isVisible }
            guard windows.count > 1 else { return }
            for window in windows.dropFirst() {
                window.close()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
