// NotificationService.swift
// Botcrew

import UserNotifications

enum NotificationService {
    enum Event {
        case sessionComplete(projectName: String)
        case error(projectName: String)
        case subagentSpawned(projectName: String, agentName: String)
    }

    /// Request notification permission (call once at app launch)
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Send a macOS notification
    static func send(_ event: Event) {
        let content = UNMutableNotificationContent()

        switch event {
        case .sessionComplete(let name):
            content.title = "Session Complete"
            content.body = "\(name) finished"
            content.sound = .default

        case .error(let name):
            content.title = "Error"
            content.body = "\(name) encountered an error"
            content.sound = UNNotificationSound.defaultCritical

        case .subagentSpawned(let name, let agentName):
            content.title = "Subagent Spawned"
            content.body = "\(agentName) started in \(name)"
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }
}
