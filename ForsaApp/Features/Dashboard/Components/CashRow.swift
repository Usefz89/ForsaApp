//
//  CashRow.swift
//  ForsaApp
//
//  Trading 212-style cash display row with deposit button
//

import SwiftUI

struct CashRow: View {
    let cashAmount: String
    var onDepositTapped: (() -> Void)? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CASH")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)

                Text(cashAmount)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            if let onDeposit = onDepositTapped {
                Button(action: onDeposit) {
                    Text("Deposit")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.primaryPurple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .shadow(color: Color.shadowLight, radius: 4, x: 0, y: 2)
        .padding(.horizontal, DashboardConstants.horizontalPadding)
    }
}

#Preview {
    VStack(spacing: 20) {
        CashRow(cashAmount: "$100.00") {
            print("Deposit tapped")
        }

        CashRow(cashAmount: "$1,250.50") {
            print("Deposit tapped")
        }

        CashRow(cashAmount: "$0.00")
    }
    .padding(.vertical)
    .background(Color.backgroundPrimary)
}
