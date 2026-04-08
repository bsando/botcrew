// ZoneEditor.swift
// Botcrew

import SwiftUI

struct ZoneEditor: View {
    @Binding var zoneColor: Color
    @Binding var insets: CGFloat
    @Binding var cornerRadius: CGFloat
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Cluster Zone")
                .font(.system(size: 13, weight: .semibold))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Color")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    ColorPicker("", selection: $zoneColor, supportsOpacity: false)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Padding: \(Int(insets))px")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Slider(value: $insets, in: 0...24, step: 2)
                        .frame(width: 100)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Corner Radius: \(Int(cornerRadius))px")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                Slider(value: $cornerRadius, in: 0...20, step: 2)
                    .frame(width: 180)
            }

            Button("Apply") { onSave() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(16)
        .frame(width: 240)
    }
}
