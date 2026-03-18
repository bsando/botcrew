// TabBarView.swift
// Botcrew

import SwiftUI

struct TabBarView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("No agents")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 40/255, opacity: 0.8))
    }
}
