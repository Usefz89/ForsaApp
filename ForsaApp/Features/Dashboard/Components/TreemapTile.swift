//
//  TreemapTile.swift
//  ForsaApp
//
//  Trading 212-style treemap tile for asset allocation visualization
//

import SwiftUI

struct TreemapTile: View {
    let symbol: String
    let allocationPercentage: Double
    let changePercentage: Double
    let marketValue: Double

    private var isPositive: Bool {
        changePercentage >= 0
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background with gradient based on gain/loss
            RoundedRectangle(cornerRadius: 12)
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

            // Border for definition
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isPositive ? Color.gainGreen.opacity(0.3) : Color.lossRed.opacity(0.3),
                    lineWidth: 1
                )

            VStack(alignment: .leading, spacing: 6) {
                // Symbol Badge (logo placeholder)
                Circle()
                    .fill(Color.primaryPurple.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(symbol.prefix(1)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryPurple)
                    )

                Spacer()

                // Bottom Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(symbol)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text(String(format: "%.1f%%", allocationPercentage))
                        .font(.caption2)
                        .foregroundColor(.textSecondary)

                    // Gain/Loss
                    HStack(spacing: 2) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text(String(format: "%+.2f%%", changePercentage))
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(isPositive ? .gainGreen : .lossRed)
                }
            }
            .padding(10)
        }
        .frame(minWidth: 80, minHeight: 80)
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
