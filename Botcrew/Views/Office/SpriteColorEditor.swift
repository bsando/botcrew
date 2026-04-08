// SpriteColorEditor.swift
// Botcrew

import SwiftUI

struct SpriteColorEditor: View {
    @Binding var bodyColor: Color
    @Binding var shirtColor: Color
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Sprite Colors")
                .font(.system(size: 13, weight: .semibold))

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Body")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    ColorPicker("", selection: $bodyColor, supportsOpacity: false)
                        .labelsHidden()
                }

                VStack(spacing: 4) {
                    Text("Accent")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    ColorPicker("", selection: $shirtColor, supportsOpacity: false)
                        .labelsHidden()
                }

                // Preview
                SpriteThumbnail(bodyColor: bodyColor, size: .root)
                    .frame(width: 24, height: 32)
                    .scaleEffect(2)
                    .padding(.leading, 8)
            }

            Button("Apply") {
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
        .frame(width: 240)
    }
}
