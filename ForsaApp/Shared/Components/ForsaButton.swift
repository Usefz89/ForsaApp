//
//  ForsaButton.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct ForsaButton: View {
    let title: String
    let style: ForsaButtonStyle
    let size: ForsaButtonSize
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool

    init(_ title: String, style: ForsaButtonStyle = .primary, size: ForsaButtonSize = .medium, isDisabled: Bool = false, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.size = size
        self.action = action
        self.isDisabled = isDisabled
        self.isLoading = isLoading
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(style.textColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(style.backgroundColor)
            .cornerRadius(size.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

enum ForsaButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case outline
    case ghost

    var backgroundColor: Color {
        switch self {
        case .primary:
            return .primaryPurple
        case .secondary:
            return .primaryGreen
        case .tertiary:
            return .backgroundSecondary
        case .destructive:
            return .errorRed
        case .outline:
            return .clear
        case .ghost:
            return .clear
        }
    }

    var textColor: Color {
        switch self {
        case .primary, .secondary, .destructive:
            return .white
        case .tertiary:
            return .textPrimary
        case .outline:
            return .primaryPurple
        case .ghost:
            return .textSecondary
        }
    }

    var borderColor: Color {
        switch self {
        case .primary, .secondary, .tertiary, .destructive, .ghost:
            return .clear
        case .outline:
            return .primaryPurple
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .outline:
            return 1.5
        default:
            return 0
        }
    }
}

enum ForsaButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }

    var font: Font {
        switch self {
        case .small: return .buttonSmall
        case .medium: return .buttonMedium
        case .large: return .buttonLarge
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
}

// MARK: - Icon Button
struct ForsaIconButton: View {
    let icon: String
    let style: ForsaButtonStyle
    let size: ForsaButtonSize
    let action: () -> Void
    let isDisabled: Bool

    init(icon: String, style: ForsaButtonStyle = .primary, size: ForsaButtonSize = .medium, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(style.textColor)
                .frame(width: size.height, height: size.height)
                .background(style.backgroundColor)
                .cornerRadius(size.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        ForsaButton("Primary Button", style: .primary) { }
        ForsaButton("Secondary Button", style: .secondary) { }
        ForsaButton("Outline Button", style: .outline) { }
        ForsaButton("Disabled Button", style: .primary, isDisabled: true) { }
        ForsaButton("Loading Button", style: .primary, isLoading: true) { }

        HStack(spacing: 12) {
            ForsaIconButton(icon: "heart.fill", style: .primary) { }
            ForsaIconButton(icon: "bookmark.fill", style: .secondary) { }
            ForsaIconButton(icon: "share", style: .outline) { }
        }
    }
    .padding()
}