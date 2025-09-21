//
//  HalalBadge.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct HalalBadge: View {
    let compliance: ShariaCompliance
    let size: BadgeSize

    init(_ compliance: ShariaCompliance, size: BadgeSize = .medium) {
        self.compliance = compliance
        self.size = size
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: compliance.iconName)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(compliance.color)

            Text(compliance.displayText)
                .font(size.font)
                .fontWeight(.medium)
                .foregroundColor(compliance.color)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(compliance.backgroundColor)
        .cornerRadius(size.cornerRadius)
    }
}

enum BadgeSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption1
        case .large: return .footnote
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
}

extension ShariaCompliance {
    var displayText: String {
        switch self {
        case .compliant: return "Halal"
        case .nonCompliant: return "Non-Halal"
        case .underReview: return "Under Review"
        }
    }

    var iconName: String {
        switch self {
        case .compliant: return "checkmark.shield.fill"
        case .nonCompliant: return "xmark.shield.fill"
        case .underReview: return "clock.badge.exclamationmark.fill"
        }
    }

    var color: Color {
        switch self {
        case .compliant: return .halalGreen
        case .nonCompliant: return .nonHalalRed
        case .underReview: return .underReviewOrange
        }
    }

    var backgroundColor: Color {
        switch self {
        case .compliant: return .halalBackground
        case .nonCompliant: return Color.nonHalalRed.opacity(0.1)
        case .underReview: return Color.underReviewOrange.opacity(0.1)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            HalalBadge(.compliant, size: .small)
            HalalBadge(.compliant, size: .medium)
            HalalBadge(.compliant, size: .large)
        }

        HStack(spacing: 12) {
            HalalBadge(.nonCompliant, size: .small)
            HalalBadge(.nonCompliant, size: .medium)
            HalalBadge(.nonCompliant, size: .large)
        }

        HStack(spacing: 12) {
            HalalBadge(.underReview, size: .small)
            HalalBadge(.underReview, size: .medium)
            HalalBadge(.underReview, size: .large)
        }
    }
    .padding()
}