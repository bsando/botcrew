// OfficePanelView.swift
// Botcrew

import SwiftUI

struct OfficePanelView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("OFFICE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.horizontal, 12)
                Spacer()
            }
            .frame(height: 26)
            .background(Color(red: 15/255, green: 16/255, blue: 32/255))

            Rectangle()
                .fill(Color(red: 25/255, green: 26/255, blue: 46/255))
        }
    }
}
