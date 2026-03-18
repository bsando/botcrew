// ActivityFeedView.swift
// Botcrew

import SwiftUI

struct ActivityFeedView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Activity Feed")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.35))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 30/255, opacity: 0.6))
    }
}
