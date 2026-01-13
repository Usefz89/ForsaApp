//
//  WalletComponents.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

// MARK: - Account Stat Row (Clean Design)

struct AccountStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var showChevron: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.12))
                    .cornerRadius(8)

                Text(title)
                    .font(.callout)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text(value)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.backgroundCard)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Pending Transactions Banner (Compact)

struct PendingTransactionsBanner: View {
    let count: Int
    let totalAmount: String
    let expectedDate: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.warningYellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) Pending Deposit\(count > 1 ? "s" : "")")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    Text("Processing • Expected \(expectedDate)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Text(totalAmount)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.warningYellow)
            }
            .padding(16)
            .background(Color.warningYellow.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) pending deposits totaling \(totalAmount)")
    }
}

// MARK: - Clean Transaction Row

struct CleanTransactionRow: View {
    let transaction: DepositTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.paymentMethod.iconName)
                .font(.callout)
                .foregroundColor(.primaryGreen)
                .frame(width: 32, height: 32)
                .background(Color.primaryGreen.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.paymentMethod.displayName)
                    .font(.callout)
                    .foregroundColor(.textPrimary)

                Text(transaction.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(transaction.formattedAmount)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.gainGreen)

                if transaction.status != .completed {
                    Text(transaction.status.displayName)
                        .font(.caption2)
                        .foregroundColor(.warningYellow)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Deposit of \(transaction.formattedAmount) via \(transaction.paymentMethod.displayName)")
    }
}

// MARK: - Account Overview Row (Legacy - kept for compatibility)

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
                .frame(width: WalletConstants.transactionIconSize)

            Text(title)
                .font(.callout)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.calloutMedium)
                .foregroundColor(.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
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
                    .frame(width: WalletConstants.pendingIconSize)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(String(localized: "Pending Deposit"))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pending deposit of \(transaction.formattedAmount), expected in \(transaction.estimatedSettlementTime)")
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
                .frame(width: WalletConstants.transactionIconSize)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.paymentMethod.displayName) transaction of \(transaction.formattedAmount)")
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
                    .frame(width: WalletConstants.pendingIconSize)

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
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Transaction History View

struct TransactionHistoryView: View {
    let transactions: [DepositTransaction]
    
    var body: some View {
        Group {
            if transactions.isEmpty {
                emptyStateView
            } else {
                transactionList
            }
        }
        .navigationTitle(WalletStrings.transactionHistoryTitle)
        .navigationBarTitleDisplayMode(.large)
        .background(Color.backgroundPrimary)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)
            
            Text(String(localized: "No Transactions Yet"))
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text(String(localized: "Your transaction history will appear here once you make your first deposit or withdrawal."))
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No transactions yet")
    }
    
    private var transactionList: some View {
        List {
            ForEach(transactions) { transaction in
                CashTransactionRowView(transaction: transaction)
                    .listRowBackground(Color.backgroundCard)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Info Row (for Deposit/Withdraw flows)

struct WalletInfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    
    init(label: String, value: String, valueColor: Color = .textPrimary) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Quick Amount Button

struct QuickAmountButton: View {
    let amount: Int
    let currency: String
    let conversionValue: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(currency) \(amount)")
                    .font(.callout)
                    .fontWeight(.medium)
                
                if let conversion = conversionValue {
                    Text(conversion)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            .foregroundColor(isSelected ? .white : .primaryPurple)
            .frame(maxWidth: .infinity)
            .frame(height: WalletConstants.quickSelectButtonHeight)
            .background(isSelected ? Color.primaryPurple : Color.primaryPurple.opacity(0.1))
            .cornerRadius(8)
        }
        .accessibilityLabel("\(currency) \(amount)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Info Card

struct WalletInfoCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let rows: [(label: String, value: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows, id: \.label) { row in
                    WalletInfoRow(label: row.label, value: row.value)
                }
            }
        }
        .padding(WalletConstants.infoCardPadding)
        .background(iconColor.opacity(0.1))
        .cornerRadius(WalletConstants.infoCardCornerRadius)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Conversion Display

struct CurrencyConversionDisplay: View {
    let fromAmount: Double
    let toAmount: Double
    let exchangeRate: Double
    let fromCurrency: String
    let toCurrency: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text("Exchange Rate: 1 \(fromCurrency) = $\(String(format: "%.2f", exchangeRate)) \(toCurrency)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            HStack {
                Text(String(localized: "You will deposit:"))
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                Text("$\(String(format: "%.2f", toAmount)) \(toCurrency)")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.successGreen)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.successGreen.opacity(0.1))
            .cornerRadius(10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Converting \(fromCurrency) \(String(format: "%.2f", fromAmount)) to \(toCurrency) \(String(format: "%.2f", toAmount))")
    }
}

// MARK: - Success Header

struct WalletSuccessHeader: View {
    let isFullySuccessful: Bool
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isFullySuccessful ? Color.successGreen.opacity(0.2) : Color.warningYellow.opacity(0.2))
                    .frame(width: WalletConstants.successIconSize, height: WalletConstants.successIconSize)
                
                Image(systemName: isFullySuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: WalletConstants.successIconInnerSize))
                    .foregroundColor(isFullySuccessful ? .successGreen : .warningYellow)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text(subtitle)
                .font(.title3)
                .foregroundColor(.primaryPurple)
        }
        .padding(.top, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}
