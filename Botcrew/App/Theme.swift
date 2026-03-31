// Theme.swift
// Botcrew

import SwiftUI

/// Adaptive color tokens for light/dark mode support.
/// Identity colors (agent body/shirt, status dots, error red, system blue) are NOT included here
/// because they stay the same in both modes.
enum Theme {
    // MARK: - Backgrounds

    static func windowBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 40/255, opacity: 0.85)
            : Color(white: 246/255, opacity: 0.8)
    }

    static func sidebarBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 30/255, opacity: 0.7)
            : Color(white: 230/255, opacity: 0.7)
    }

    static func contentBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 30/255, opacity: 0.6)
            : Color(white: 245/255, opacity: 0.6)
    }

    static func tabBarBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 40/255, opacity: 0.8)
            : Color(white: 235/255, opacity: 0.8)
    }

    static func tabBg(_ scheme: ColorScheme, isSelected: Bool, isExpanded: Bool) -> Color {
        if isSelected {
            return Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.15)
        }
        if isExpanded {
            return scheme == .dark
                ? Color(white: 50/255, opacity: 0.6)
                : Color(white: 200/255, opacity: 0.6)
        }
        return scheme == .dark
            ? Color(white: 50/255, opacity: 0.3)
            : Color(white: 210/255, opacity: 0.3)
    }

    static func subTabBg(_ scheme: ColorScheme, isSelected: Bool) -> Color {
        if isSelected {
            return Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.15)
        }
        return scheme == .dark
            ? Color(white: 50/255, opacity: 0.2)
            : Color(white: 210/255, opacity: 0.3)
    }

    static func terminalBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 15/255, green: 15/255, blue: 20/255)
            : Color(white: 248/255)
    }

    static func promptBarBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 35/255, opacity: 0.9)
            : Color(white: 240/255, opacity: 0.9)
    }

    static func cardBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.03)
            : Color.black.opacity(0.03)
    }

    static func codeBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 0.08)
            : Color(white: 0.94)
    }

    // MARK: - Text

    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.85) : .black.opacity(0.85)
    }

    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.55) : .black.opacity(0.55)
    }

    static func textTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.30) : .black.opacity(0.30)
    }

    static func textMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.35) : .black.opacity(0.40)
    }

    static func textOnDark(_ scheme: ColorScheme) -> Color {
        // For elements that are always on dark backgrounds (office panel, etc.)
        .white.opacity(0.85)
    }

    // MARK: - UI Elements

    static func separator(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.10)
    }

    static func iconDefault(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.45) : .black.opacity(0.45)
    }

    static func iconMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.35) : .black.opacity(0.35)
    }

    // MARK: - Office Panel (always dark)

    static let officeBarBg = Color(red: 15/255, green: 16/255, blue: 32/255)
    static let officeFloorBg = Color(red: 25/255, green: 26/255, blue: 46/255)
}
