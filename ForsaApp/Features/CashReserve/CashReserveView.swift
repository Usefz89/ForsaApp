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
            .sheet(isPresented: $viewModel.showingWithdrawFlow) {
                WithdrawFlowView()
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

                            Text("$\(String(format: "%.0f", viewModel.cashAccount.availableDailyLimit))")
                                .font(.caption1)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Monthly Limit")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)

                            Text("$\(String(format: "%.0f", viewModel.cashAccount.availableMonthlyLimit))")
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
                        value: "$\(String(format: "%.2f", viewModel.cashAccount.totalDeposited))",
                        icon: "arrow.down.circle.fill",
                        color: .primaryGreen
                    )

                    AccountOverviewRow(
                        title: "Total Withdrawn",
                        value: "$\(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))",
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
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Amount Input
                    VStack(spacing: 12) {
                        Text("Enter Amount to Withdraw")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            Text("$")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primaryPurple)
                            
                            TextField("0.00", text: $amount)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primaryPurple)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.backgroundCard)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Withdraw Button
                    ForsaButton(
                        "Withdraw Funds",
                        style: .primary,
                        size: .large,
                        isDisabled: !isValidAmount,
                        isLoading: isProcessing
                    ) {
                        Task {
                            await processWithdrawal()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Withdraw Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your withdrawal of $\(amount) has been initiated.")
            }
        }
    }
    
    private var isValidAmount: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        return true
    }
    
    private func processWithdrawal() async {
        guard let amountValue = Double(amount) else { return }
        
        isProcessing = true
        
        do {
            guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No account found"])
            }
            
            try await AlpacaTradingService.shared.withdrawFunds(accountId: accountId, amount: amountValue)
            showSuccess = true
        } catch {
            errorMessage = "Withdrawal failed: \(error.localizedDescription)"
            showError = true
        }
        
        isProcessing = false
    }
}

struct DepositFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Amount Input
                    VStack(spacing: 12) {
                        Text("Enter Amount to Deposit")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            Text("$")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primaryPurple)
                            
                            TextField("0.00", text: $amount)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primaryPurple)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.backgroundCard)
                        .cornerRadius(12)
                        
                        Text("Funds will be available immediately in sandbox")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    // Quick Amount Buttons
                    VStack(spacing: 12) {
                        Text("Quick Select")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                        
                        HStack(spacing: 12) {
                            ForEach([100, 500, 1000, 5000], id: \.self) { value in
                                Button {
                                    amount = "\(value)"
                                } label: {
                                    Text("$\(value)")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primaryPurple)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.primaryPurple.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Deposit Button
                    ForsaButton(
                        "Deposit Funds",
                        style: .primary,
                        size: .large,
                        isDisabled: !isValidAmount,
                        isLoading: isProcessing
                    ) {
                        Task {
                            await processDeposit()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Deposit Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your deposit of $\(amount) has been initiated successfully!")
            }
        }
    }
    
    private var isValidAmount: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        return true
    }
    
    private func processDeposit() async {
        guard let amountValue = Double(amount) else { return }
        
        isProcessing = true
        
        do {
            guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No account found. Please sign up first."])
            }
            
            try await AlpacaTradingService.shared.fundAccount(accountId: accountId, amount: amountValue)
            showSuccess = true
        } catch {
            errorMessage = "Deposit failed: \(error.localizedDescription)"
            showError = true
        }
        
        isProcessing = false
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