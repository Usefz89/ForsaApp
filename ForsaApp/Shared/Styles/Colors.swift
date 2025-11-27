//
//  Colors.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let primaryPurple = Color(red: 0.388, green: 0.4, blue: 0.945) // #6366F1
    static let primaryPurpleDark = Color(red: 0.545, green: 0.361, blue: 0.965) // #8B5CF6
    static let primaryGreen = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981
    static let primaryBlue = Color(red: 0.235, green: 0.639, blue: 0.973) // #3C82F6
    static let primaryOrange = Color(red: 0.969, green: 0.533, blue: 0.212) // #F78836

    // MARK: - Background Colors
    static let backgroundPrimary = Color.white
    static let backgroundSecondary = Color(red: 0.976, green: 0.976, blue: 0.976) // #F9F9F9
    static let backgroundTertiary = Color(red: 0.949, green: 0.949, blue: 0.949) // #F3F3F3
    static let backgroundCard = Color.white

    // MARK: - Text Colors
    static let textPrimary = Color(red: 0.067, green: 0.067, blue: 0.067) // #111111
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
    static let textMuted = Color(red: 0.733, green: 0.733, blue: 0.733) // #BBBBBB

    // MARK: - Status Colors
    static let successGreen = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981
    static let errorRed = Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
    static let warningYellow = Color(red: 1.0, green: 0.733, blue: 0.2) // #FFBB33
    static let warningOrange = Color(red: 0.945, green: 0.541, blue: 0.114) // #F18A1D
    static let infoBlue = Color(red: 0.235, green: 0.639, blue: 0.973) // #3C82F6

    // MARK: - Gain/Loss Colors
    static let gainGreen = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981
    static let lossRed = Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444

    // MARK: - Border Colors
    static let borderPrimary = Color(red: 0.898, green: 0.898, blue: 0.898) // #E5E5E5
    static let borderSecondary = Color(red: 0.933, green: 0.933, blue: 0.933) // #EEEEEE
    static let borderLight = Color(red: 0.949, green: 0.949, blue: 0.949) // #F3F3F3

    // MARK: - Sharia Compliance Colors
    static let halalGreen = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981
    static let halalBackground = Color(red: 0.925, green: 0.976, blue: 0.945) // #ECFDF5
    static let nonHalalRed = Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
    static let underReviewOrange = Color(red: 1.0, green: 0.733, blue: 0.2) // #FFBB33

    // MARK: - Gradient Colors
    static let gradientPrimary = LinearGradient(
        colors: [primaryPurple, primaryPurpleDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSecondary = LinearGradient(
        colors: [primaryBlue, primaryPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSuccess = LinearGradient(
        colors: [primaryGreen, Color(red: 0.035, green: 0.584, blue: 0.396)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientCard = LinearGradient(
        colors: [Color.white, Color(red: 0.988, green: 0.988, blue: 0.988)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadow Colors
    static let shadowLight = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.1)
    static let shadowHeavy = Color.black.opacity(0.15)

    // MARK: - Tab Bar Colors
    static let tabBarBackground = Color.white
    static let tabBarSelected = primaryPurple
    static let tabBarUnselected = textTertiary

    // MARK: - Chart Colors
    static let chartColors = [
        primaryPurple,
        primaryGreen,
        primaryBlue,
        Color(red: 0.929, green: 0.341, blue: 0.341), // #ED5757
        Color(red: 1.0, green: 0.733, blue: 0.2), // #FFBB33
        Color(red: 0.529, green: 0.325, blue: 0.812), // #8752CF
        Color(red: 0.996, green: 0.365, blue: 0.612), // #FE5D9C
        Color(red: 0.133, green: 0.706, blue: 0.886) // #22B4E2
    ]
}

// MARK: - Color Modifiers
extension View {
    func primaryGradientBackground() -> some View {
        self.background(Color.gradientPrimary)
    }

    func cardStyle() -> some View {
        self
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .shadow(color: Color.shadowLight, radius: 4, x: 0, y: 2)
    }

    func halalBadgeStyle() -> some View {
        self
            .background(Color.halalBackground)
            .foregroundColor(Color.halalGreen)
            .cornerRadius(6)
    }
}