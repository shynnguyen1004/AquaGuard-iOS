//
//  Extensions.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

// MARK: - Design System
extension Color {
    // Stronger teal — bolder in light mode, still vibrant in dark
    static let aquaPrimary = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.41, green: 0.77, blue: 0.80, alpha: 1)  // #68C5CB (dark)
                : UIColor(red: 0.18, green: 0.67, blue: 0.70, alpha: 1)  // #2EAAB3 (light)
        })

    // Adaptive text color: Navy in Light mode, White in Dark mode
    static let aquaNavy = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? .white : UIColor(red: 0.08, green: 0.16, blue: 0.24, alpha: 1)  // #142840 deeper navy
        })

    static let aquaSafe = Color.green  //
    static let aquaWarning = Color(red: 0.96, green: 0.62, blue: 0.04)  // #F59E0B
    static let aquaDanger = Color(red: 0.94, green: 0.27, blue: 0.27)  // #EF4444
    static let aquaCritical = Color(red: 0.435, green: 0.176, blue: 0.988)  //##6F2DFC

    // Overall background color (light gray / dark navy)
    static let aquaBackground = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.063, green: 0.106, blue: 0.149, alpha: 1)  // #101B26
                : .systemGroupedBackground
        })

    // Card background color (white / dark card)
    static let aquaCard = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.086, green: 0.145, blue: 0.208, alpha: 1)  // #162535
                : .white
        })

    // Input/Textarea background (white / slate-800)
    static let aquaInputBg = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.118, green: 0.161, blue: 0.231, alpha: 1)  // #1e293b
                : .secondarySystemGroupedBackground
        })

    // Input border (light gray / slate-700)
    static let aquaInputBorder = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.255, blue: 0.333, alpha: 1)  // #334155
                : UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        })

    // Modal background (system / slate-900)
    static let aquaModalBg = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.059, green: 0.090, blue: 0.165, alpha: 1)  // #0f172a
                : .systemBackground
        })

    // Divider color (light / slate-800)
    static let aquaDivider = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.118, green: 0.161, blue: 0.231, alpha: 1)  // #1e293b
                : UIColor.separator
        })

    // Subtitle text — stronger than .secondary in light mode
    static let aquaSubtitle = Color(
        UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondaryLabel
                : UIColor(red: 0.35, green: 0.40, blue: 0.45, alpha: 1)  // #596673
        })
}
