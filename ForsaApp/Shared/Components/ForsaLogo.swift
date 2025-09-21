//
//  ForsaLogo.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct ForsaLogo: View {
    let size: LogoSize
    let style: LogoStyle

    init(size: LogoSize = .medium, style: LogoStyle = .full) {
        self.size = size
        self.style = style
    }

    var body: some View {
        Group {
            switch style {
            case .full:
                fullLogo
            case .iconOnly:
                logoIcon
            case .textOnly:
                logoText
            }
        }
    }

    private var fullLogo: some View {
        HStack(spacing: size.spacing) {
            logoIcon
            logoText
        }
    }

    private var logoIcon: some View {
        ZStack {
            // Background gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.primaryPurple, .primaryPurpleDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.iconSize, height: size.iconSize)

            // Inner circle with opacity
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: size.iconSize * 0.75, height: size.iconSize * 0.75)

            // Center icon - represents growth/investment
            VStack(spacing: 2) {
                // Arrow pointing up (growth)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: size.iconSize * 0.3, weight: .bold))
                    .foregroundColor(.white)

                // Small dots representing diversification
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: size.iconSize * 0.08, height: size.iconSize * 0.08)
                    }
                }
            }
        }
    }

    private var logoText: some View {
        VStack(alignment: .leading, spacing: size.textSpacing) {
            Text("Forsa")
                .font(.system(size: size.titleSize, weight: .bold, design: .default))
                .foregroundColor(.textPrimary)

            if size != .small {
                Text("Sharia-Compliant Investing")
                    .font(.system(size: size.subtitleSize, weight: .medium, design: .default))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

enum LogoSize {
    case small
    case medium
    case large
    case xlarge

    var iconSize: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 48
        case .large: return 64
        case .xlarge: return 80
        }
    }

    var titleSize: CGFloat {
        switch self {
        case .small: return 18
        case .medium: return 24
        case .large: return 32
        case .xlarge: return 40
        }
    }

    var subtitleSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        case .xlarge: return 16
        }
    }

    var spacing: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .xlarge: return 20
        }
    }

    var textSpacing: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        case .xlarge: return 8
        }
    }
}

enum LogoStyle {
    case full
    case iconOnly
    case textOnly
}

// MARK: - App Icon Component
struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.primaryPurple, .primaryPurpleDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            // App icon content
            VStack(spacing: 8) {
                // Main symbol - upward trending chart with Islamic star
                ZStack {
                    // Chart bars
                    HStack(alignment: .bottom, spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 6, height: 16)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 6, height: 24)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 6, height: 32)
                    }

                    // Star overlay (representing Islamic values)
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primaryGreen)
                        .offset(x: 12, y: -8)
                }

                // App name
                Text("Forsa")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        ForsaLogo(size: .small, style: .full)
        ForsaLogo(size: .medium, style: .full)
        ForsaLogo(size: .large, style: .iconOnly)
        ForsaLogo(size: .xlarge, style: .textOnly)

        AppIconView()
    }
    .padding()
}