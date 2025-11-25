//
//  WalletComponents.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

// MARK: - Account Overview Row

struct AccountOverviewRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.callout)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.calloutMedium)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Pending Transaction Card

struct PendingTransactionCard: View {
    let transaction: DepositTransaction

    var body: some View {
        ForsaCard(shadowStyle: .light) {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.warningYellow)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Pending Deposit")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Text(transaction.formattedAmount)
                            .font(.calloutMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryPurple)
                    }

                    HStack {
                        Text(transaction.paymentMethod.displayName)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text("Expected: \(transaction.estimatedSettlementTime)")
                            .font(.caption1)
                            .foregroundColor(.warningYellow)
                    }
                }
            }
        }
    }
}

// MARK: - Cash Transaction Row View

struct CashTransactionRowView: View {
    let transaction: DepositTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.paymentMethod.iconName)
                .font(.callout)
                .foregroundColor(.primaryPurple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.paymentMethod.displayName)
                    .font(.callout)
                    .foregroundColor(.textPrimary)

                Text(transaction.createdAt, style: .date)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.formattedAmount)
                    .font(.calloutMedium)
                    .foregroundColor(.halalGreen)

                if transaction.processingFee > 0 {
                    Text("Fee: \(transaction.formattedFee)")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Transaction History View

struct TransactionHistoryView: View {
    let transactions: [DepositTransaction]

    var body: some View {
        List(transactions) { transaction in
            CashTransactionRowView(transaction: transaction)
        }
        .navigationTitle("Transaction History")
        .navigationBarTitleDisplayMode(.large)
    }
}

