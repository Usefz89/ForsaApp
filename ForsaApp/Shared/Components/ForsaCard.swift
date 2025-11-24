//
//  ForsaCard.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct ForsaCard<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let shadowStyle: ShadowStyle

    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 12,
        shadowStyle: ShadowStyle = .light,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.backgroundCard)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.x,
                y: shadowStyle.y
            )
    }
}

enum ShadowStyle {
    case none
    case light
    case medium
    case heavy

    var color: Color {
        switch self {
        case .none: return .clear
        case .light: return .shadowLight
        case .medium: return .shadowMedium
        case .heavy: return .shadowHeavy
        }
    }

    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .light: return 4
        case .medium: return 8
        case .heavy: return 12
        }
    }

    var x: CGFloat { 0 }

    var y: CGFloat {
        switch self {
        case .none: return 0
        case .light: return 2
        case .medium: return 4
        case .heavy: return 6
        }
    }
}

// MARK: - Specialized Cards

struct PortfolioCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String?

    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.callout)
                            .foregroundColor(.textSecondary)

                        Text(value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.primaryPurple)
                    }
                }

                Text(change)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? .gainGreen : .lossRed)
            }
        }
    }
}

struct StockCard: View {
    let stock: Stock
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ForsaCard(padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)) {
                HStack(spacing: 12) {
                    // Stock logo placeholder
                    Circle()
                        .fill(Color.primaryPurple.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(stock.symbol.prefix(2)))
                                .font(.caption1)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryPurple)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(stock.symbol)
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)

                            if stock.shariaCompliance == .compliant {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.caption1)
                                    .foregroundColor(.halalGreen)
                            }
                        }

                        Text(stock.name)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(stock.formattedPrice)")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)

                        Text(stock.formattedChangePercentage)
                            .font(.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(stock.isPositive ? .gainGreen : .lossRed)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            PortfolioCard(
                title: "Total Portfolio",
                value: "$25,420.50",
                change: "+$2,840.30 (12.6%)",
                isPositive: true,
                icon: "chart.line.uptrend.xyaxis"
            )

            StockCard(
                stock: Stock(
                    symbol: "AAPL",
                    name: "Apple Inc.",
                    market: .nasdaq,
                    assetType: .stock,
                    currentPrice: 175.43,
                    previousClose: 172.80,
                    volume: 45_000_000,
                    shariaCompliance: .compliant
                )
            ) { }
        }
        .padding()
    }
}