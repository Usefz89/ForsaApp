//
//  AccountValueHeader.swift
//  ForsaApp
//
//  Trading 212-style clean account value header
//

import SwiftUI

struct AccountValueHeader: View {
    let accountValue: String
    let lastYearGain: String
    let rateOfReturn: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCOUNT VALUE")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            Text(accountValue)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .contentTransition(.numericText())

            HStack(spacing: 24) {
                // Last Year Gain
                HStack(spacing: 4) {
                    Text("LAST YEAR")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)

                    HStack(spacing: 2) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .fontWeight(.bold)
                        Text(lastYearGain)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(isPositive ? .gainGreen : .lossRed)
                }

                // Rate of Return
                HStack(spacing: 4) {
                    Text("RATE OF RETURN")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)

                    HStack(spacing: 2) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .fontWeight(.bold)
                        Text(rateOfReturn)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(isPositive ? .gainGreen : .lossRed)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DashboardConstants.horizontalPadding)
    }
}

#Preview {
    VStack {
        AccountValueHeader(
            accountValue: "$4,160.03",
            lastYearGain: "$520.91",
            rateOfReturn: "14.9%",
            isPositive: true
        )

        AccountValueHeader(
            accountValue: "$3,500.00",
            lastYearGain: "$120.50",
            rateOfReturn: "-3.2%",
            isPositive: false
        )
    }
    .padding(.vertical)
    .background(Color.backgroundPrimary)
}
