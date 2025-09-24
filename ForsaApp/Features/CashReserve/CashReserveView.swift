//
//  CashReserveView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct CashReserveView: View {
    @StateObject private var viewModel = CashReserveViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Cash Balance Header
                    cashBalanceHeader

                    // Action Buttons
                    actionButtons

                    // Account Overview
                    accountOverview

                    // Pending Transactions
                    if !viewModel.pendingTransactions.isEmpty {
                        pendingTransactionsSection
                    }

                    // Recent Transactions
                    if viewModel.hasTransactions {
                        recentTransactionsSection
                    }

                    // Quick Transfer to Pies
                    quickTransferSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Cash Reserve")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $viewModel.showingDepositFlow) {
                DepositFlowView()
            }
            .sheet(isPresented: $viewModel.showingWithdrawFlow) {
                WithdrawFlowView()
            }
            .sheet(isPresented: $viewModel.showingTransferToPieFlow) {
                TransferToPieView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var cashBalanceHeader: some View {
        ForsaCard {
            VStack(spacing: 20) {
                // Main Balance
                VStack(spacing: 8) {
                    Text("Available Cash")
                        .font(.callout)
                        .foregroundColor(.textSecondary)

                    Text(viewModel.cashAccount.formattedBalance)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryPurple)

                    if viewModel.pendingAmount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(.warningYellow)

                            Text("\(viewModel.formattedPendingAmount) pending")
                                .font(.caption1)
                                .foregroundColor(.warningYellow)
                        }
                    }
                }

                // Account Status
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.callout)
                            .foregroundColor(.halalGreen)

                        Text("Account Verified")
                            .font(.callout)
                            .foregroundColor(.halalGreen)

                        Spacer()

                        Text(viewModel.cashAccount.verificationLevel.displayName)
                            .font(.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryPurple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primaryPurple.opacity(0.1))
                            .cornerRadius(4)
                    }

                    // Limits
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Limit")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)

                            Text("KWD \(String(format: "%.0f", viewModel.cashAccount.availableDailyLimit))")
                                .font(.caption1)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Monthly Limit")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)

                            Text("KWD \(String(format: "%.0f", viewModel.cashAccount.availableMonthlyLimit))")
                                .font(.caption1)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            ForsaButton("Deposit Funds", style: .primary, size: .large) {
                viewModel.showDepositFlow()
            }

            ForsaButton("Withdraw", style: .outline, size: .large) {
                viewModel.showWithdrawFlow()
            }
        }
    }

    private var accountOverview: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Account Overview")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 12) {
                    AccountOverviewRow(
                        title: "Total Deposited",
                        value: "KWD \(String(format: "%.2f", viewModel.cashAccount.totalDeposited))",
                        icon: "arrow.down.circle.fill",
                        color: .primaryGreen
                    )

                    AccountOverviewRow(
                        title: "Total Withdrawn",
                        value: "KWD \(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))",
                        icon: "arrow.up.circle.fill",
                        color: .primaryBlue
                    )

                    if viewModel.availableBalance != viewModel.cashAccount.balance {
                        AccountOverviewRow(
                            title: "Available Balance",
                            value: viewModel.formattedAvailableBalance,
                            icon: "dollarsign.circle.fill",
                            color: .primaryPurple
                        )
                    }
                }
            }
        }
    }

    private var pendingTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Transactions")
                .font(.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: 12) {
                ForEach(viewModel.pendingTransactions) { transaction in
                    PendingTransactionCard(transaction: transaction)
                }
            }
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink("View All") {
                    TransactionHistoryView(transactions: viewModel.allTransactions)
                }
                .font(.callout)
                .foregroundColor(.primaryPurple)
            }

            VStack(spacing: 12) {
                ForEach(viewModel.recentTransactions) { transaction in
                    CashTransactionRowView(transaction: transaction)
                }
            }
        }
    }

    private var quickTransferSection: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()
                }

                VStack(spacing: 12) {
                    QuickActionButton(
                        title: "Transfer to Pie",
                        subtitle: "Invest cash in existing pies",
                        icon: "arrow.right.circle.fill",
                        color: .primaryPurple
                    ) {
                        viewModel.showTransferToPieFlow()
                    }

                    QuickActionButton(
                        title: "Create New Pie",
                        subtitle: "Start a new investment pie",
                        icon: "plus.circle.fill",
                        color: .primaryGreen
                    ) {
                        // Navigate to pie creation
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

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

// MARK: - Placeholder Views (to be implemented)

struct WithdrawFlowView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Withdraw Flow")
                Text("Coming Soon")
            }
            .navigationTitle("Withdraw Funds")
        }
    }
}

struct TransferToPieView: View {
    @ObservedObject var viewModel: CashReserveViewModel

    var body: some View {
        NavigationView {
            VStack {
                Text("Transfer to Pie")
                Text("Coming Soon")
            }
            .navigationTitle("Transfer to Pie")
        }
    }
}

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

// MARK: - Preview
#Preview {
    CashReserveView()
}