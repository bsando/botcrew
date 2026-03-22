// PromptTemplateSheet.swift
// Botcrew

import SwiftUI

struct PromptTemplateSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: TemplateCategory?
    @State private var editingTemplate: PromptTemplate?
    @State private var showNewTemplate = false
    @State private var newName = ""
    @State private var newPrompt = ""
    @State private var newCategory: TemplateCategory = .custom

    var onSelect: (String) -> Void

    private var allTemplates: [PromptTemplate] {
        let builtIn = PromptTemplate.builtIn
        let custom = appState.promptTemplates
        return builtIn + custom
    }

    private var filteredTemplates: [PromptTemplate] {
        var result = allTemplates
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.prompt.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Prompt Templates")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                Spacer()
                Button {
                    showNewTemplate = true
                    newName = ""
                    newPrompt = ""
                    newCategory = .custom
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: 0x0A84FF))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Search
            TextField("Search templates...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    categoryPill(nil, label: "All")
                    ForEach(TemplateCategory.allCases, id: \.self) { cat in
                        categoryPill(cat, label: cat.label)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)

            Divider().opacity(0.15)

            // Template list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredTemplates) { template in
                        templateRow(template)
                    }
                }
                .padding(8)
            }

            // New template form
            if showNewTemplate {
                Divider().opacity(0.15)
                newTemplateForm
            }
        }
        .frame(width: 420, height: 480)
    }

    private func categoryPill(_ category: TemplateCategory?, label: String) -> some View {
        let isActive = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? Theme.textPrimary(colorScheme) : Theme.textSecondary(colorScheme))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? Color(hex: 0x0A84FF).opacity(0.3) : Theme.cardBg(colorScheme))
                )
        }
        .buttonStyle(.plain)
    }

    private func templateRow(_ template: PromptTemplate) -> some View {
        Button {
            onSelect(template.prompt)
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: template.category.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted(colorScheme))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary(colorScheme))
                        .lineLimit(1)

                    Text(template.prompt)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                        .lineLimit(2)
                }

                Spacer()

                if !template.isBuiltIn {
                    Button {
                        appState.deleteTemplate(template.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary(colorScheme))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.cardBg(colorScheme))
            )
        }
        .buttonStyle(.plain)
    }

    private var newTemplateForm: some View {
        VStack(spacing: 8) {
            HStack {
                Text("New Template")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                Spacer()
                Button("Cancel") { showNewTemplate = false }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted(colorScheme))
            }

            TextField("Template name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))

            TextEditor(text: $newPrompt)
                .font(.system(size: 12))
                .frame(height: 60)
                .scrollContentBackground(.hidden)
                .background(Theme.cardBg(colorScheme))
                .cornerRadius(4)

            HStack {
                Picker("Category", selection: $newCategory) {
                    ForEach(TemplateCategory.allCases, id: \.self) { cat in
                        Text(cat.label).tag(cat)
                    }
                }
                .frame(width: 140)

                Spacer()

                Button("Save") {
                    guard !newName.isEmpty, !newPrompt.isEmpty else { return }
                    appState.saveTemplate(name: newName, prompt: newPrompt, category: newCategory)
                    showNewTemplate = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: 0x0A84FF))
                )
                .disabled(newName.isEmpty || newPrompt.isEmpty)
            }
        }
        .padding(12)
    }
}
