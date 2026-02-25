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

    var body: some View {
        Image("AquaLogoHeader")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .padding(.top, topPadding)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
