//
//  TreemapTile.swift
//  ForsaApp
//
//  Trading 212-style treemap tile for asset allocation visualization
//

import SwiftUI

// MARK: - Treemap Tile

// MARK: - Treemap Tile

struct TreemapTile: View {
    let symbol: String
    let allocationPercentage: Double
    let changePercentage: Double
    let marketValue: Double

    private var isPositive: Bool {
        changePercentage >= 0
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isSmall = size.width < 70 || size.height < 70
            
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: isSmall ? 6 : 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                isPositive ? Color.gainGreen.opacity(0.25) : Color.lossRed.opacity(0.25),
                                isPositive ? Color.gainGreen.opacity(0.1) : Color.lossRed.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: isSmall ? 6 : 12)
                    .strokeBorder(
                        isPositive ? Color.gainGreen.opacity(0.3) : Color.lossRed.opacity(0.3),
                        lineWidth: 1
                    )

                // Content Layer
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Top Section: Icon or Symbol
                    if !isSmall {
                        Circle()
                            .fill(Color.primaryPurple.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text(String(symbol.prefix(1)))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.primaryPurple)
                            )
                            .padding(.bottom, 2)
                    }

                    Spacer(minLength: 0)
                    
                    // Bottom Section: Symbol + Stats
                    // Always show this block regardless of size
                    VStack(alignment: .leading, spacing: isSmall ? 0 : 2) {
                        Text(symbol)
                            .font(.system(size: isSmall ? 10 : 12, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(String(format: "%.1f%%", allocationPercentage))
                            .font(.system(size: isSmall ? 8 : 10))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        // Gain/Loss
                        HStack(spacing: 1) {
                            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: isSmall ? 5 : 7, weight: .bold))
                            Text(String(format: "%+.1f%%", changePercentage))
                                .font(.system(size: isSmall ? 7 : 9))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isPositive ? .gainGreen : .lossRed)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                }
                .padding(isSmall ? 4 : 8)
            }
        }
    }
}

// Helper for centering in tiny mode
struct Center<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                content
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            TreemapTile(
                symbol: "AAPL",
                allocationPercentage: 25.5,
                changePercentage: 3.45,
                marketValue: 2500
            )
            .frame(width: 120, height: 120)

            TreemapTile(
                symbol: "MSFT",
                allocationPercentage: 18.2,
                changePercentage: -1.23,
                marketValue: 1820
            )
            .frame(width: 120, height: 120)
        }

        HStack(spacing: 12) {
            TreemapTile(
                symbol: "GOOGL",
                allocationPercentage: 15.0,
                changePercentage: 0.85,
                marketValue: 1500
            )
            .frame(width: 100, height: 100)

            TreemapTile(
                symbol: "AMZN",
                allocationPercentage: 12.3,
                changePercentage: -2.15,
                marketValue: 1230
            )
            .frame(width: 100, height: 100)
        }
    }
    .padding()
    .background(Color.backgroundSecondary)
}
