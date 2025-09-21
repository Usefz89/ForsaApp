//
//  Typography.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

extension Font {
    // MARK: - Headlines
    static let largeTitle = Font.system(size: 32, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 24, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let headline = Font.system(size: 18, weight: .semibold, design: .default)
    static let subheadline = Font.system(size: 16, weight: .medium, design: .default)

    // MARK: - Body Text
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let bodySemibold = Font.system(size: 16, weight: .semibold, design: .default)
    static let callout = Font.system(size: 15, weight: .regular, design: .default)
    static let calloutMedium = Font.system(size: 15, weight: .medium, design: .default)

    // MARK: - Small Text
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let footnoteMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption1Medium = Font.system(size: 12, weight: .medium, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Numbers & Currency
    static let priceXLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
    static let priceLarge = Font.system(size: 24, weight: .bold, design: .monospaced)
    static let priceMedium = Font.system(size: 18, weight: .semibold, design: .monospaced)
    static let priceSmall = Font.system(size: 16, weight: .medium, design: .monospaced)
    static let percentage = Font.system(size: 14, weight: .medium, design: .monospaced)

    // MARK: - Button Text
    static let buttonLarge = Font.system(size: 18, weight: .semibold, design: .default)
    static let buttonMedium = Font.system(size: 16, weight: .semibold, design: .default)
    static let buttonSmall = Font.system(size: 14, weight: .medium, design: .default)

    // MARK: - Navigation & Tab Bar
    static let navigationTitle = Font.system(size: 18, weight: .semibold, design: .default)
    static let tabBarItem = Font.system(size: 10, weight: .medium, design: .default)

    // MARK: - Input Fields
    static let inputText = Font.system(size: 16, weight: .regular, design: .default)
    static let inputLabel = Font.system(size: 14, weight: .medium, design: .default)
    static let inputPlaceholder = Font.system(size: 16, weight: .regular, design: .default)
}

// MARK: - Text Style Modifiers
extension Text {
    func primaryTitle() -> some View {
        self
            .font(.title1)
            .foregroundColor(.textPrimary)
            .fontWeight(.bold)
    }

    func secondaryTitle() -> some View {
        self
            .font(.title2)
            .foregroundColor(.textPrimary)
            .fontWeight(.semibold)
    }

    func sectionHeader() -> some View {
        self
            .font(.headline)
            .foregroundColor(.textPrimary)
            .fontWeight(.semibold)
    }

    func bodyText() -> some View {
        self
            .font(.body)
            .foregroundColor(.textSecondary)
    }

    func secondaryText() -> some View {
        self
            .font(.callout)
            .foregroundColor(.textTertiary)
    }

    func captionText() -> some View {
        self
            .font(.caption1)
            .foregroundColor(.textMuted)
    }

    func priceText(size: PriceSize = .medium) -> some View {
        self
            .font(size.font)
            .foregroundColor(.textPrimary)
            .fontWeight(.semibold)
    }

    func gainLossText(isPositive: Bool) -> some View {
        self
            .font(.percentage)
            .foregroundColor(isPositive ? .gainGreen : .lossRed)
            .fontWeight(.medium)
    }

    func halalBadgeText() -> some View {
        self
            .font(.caption1Medium)
            .foregroundColor(.halalGreen)
            .fontWeight(.medium)
    }

    func buttonText(style: ButtonStyle = .primary) -> some View {
        self
            .font(.buttonMedium)
            .foregroundColor(style.textColor)
            .fontWeight(.semibold)
    }
}

enum PriceSize {
    case small
    case medium
    case large
    case xlarge

    var font: Font {
        switch self {
        case .small: return .priceSmall
        case .medium: return .priceMedium
        case .large: return .priceLarge
        case .xlarge: return .priceXLarge
        }
    }
}

enum ButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive

    var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .primaryPurple
        case .tertiary: return .textSecondary
        case .destructive: return .white
        }
    }
}

// MARK: - Line Heights and Spacing
struct TextSpacing {
    static let lineSpacingSmall: CGFloat = 2
    static let lineSpacingMedium: CGFloat = 4
    static let lineSpacingLarge: CGFloat = 6

    static let letterSpacingTight: CGFloat = -0.5
    static let letterSpacingNormal: CGFloat = 0
    static let letterSpacingWide: CGFloat = 0.5
}

// MARK: - Text Field Styles
struct ForsaTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.inputText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.backgroundSecondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
}