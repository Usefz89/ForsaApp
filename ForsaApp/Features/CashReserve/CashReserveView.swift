//
//  CashReserveView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct CashReserveView: View {
    @EnvironmentObject var coordinator: AppCoordinator
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
            .sheet(isPresented: $viewModel.showingDepositFlow, onDismiss: {
                // Refresh data after deposit sheet is closed
                viewModel.loadData()
            }) {
                DepositFlowView()
                    .environmentObject(coordinator)
            }
            .sheet(isPresented: $viewModel.showingWithdrawFlow, onDismiss: {
                // Refresh data after withdraw sheet is closed
                viewModel.loadData()
            }) {
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
                // Total Balance Section (like eToro)
                VStack(spacing: 16) {
                    // Available Balance
                    VStack(spacing: 4) {
                        Text("Available Balance")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Text(viewModel.cashAccount.formattedBalance)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryPurple)
                    }
                    
                    // Balance Breakdown
                    HStack(spacing: 0) {
                        // Buying Power
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.primaryBlue)
                                Text("Buying Power")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            Text("$\(String(format: "%.2f", viewModel.buyingPower))")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryBlue)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 40)
                        
                        // Total Deposited
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.successGreen)
                                Text("Deposited")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            Text("$\(String(format: "%.2f", viewModel.cashAccount.totalDeposited))")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.successGreen)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 40)
                        
                        // Total Withdrawn
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.warningYellow)
                                Text("Withdrawn")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            Text("$\(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.warningYellow)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)
                }

                // Pending Transfers Alert (if any)
                if viewModel.pendingAmount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.warningYellow)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Funds Processing")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            Text("\(viewModel.formattedPendingAmount) will be available within 1-2 business days")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.warningYellow.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Account Status
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
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var amountKWD: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var autoInvestEnabled = true // Default to auto-invest
    @State private var isInvesting = false
    @State private var investmentResult: PortfolioInvestmentResult?
    @State private var showInvestmentResult = false
    
    private let exchangeRate = AppConfig.Currency.kwdToUsdRate
    
    private var amountUSD: Double {
        guard let kwd = Double(amountKWD) else { return 0 }
        return kwd * exchangeRate
    }
    
    private var selectedPortfolioName: String {
        coordinator.selectedPortfolio?.title ?? "your portfolio"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Amount Input in KWD
                        VStack(spacing: 16) {
                            Text("Enter Amount in KWD")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack {
                                Text("KWD")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primaryPurple)
                                
                                TextField("0.000", text: $amountKWD)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.primaryPurple)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.backgroundCard)
                            .cornerRadius(12)
                            
                            // Conversion Display
                            if let _ = Double(amountKWD), amountUSD > 0 {
                                VStack(spacing: 8) {
                                    // Exchange Rate
                                    HStack {
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                        Text("Exchange Rate: 1 KWD = $\(String(format: "%.2f", exchangeRate)) USD")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    
                                    // Converted Amount
                                    HStack {
                                        Text("You will deposit:")
                                            .font(.callout)
                                            .foregroundColor(.textSecondary)
                                        Text("$\(String(format: "%.2f", amountUSD)) USD")
                                            .font(.callout)
                                            .fontWeight(.bold)
                                            .foregroundColor(.successGreen)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.successGreen.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                        
                        // Quick Amount Buttons (in KWD)
                        VStack(spacing: 12) {
                            Text("Quick Select (KWD)")
                                .font(.callout)
                                .foregroundColor(.textSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach([50, 100, 250, 500], id: \.self) { value in
                                    Button {
                                        amountKWD = "\(value)"
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text("KWD \(value)")
                                                .font(.callout)
                                                .fontWeight(.medium)
                                            Text("≈ $\(Int(Double(value) * exchangeRate))")
                                                .font(.caption2)
                                                .foregroundColor(.textSecondary)
                                        }
                                        .foregroundColor(.primaryPurple)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.primaryPurple.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Auto-Invest Toggle (if portfolio selected)
                        if coordinator.selectedPortfolio != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $autoInvestEnabled) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "chart.pie.fill")
                                            .font(.title3)
                                            .foregroundColor(.primaryGreen)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Auto-Invest Funds")
                                                .font(.calloutMedium)
                                                .foregroundColor(.textPrimary)
                                            
                                            Text("Automatically invest in \(selectedPortfolioName)")
                                                .font(.caption)
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                }
                                .tint(.primaryGreen)
                                
                                if autoInvestEnabled, let portfolio = coordinator.selectedPortfolio {
                                    // Show portfolio allocation preview
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Investment Breakdown")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.textSecondary)
                                        
                                        ForEach(portfolio.allocations) { allocation in
                                            HStack {
                                                Circle()
                                                    .fill(allocationColor(for: allocation.assetClass))
                                                    .frame(width: 8, height: 8)
                                                
                                                Text(allocation.name)
                                                    .font(.caption)
                                                    .foregroundColor(.textPrimary)
                                                
                                                Spacer()
                                                
                                                Text("\(Int(allocation.percentage * 100))%")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primaryPurple)
                                                
                                                if amountUSD > 0 {
                                                    Text("($\(String(format: "%.0f", amountUSD * allocation.percentage)))")
                                                        .font(.caption2)
                                                        .foregroundColor(.textSecondary)
                                                }
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.backgroundSecondary)
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.backgroundCard)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.infoBlue)
                                Text("Deposit Information")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Processing Time", value: autoInvestEnabled ? "Instant (Sandbox)" : "1-2 Business Days")
                                InfoRow(label: "Minimum Deposit", value: "KWD 10 (~$32.50)")
                                InfoRow(label: "Fee", value: "Free")
                            }
                        }
                        .padding()
                        .background(Color.infoBlue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Fixed Bottom Button
                VStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        if amountUSD > 0 {
                            Text("Total: $\(String(format: "%.2f", amountUSD)) USD")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }
                        
                        ForsaButton(
                            autoInvestEnabled ? "Deposit & Invest" : "Deposit Funds",
                            style: .primary,
                            size: .large,
                            isDisabled: !isValidAmount,
                            isLoading: isProcessing || isInvesting
                        ) {
                            Task {
                                await processDeposit()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .background(
                        Color.backgroundPrimary
                            .shadow(color: .shadowLight, radius: 10, y: -5)
                    )
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
            .sheet(isPresented: $showInvestmentResult) {
                if let result = investmentResult {
                    InvestmentResultView(result: result, depositAmount: amountUSD) {
                        dismiss()
                    }
                }
            }
            .alert("Deposit Successful!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your deposit of KWD \(amountKWD) ($\(String(format: "%.2f", amountUSD)) USD) has been initiated!\n\nThe funds will be available within 1-2 business days.")
            }
        }
    }
    
    private var isValidAmount: Bool {
        guard let value = Double(amountKWD), value >= 10 else { return false }
        return true
    }
    
    private func allocationColor(for assetClass: AssetClass) -> Color {
        switch assetClass {
        case .equity: return .primaryBlue
        case .sukuk: return .primaryGreen
        case .gold: return .warningYellow
        case .reit: return .primaryPurple
        case .international: return .primaryOrange
        }
    }
    
    private func processDeposit() async {
        isProcessing = true
        
        do {
            guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No account found. Please sign up first."])
            }
            
            // Convert KWD to USD and deposit
            try await AlpacaTradingService.shared.fundAccount(accountId: accountId, amount: amountUSD)
            
            isProcessing = false
            
            // If auto-invest is enabled, proceed to invest
            if autoInvestEnabled && coordinator.selectedPortfolio != nil {
                isInvesting = true
                
                // Wait briefly for funds to settle in sandbox
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                if let result = try await coordinator.investInPortfolio(amount: amountUSD) {
                    investmentResult = result
                    showInvestmentResult = true
                }
                
                isInvesting = false
            } else {
                showSuccess = true
            }
        } catch {
            errorMessage = "Operation failed: \(error.localizedDescription)"
            showError = true
            isProcessing = false
            isInvesting = false
        }
    }
}

