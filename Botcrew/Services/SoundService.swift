// SoundService.swift
// Botcrew

import AppKit

enum SoundService {
    enum Event {
        case sessionComplete
        case error
        case subagentSpawned
    }

    /// Play a system sound for a Botcrew event
    static func play(_ event: Event) {
        let soundName: NSSound.Name
        switch event {
        case .sessionComplete:
            soundName = "Glass"
        case .error:
            soundName = "Basso"
        case .subagentSpawned:
            soundName = "Pop"
        }
        NSSound(named: soundName)?.play()
    }
}
