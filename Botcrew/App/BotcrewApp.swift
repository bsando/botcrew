// BotcrewApp.swift
// Botcrew

import SwiftUI

@main
struct BotcrewApp: App {
    @State private var appState = AppState.withMockData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .scaleEffect(appState.zoomLevel)
                .frame(
                    minWidth: 900 * appState.zoomLevel,
                    minHeight: 640 * appState.zoomLevel
                )
                .environment(appState)
                .preferredColorScheme(.dark)
                .background(.ultraThinMaterial)
                .background(Color(red: 25/255, green: 25/255, blue: 30/255, opacity: 0.4))
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 640)
        .commands {
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
