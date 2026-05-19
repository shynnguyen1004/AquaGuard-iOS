//
//  LogoHeaderView.swift
//  AquaGuard
//
//  Reusable logo header component used across tab views.
//

import SwiftUI

struct LogoHeaderView: View {
    var height: CGFloat = 100
    var topPadding: CGFloat = -20

    @Environment(\.colorScheme) var colorScheme

    private var logoName: String {
        colorScheme == .dark ? "AquaLogoDark" : "AquaLogoHeader"
    }

    var body: some View {
        Image(logoName)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .padding(.top, topPadding)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
