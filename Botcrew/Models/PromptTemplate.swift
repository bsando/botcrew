// PromptTemplate.swift
// Botcrew

import Foundation

enum TemplateCategory: String, Codable, CaseIterable {
    case custom, testing, review, refactor, docs, debug

    var label: String {
        switch self {
        case .custom: "Custom"
        case .testing: "Testing"
        case .review: "Review"
        case .refactor: "Refactor"
        case .docs: "Docs"
        case .debug: "Debug"
        }
    }

    var icon: String {
        switch self {
        case .custom: "star"
        case .testing: "checkmark.circle"
        case .review: "magnifyingglass"
        case .refactor: "arrow.triangle.2.circlepath"
        case .docs: "doc.text"
        case .debug: "ant"
        }
    }
}

struct PromptTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var prompt: String
    var category: TemplateCategory
    var isBuiltIn: Bool
    var lastUsed: Date?

    static let builtIn: [PromptTemplate] = [
        PromptTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Fix failing tests",
            prompt: "Run the test suite, identify all failing tests, and fix them one by one. Show me what you changed.",
            category: .testing, isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Review for bugs",
            prompt: "Review the recent changes in this project for bugs, edge cases, and potential issues. Be thorough.",
            category: .review, isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Refactor for clarity",
            prompt: "Look at the codebase and identify the messiest or most complex files. Refactor them for readability without changing behavior.",
            category: .refactor, isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Add documentation",
            prompt: "Add clear documentation to the public API of this project. Focus on functions and types that are missing docs.",
            category: .docs, isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Debug this error",
            prompt: "I'm seeing an error. Help me debug it — read the relevant files, identify the root cause, and fix it.",
            category: .debug, isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Write unit tests",
            prompt: "Write comprehensive unit tests for the core logic in this project. Cover edge cases and error paths.",
            category: .testing, isBuiltIn: true
        ),
    ]
}
