//
//  Extensions.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

// MARK: - Design System
extension Color {
    static let aquaPrimary = Color(red: 0.41, green: 0.77, blue: 0.80)  // #68C5CB

    // Adaptive text color: Navy in Light mode, White in Dark mode
    static let aquaNavy = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? .white : UIColor(red: 0.11, green: 0.23, blue: 0.31, alpha: 1)
        })

    static let aquaSafe = Color.green  //
    static let aquaWarning = Color(red: 0.96, green: 0.62, blue: 0.04)  // #F59E0B
    static let aquaDanger = Color(red: 0.94, green: 0.27, blue: 0.27)  // #EF4444
    static let aquaCritical = Color(red: 0.435, green: 0.176, blue: 0.988)  //##6F2DFC

    // Overall background color (light gray / dark)
    static let aquaBackground = Color(UIColor.systemGroupedBackground)

    // Card background color (white / dark gray)
    static let aquaCard = Color(UIColor.secondarySystemGroupedBackground)
}
