//
//  DepositFlowView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct DepositFlowView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var amountKWD: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var autoInvestEnabled = true
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
    
    private var isValidAmount: Bool {
        guard let value = Double(amountKWD), value >= 10 else { return false }
        return true
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        amountInputSection
                        quickSelectButtons
                        
                        if coordinator.selectedPortfolio != nil {
                            autoInvestSection
                        }
                        
                        infoCard
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Fixed Bottom Button
                bottomButton
            }
            .navigationTitle("Deposit Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
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
                Button("Done") { dismiss() }
            } message: {
                Text("Your deposit of KWD \(amountKWD) ($\(String(format: "%.2f", amountUSD)) USD) has been initiated!\n\nThe funds will be available within 1-2 business days.")
            }
        }
    }
    
    // MARK: - Amount Input Section
    
    private var amountInputSection: some View {
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
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text("Exchange Rate: 1 KWD = $\(String(format: "%.2f", exchangeRate)) USD")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
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
    }
    
    // MARK: - Quick Select Buttons
    
    private var quickSelectButtons: some View {
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
    }
    
    // MARK: - Auto Invest Section
    
    private var autoInvestSection: some View {
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
                allocationPreview(portfolio: portfolio)
            }
        }
        .padding()
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
    
    private func allocationPreview(portfolio: RiskLevel) -> some View {
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
    
    // MARK: - Info Card
    
    private var infoCard: some View {
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
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
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
                    Task { await processDeposit() }
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
    
    // MARK: - Helpers
    
    private func allocationColor(for assetClass: AssetClass) -> Color {
        switch assetClass {
        case .equity: return .primaryBlue
        case .sukuk: return .primaryGreen
        case .gold: return .warningYellow
        case .reit: return .primaryPurple
        case .international: return .primaryOrange
        case .emergingMarkets: return .errorRed
        }
    }
    
    private func processDeposit() async {
        isProcessing = true
        
        do {
            guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No account found. Please sign up first."])
            }
            
            try await AlpacaTradingService.shared.fundAccount(accountId: accountId, amount: amountUSD)
            
            isProcessing = false
            
            if autoInvestEnabled && coordinator.selectedPortfolio != nil {
                isInvesting = true
                
                print("⏳ Waiting for funds to settle...")
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                let account = try await AlpacaTradingService.shared.fetchAccountDetails(accountId: accountId)
                let availableCash = account.cashValue
                
                print("💰 Available cash after deposit: $\(availableCash)")
                
                if availableCash >= 1.0 {
                    let investAmount = min(amountUSD, availableCash)
                    
                    if let result = try await coordinator.investInPortfolio(amount: investAmount) {
                        investmentResult = result
                        showInvestmentResult = true
                    }
                } else {
                    print("⚠️ Funds not yet available. Transfer may be pending.")
                    await MainActor.run {
                        isInvesting = false
                        showSuccess = true
                    }
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

// MARK: - Info Row

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

