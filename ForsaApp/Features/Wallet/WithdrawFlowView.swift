//
//  WithdrawFlowView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct WithdrawFlowView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    let availableBalance: Double
    
    // MARK: - State
    @State private var amount: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var contentAppeared = false
    @State private var selectedQuickAmount: Double? = nil
    
    // MARK: - Computed Properties
    
    private var amountValue: Double {
        Double(amount) ?? 0
    }
    
    private var isValidAmount: Bool {
        guard let value = Double(amount), value >= WalletConstants.minimumWithdrawal else { return false }
        return value <= availableBalance
    }
    
    private var availableBalanceText: String {
        "$\(String(format: "%.2f", availableBalance))"
    }
    
    private var exceedsBalance: Bool {
        amountValue > availableBalance
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: WalletConstants.cardSpacing) {
                        // Available Balance Display
                        availableBalanceCard
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                        
                        // Amount Input
                        amountInputSection
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                            .animation(.spring(response: WalletConstants.springResponse,
                                               dampingFraction: WalletConstants.springDamping)
                                       .delay(WalletConstants.cardAppearanceDelay),
                                       value: contentAppeared)
                        
                        // Quick Select
                        quickSelectSection
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                            .animation(.spring(response: WalletConstants.springResponse,
                                               dampingFraction: WalletConstants.springDamping)
                                       .delay(WalletConstants.cardAppearanceDelay * 2),
                                       value: contentAppeared)
                        
                        // Info Card
                        infoCard
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                            .animation(.spring(response: WalletConstants.springResponse,
                                               dampingFraction: WalletConstants.springDamping)
                                       .delay(WalletConstants.cardAppearanceDelay * 3),
                                       value: contentAppeared)
                        
                        Spacer(minLength: 120)
                    }
                }
                
                // Bottom Button
                bottomButton
            }
            .navigationTitle(WalletStrings.withdrawTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(WalletStrings.cancel) { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
            .alert(WalletStrings.error, isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert(String(localized: "Withdrawal Initiated!"), isPresented: $showSuccess) {
                Button(WalletStrings.done) { dismiss() }
            } message: {
                Text("Your withdrawal of $\(amount) has been initiated.\n\nFunds will arrive in your bank account within 1-3 business days.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: WalletConstants.fadeInDuration)) {
                    contentAppeared = true
                }
            }
        }
    }
    
    // MARK: - Available Balance Card
    
    private var availableBalanceCard: some View {
        ForsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(WalletStrings.availableToWithdraw)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text(availableBalanceText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryPurple)
                }
                
                Spacer()
                
                Image(systemName: "wallet.pass.fill")
                    .font(.title2)
                    .foregroundColor(.primaryPurple.opacity(0.3))
            }
        }
        .padding(.horizontal, WalletConstants.horizontalPadding)
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(WalletStrings.availableToWithdraw): \(availableBalanceText)")
    }
    
    // MARK: - Amount Input Section
    
    private var amountInputSection: some View {
        VStack(spacing: 12) {
            Text(WalletStrings.enterWithdrawAmount)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Text("$")
                    .font(.system(size: WalletConstants.amountInputFontSize, weight: .bold))
                    .foregroundColor(exceedsBalance ? .errorRed : .primaryPurple)
                
                TextField("0.00", text: $amount)
                    .font(.system(size: WalletConstants.amountInputFontSize, weight: .bold))
                    .foregroundColor(exceedsBalance ? .errorRed : .primaryPurple)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .onChange(of: amount) { _, _ in
                        selectedQuickAmount = nil
                    }
            }
            .padding()
            .background(Color.backgroundCard)
            .cornerRadius(WalletConstants.infoCardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: WalletConstants.infoCardCornerRadius)
                    .stroke(exceedsBalance ? Color.errorRed : Color.clear, lineWidth: 2)
            )
            
            // Error message if exceeds balance
            if exceedsBalance {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(String(localized: "Amount exceeds available balance"))
                        .font(.caption)
                }
                .foregroundColor(.errorRed)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Withdraw All Button
            if availableBalance > 0 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        amount = String(format: "%.2f", availableBalance)
                        selectedQuickAmount = availableBalance
                    }
                }) {
                    Text(String(localized: "Withdraw All (\(availableBalanceText))"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryPurple)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.primaryPurple.opacity(0.1))
                        .cornerRadius(8)
                }
                .accessibilityLabel("Withdraw all available funds")
            }
        }
        .padding(.horizontal, WalletConstants.horizontalPadding)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Quick Select Section
    
    private var quickSelectSection: some View {
        VStack(spacing: 12) {
            Text(WalletStrings.quickSelectUSD)
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(WalletConstants.quickSelectAmountsUSD, id: \.self) { value in
                    QuickAmountButton(
                        amount: Int(value),
                        currency: "$",
                        conversionValue: nil,
                        isSelected: selectedQuickAmount == value
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            amount = String(format: "%.0f", value)
                            selectedQuickAmount = value
                        }
                    }
                    .disabled(value > availableBalance)
                    .opacity(value > availableBalance ? 0.5 : 1)
                }
            }
        }
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        WalletInfoCard(
            title: WalletStrings.withdrawalInformation,
            icon: "info.circle.fill",
            iconColor: .infoBlue,
            rows: [
                (label: WalletStrings.estimatedArrival, value: WalletStrings.businessDays),
                (label: WalletStrings.minimumDeposit, value: "$1.00"),
                (label: WalletStrings.fee, value: WalletStrings.free)
            ]
        )
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 8) {
                if amountValue > 0 && !exceedsBalance {
                    HStack(spacing: 4) {
                        Text(String(localized: "Withdrawing"))
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                        Text("$\(String(format: "%.2f", amountValue))")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryPurple)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                ForsaButton(
                    WalletStrings.withdrawFunds,
                    style: .primary,
                    size: .large,
                    isDisabled: !isValidAmount,
                    isLoading: isProcessing
                ) {
                    Task { await processWithdrawal() }
                }
                .accessibilityLabel(WalletStrings.withdrawFunds)
                .accessibilityHint(isValidAmount ? "Tap to withdraw funds" : exceedsBalance ? "Amount exceeds available balance" : "Enter a valid amount first")
            }
            .padding(.horizontal, WalletConstants.horizontalPadding)
            .padding(.bottom, 40)
            .background(
                Color.backgroundPrimary
                    .shadow(color: .shadowLight, radius: 10, y: -5)
            )
        }
    }
    
    // MARK: - Actions
    
    private func processWithdrawal() async {
        guard let amountValue = Double(amount) else { return }
        
        isProcessing = true
        
        do {
            guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: WalletStrings.noAccountFound])
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

// MARK: - Preview

#Preview {
    WithdrawFlowView(availableBalance: 1500.00)
}