// MARK: - Investment Result View

struct InvestmentResultView: View {
    let result: PortfolioInvestmentResult
    let depositAmount: Double
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(result.isFullySuccessful ? Color.successGreen.opacity(0.2) : Color.warningYellow.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: result.isFullySuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(result.isFullySuccessful ? .successGreen : .warningYellow)
                        }
                        
                        Text(result.isFullySuccessful ? "Investment Complete!" : "Investment Partially Complete")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("$\(String(format: "%.2f", result.totalInvested)) invested")
                            .font(.title3)
                            .foregroundColor(.primaryPurple)
                    }
                    .padding(.top, 40)
                    
                    // Summary Card
                    ForsaCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Investment Summary")
                                    .font(.calloutMedium)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Deposited")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("$\(String(format: "%.2f", depositAmount))")
                                    .font(.calloutMedium)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            HStack {
                                Text("Invested")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("$\(String(format: "%.2f", result.totalInvested))")
                                    .font(.calloutMedium)
                                    .foregroundColor(.successGreen)
                            }
                            
                            HStack {
                                Text("Successful Orders")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("\(result.successCount)")
                                    .font(.calloutMedium)
                                    .foregroundColor(.successGreen)
                            }
                            
                            if result.failedCount > 0 {
                                HStack {
                                    Text("Failed Orders")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text("\(result.failedCount)")
                                        .font(.calloutMedium)
                                        .foregroundColor(.errorRed)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Order Details
                    ForsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Order Details")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            ForEach(result.orderResults) { order in
                                HStack {
                                    // Status Icon
                                    Image(systemName: orderStatusIcon(order.status))
                                        .font(.caption)
                                        .foregroundColor(orderStatusColor(order.status))
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(order.symbol)
                                            .font(.calloutMedium)
                                            .foregroundColor(.textPrimary)
                                        
                                        if let message = order.message {
                                            Text(message)
                                                .font(.caption2)
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text("$\(String(format: "%.2f", order.requestedAmount))")
                                        .font(.calloutMedium)
                                        .foregroundColor(orderStatusColor(order.status))
                                }
                                
                                if order.id != result.orderResults.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Investment Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            .safeAreaInset(edge: .bottom) {
                ForsaButton("View Portfolio", style: .primary, size: .large) {
                    onDismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(Color.backgroundPrimary)
            }
        }
    }
    
    private func orderStatusIcon(_ status: OrderResultStatus) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
    
    private func orderStatusColor(_ status: OrderResultStatus) -> Color {
        switch status {
        case .success: return .successGreen
        case .failed: return .errorRed
        case .skipped: return .textSecondary
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
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
        .environmentObject(AppCoordinator())
}