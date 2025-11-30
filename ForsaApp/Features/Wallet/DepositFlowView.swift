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
    
    // MARK: - State
    @State private var amountKWD: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var autoInvestEnabled = true
    @State private var isInvesting = false
    @State private var investmentResult: PortfolioInvestmentResult?
    @State private var showInvestmentResult = false
    @State private var contentAppeared = false
    @State private var selectedQuickAmount: Int? = nil
    @State private var selectedPaymentMethod: DepositPaymentMethod = .knet
    
    // Credit Card State
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    
    // KNET State
    @State private var showKNETWebView = false
    @State private var knetPaymentResponse: KNETPaymentResponse?
    
    // MARK: - Constants
    private let exchangeRate = AppConfig.Currency.kwdToUsdRate
    
    // MARK: - Computed Properties
    
    private var amountUSD: Double {
        guard let kwd = Double(amountKWD) else { return 0 }
        return (kwd - selectedPaymentMethod.calculateFee(for: kwd)) * exchangeRate
    }
    
    private var selectedPortfolioName: String {
        coordinator.selectedPortfolio?.title ?? "your portfolio"
    }
    
    private var isValidAmount: Bool {
        guard let value = Double(amountKWD), value >= WalletConstants.minimumDepositKWD else { return false }
        return true
    }
    
    private var isCardValid: Bool {
        guard selectedPaymentMethod == .creditCard else { return true }
        let cleanedCard = cardNumber.replacingOccurrences(of: " ", with: "")
        return cleanedCard.count >= 15 &&
               expiryDate.count == 5 &&
               cvv.count >= 3 &&
               !cardholderName.isEmpty
    }
    
    private var canProceed: Bool {
        isValidAmount && isCardValid
    }
    
    private var actionButtonTitle: String {
        switch selectedPaymentMethod {
        case .knet:
            return autoInvestEnabled ? "Pay with KNET & Invest" : WalletStrings.payWithKnet
        case .creditCard:
            return autoInvestEnabled ? "Pay & Invest" : WalletStrings.payWithCard
        case .bankWire:
            return "I've Initiated the Transfer"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: WalletConstants.cardSpacing) {
                        // Payment Method Tabs
                        PaymentMethodTabBar(selectedMethod: $selectedPaymentMethod)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                        
                        // Payment Method Header
                        PaymentMethodHeaderCard(method: selectedPaymentMethod)
                            .id(selectedPaymentMethod)
                        
                        // Amount Input Section
                        amountInputSection
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                            .animation(.spring(response: WalletConstants.springResponse,
                                               dampingFraction: WalletConstants.springDamping)
                                       .delay(WalletConstants.cardAppearanceDelay),
                                       value: contentAppeared)
                        
                        // Quick Select Buttons
                        quickSelectButtons
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                            .animation(.spring(response: WalletConstants.springResponse,
                                               dampingFraction: WalletConstants.springDamping)
                                       .delay(WalletConstants.cardAppearanceDelay * 2),
                                       value: contentAppeared)
                        
                        // Payment Method Specific Content
                        paymentMethodContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(selectedPaymentMethod.rawValue)
                        
                        // Fee Breakdown (for amount > 0)
                        if let amount = Double(amountKWD), amount > 0 {
                            FeeBreakdownCard(
                                method: selectedPaymentMethod,
                                amountKWD: amount,
                                exchangeRate: exchangeRate
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Auto Invest Section
                        if coordinator.selectedPortfolio != nil && selectedPaymentMethod != .bankWire {
                            autoInvestSection
                                .opacity(contentAppeared ? 1 : 0)
                                .offset(y: contentAppeared ? 0 : 20)
                                .animation(.spring(response: WalletConstants.springResponse,
                                                   dampingFraction: WalletConstants.springDamping)
                                           .delay(WalletConstants.cardAppearanceDelay * 3),
                                           value: contentAppeared)
                        }
                        
                        // Security Badge
                        if selectedPaymentMethod != .bankWire {
                            SecurityBadge()
                        }
                        
                        // Info Card
                        infoCard
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                            .animation(.spring(response: WalletConstants.springResponse,
                                               dampingFraction: WalletConstants.springDamping)
                                       .delay(WalletConstants.cardAppearanceDelay * 4),
                                       value: contentAppeared)
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.top, 16)
                }
                
                // Fixed Bottom Button
                bottomButton
                
                // Processing Overlay
                if isProcessing || isInvesting {
                    PaymentProcessingOverlay(
                        message: isInvesting ? "Investing your funds..." : WalletStrings.processingPayment,
                        method: selectedPaymentMethod
                    )
                    .transition(.opacity)
                }
            }
            .navigationTitle(WalletStrings.depositTitle)
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
            .sheet(isPresented: $showInvestmentResult) {
                if let result = investmentResult {
                    InvestmentResultView(result: result, depositAmount: amountUSD) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showKNETWebView) {
                KNETPaymentWebView(
                    paymentResponse: knetPaymentResponse,
                    onSuccess: { result in
                        showKNETWebView = false
                        Task { await handlePaymentSuccess() }
                    },
                    onCancel: {
                        showKNETWebView = false
                    },
                    onError: { error in
                        showKNETWebView = false
                        errorMessage = error
                        showError = true
                    }
                )
            }
            .alert(String(localized: "Deposit Initiated!"), isPresented: $showSuccess) {
                Button(WalletStrings.done) { dismiss() }
            } message: {
                Text(successMessage)
            }
            .onAppear {
                withAnimation(.easeOut(duration: WalletConstants.fadeInDuration)) {
                    contentAppeared = true
                }
            }
        }
    }
    
    private var successMessage: String {
        switch selectedPaymentMethod {
        case .knet, .creditCard:
            return "Your deposit of KWD \(amountKWD) ($\(String(format: "%.2f", amountUSD)) USD) has been processed successfully!"
        case .bankWire:
            return "Your deposit request has been recorded. Once we receive the bank transfer of KWD \(amountKWD), your account will be credited within 1-3 business days."
        }
    }
    
    // MARK: - Payment Method Specific Content
    
    @ViewBuilder
    private var paymentMethodContent: some View {
        switch selectedPaymentMethod {
        case .knet:
            knetContent
        case .creditCard:
            creditCardContent
        case .bankWire:
            bankWireContent
        }
    }
    
    // MARK: - KNET Content
    
    private var knetContent: some View {
        VStack(spacing: 16) {
            // KNET Info Card
            HStack(spacing: 12) {
                KNETLogoView(size: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kuwait's Trusted Payment Gateway")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Pay directly from your Kuwaiti bank account")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(hex: "0066B3")?.opacity(0.08) ?? Color.blue.opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal, WalletConstants.horizontalPadding)
            
            // Supported Banks
            SupportedBanksView()
        }
    }
    
    // MARK: - Credit Card Content
    
    private var creditCardContent: some View {
        VStack(spacing: 16) {
            CreditCardInputForm(
                cardNumber: $cardNumber,
                expiryDate: $expiryDate,
                cvv: $cvv,
                cardholderName: $cardholderName
            )
            
            // Accepted Cards
            HStack(spacing: 16) {
                Text("Accepted:")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                HStack(spacing: 8) {
                    Text("VISA")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    HStack(spacing: -3) {
                        Circle().fill(Color.red).frame(width: 12, height: 12)
                        Circle().fill(Color.orange).frame(width: 12, height: 12)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding(.horizontal, WalletConstants.horizontalPadding)
        }
    }
    
    // MARK: - Bank Wire Content
    
    private var bankWireContent: some View {
        VStack(spacing: 16) {
            BankWireInstructionsCard()
            
            // Amount to Transfer
            if let amount = Double(amountKWD), amount > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount to Transfer")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Text("KWD \(String(format: "%.3f", amount + selectedPaymentMethod.flatFee))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)
                    }
                    
                    Spacer()
                    
                    Text("(includes KWD 5 fee)")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
                .padding()
                .background(Color.primaryGreen.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, WalletConstants.horizontalPadding)
            }
        }
    }
    
    // MARK: - Amount Input Section
    
    private var amountInputSection: some View {
        VStack(spacing: WalletConstants.sectionSpacing) {
            Text(WalletStrings.enterAmountKWD)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Text("KWD")
                    .font(.system(size: WalletConstants.currencyLabelFontSize, weight: .bold))
                    .foregroundColor(.primaryPurple)
                
                TextField("0.000", text: $amountKWD)
                    .font(.system(size: WalletConstants.amountInputFontSize, weight: .bold))
                    .foregroundColor(.primaryPurple)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .onChange(of: amountKWD) { _, _ in
                        selectedQuickAmount = nil
                    }
            }
            .padding()
            .background(Color.backgroundCard)
            .cornerRadius(WalletConstants.infoCardCornerRadius)
            .shadow(color: .shadowLight, radius: 4, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Amount in KWD")
            .accessibilityValue(amountKWD.isEmpty ? "Enter amount" : "KWD \(amountKWD)")
            
            // Conversion Display
            if let _ = Double(amountKWD), amountUSD > 0 {
                CurrencyConversionDisplay(
                    fromAmount: Double(amountKWD) ?? 0,
                    toAmount: amountUSD,
                    exchangeRate: exchangeRate,
                    fromCurrency: "KWD",
                    toCurrency: "USD"
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
    
    // MARK: - Quick Select Buttons
    
    private var quickSelectButtons: some View {
        VStack(spacing: 12) {
            Text(WalletStrings.quickSelectKWD)
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(WalletConstants.quickSelectAmountsKWD, id: \.self) { value in
                    QuickAmountButton(
                        amount: value,
                        currency: "KWD",
                        conversionValue: "≈ $\(Int(Double(value) * exchangeRate))",
                        isSelected: selectedQuickAmount == value
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            amountKWD = "\(value)"
                            selectedQuickAmount = value
                        }
                    }
                }
            }
        }
        .padding(.horizontal, WalletConstants.horizontalPadding)
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
                        Text(WalletStrings.autoInvestFunds)
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)
                        
                        Text("Automatically invest in \(selectedPortfolioName)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .tint(.primaryGreen)
            .accessibilityLabel(WalletStrings.autoInvestFunds)
            .accessibilityHint("Automatically invest deposited funds in \(selectedPortfolioName)")
            
            if autoInvestEnabled, let portfolio = coordinator.selectedPortfolio {
                allocationPreview(portfolio: portfolio)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(Color.backgroundCard)
        .cornerRadius(WalletConstants.infoCardCornerRadius)
        .shadow(color: .shadowLight, radius: 4, y: 2)
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
    
    private func allocationPreview(portfolio: RiskLevel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(WalletStrings.investmentBreakdown)
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(allocation.name): \(Int(allocation.percentage * 100)) percent")
            }
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        WalletInfoCard(
            title: WalletStrings.depositInformation,
            icon: "info.circle.fill",
            iconColor: .infoBlue,
            rows: [
                (label: WalletStrings.processingTime, value: selectedPaymentMethod.processingTime),
                (label: WalletStrings.minimumDeposit, value: "KWD 10 (~$32.50)"),
                (label: WalletStrings.fee, value: selectedPaymentMethod.feePercentage > 0 ? "\(String(format: "%.1f", selectedPaymentMethod.feePercentage))%" : (selectedPaymentMethod.flatFee > 0 ? "KWD \(String(format: "%.0f", selectedPaymentMethod.flatFee))" : WalletStrings.free))
            ]
        )
        .padding(.horizontal, WalletConstants.horizontalPadding)
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
                        .transition(.scale.combined(with: .opacity))
                }
                
                ForsaButton(
                    actionButtonTitle,
                    style: .primary,
                    size: .large,
                    isDisabled: !canProceed,
                    isLoading: isProcessing || isInvesting
                ) {
                    Task { await processDeposit() }
                }
                .accessibilityLabel(actionButtonTitle)
                .accessibilityHint(canProceed ? "Tap to proceed with payment" : "Enter a valid amount first")
            }
            .padding(.horizontal, WalletConstants.horizontalPadding)
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
        switch selectedPaymentMethod {
        case .knet:
            await processKNETPayment()
        case .creditCard:
            await processCreditCardPayment()
        case .bankWire:
            await processBankWireTransfer()
        }
    }
    
    // MARK: - KNET Payment Processing
    
    private func processKNETPayment() async {
        isProcessing = true
        
        do {
            guard let amount = Double(amountKWD) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid amount"])
            }
            
            let trackId = "FORSA-\(UUID().uuidString.prefix(8))"
            let response = try await KNETPaymentService.shared.initiatePayment(amount: amount, trackId: trackId)
            
            await MainActor.run {
                knetPaymentResponse = response
                isProcessing = false
                showKNETWebView = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to initiate KNET payment: \(error.localizedDescription)"
                showError = true
                isProcessing = false
            }
        }
    }
    
    // MARK: - Credit Card Payment Processing
    
    private func processCreditCardPayment() async {
        isProcessing = true
        
        do {
            // Simulate credit card processing
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            await handlePaymentSuccess()
        } catch {
            await MainActor.run {
                errorMessage = "Credit card payment failed: \(error.localizedDescription)"
                showError = true
                isProcessing = false
            }
        }
    }
    
    // MARK: - Bank Wire Transfer Processing
    
    private func processBankWireTransfer() async {
        isProcessing = true
        
        do {
            // Record the pending bank wire transfer
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isProcessing = false
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to record transfer: \(error.localizedDescription)"
                showError = true
                isProcessing = false
            }
        }
    }
    
    // MARK: - Handle Payment Success
    
    private func handlePaymentSuccess() async {
        do {
            guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: WalletStrings.noAccountFound])
            }
            
            try await AlpacaTradingService.shared.fundAccount(accountId: accountId, amount: amountUSD)
            
            await MainActor.run {
                isProcessing = false
            }
            
            if autoInvestEnabled && coordinator.selectedPortfolio != nil {
                await MainActor.run {
                    isInvesting = true
                }
                
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                let account = try await AlpacaTradingService.shared.fetchAccountDetails(accountId: accountId)
                let availableCash = account.cashValue
                
                if availableCash >= 1.0 {
                    let investAmount = min(amountUSD, availableCash)
                    
                    if let result = try await coordinator.investInPortfolio(amount: investAmount) {
                        await MainActor.run {
                            investmentResult = result
                            showInvestmentResult = true
                            isInvesting = false
                        }
                    }
                } else {
                    await MainActor.run {
                        isInvesting = false
                        showSuccess = true
                    }
                }
            } else {
                await MainActor.run {
                    showSuccess = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Operation failed: \(error.localizedDescription)"
                showError = true
                isProcessing = false
                isInvesting = false
            }
        }
    }
}

// MARK: - Supported Banks View

struct SupportedBanksView: View {
    private let banks = [
        ("NBK", "National Bank of Kuwait"),
        ("KFH", "Kuwait Finance House"),
        ("ABK", "Al Ahli Bank"),
        ("Burgan", "Burgan Bank"),
        ("Warba", "Warba Bank"),
        ("Boubyan", "Boubyan Bank")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supported Banks")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(banks, id: \.0) { bank in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.backgroundSecondary)
                                .frame(width: 40, height: 40)
                            
                            Text(bank.0.prefix(2))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }
                        
                        Text(bank.0)
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
}

// MARK: - KNET Payment WebView

struct KNETPaymentWebView: View {
    let paymentResponse: KNETPaymentResponse?
    let onSuccess: (KNETPaymentResult) -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void
    
    @State private var isSimulating = false
    @State private var simulationProgress: Double = 0
    @State private var showTestCardInfo = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // KNET Header
                        HStack {
                            KNETLogoView(size: 48)
                            
                            VStack(alignment: .leading) {
                                Text("KNET Payment Gateway")
                                    .font(.headline)
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.warningYellow)
                                        .frame(width: 8, height: 8)
                                    Text("Sandbox Mode")
                                        .font(.caption)
                                        .foregroundColor(.warningYellow)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(hex: "0066B3")?.opacity(0.1) ?? Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        if let response = paymentResponse {
                            // Payment Details
                            VStack(spacing: 16) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.primaryGreen)
                                
                                Text("Secure Payment")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Transaction ID: \(response.trackId)")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.backgroundSecondary)
                                    .cornerRadius(6)
                            }
                            
                            // Test Card Information
                            if showTestCardInfo {
                                testCardInfoSection
                            }
                            
                            // Info about production
                            VStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.infoBlue)
                                
                                Text("In production, users will be redirected to the official KNET payment page to select their bank and enter credentials securely.")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.infoBlue.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Simulation Progress
                            if isSimulating {
                                VStack(spacing: 12) {
                                    ProgressView(value: simulationProgress)
                                        .tint(Color(hex: "0066B3") ?? .blue)
                                    
                                    Text("Processing payment...")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding()
                            }
                            
                            Spacer(minLength: 20)
                            
                            // Action Buttons
                            VStack(spacing: 12) {
                                Button {
                                    simulatePayment()
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Simulate Successful Payment")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primaryGreen)
                                    .cornerRadius(12)
                                }
                                .disabled(isSimulating)
                                
                                Button {
                                    simulateDeclinedPayment()
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Simulate Declined Payment")
                                    }
                                    .font(.callout)
                                    .foregroundColor(.errorRed)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.errorRed.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(isSimulating)
                                
                                Button {
                                    onCancel()
                                } label: {
                                    Text("Cancel Payment")
                                        .font(.callout)
                                        .foregroundColor(.textSecondary)
                                }
                                .disabled(isSimulating)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("KNET Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isSimulating)
                }
            }
        }
    }
    
    // MARK: - Test Card Info Section
    
    private var testCardInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(Color(hex: "0066B3") ?? .blue)
                Text("Sandbox Test Card")
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showTestCardInfo.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            
            VStack(spacing: 8) {
                TestCardRow(label: "Bank", value: "Knet Test Card [KNET1]")
                TestCardRow(label: "Card Number", value: "8888 8800 0000 0001", isCopyable: true)
                TestCardRow(label: "Expiry Date", value: "09/30")
                TestCardRow(label: "PIN", value: "1234")
            }
            
            Text("Use these credentials when testing with real KNET sandbox")
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
        .padding()
        .background(Color(hex: "0066B3")?.opacity(0.08) ?? Color.blue.opacity(0.08))
        .cornerRadius(12)
    }
    
    private func simulatePayment() {
        isSimulating = true
        simulationProgress = 0
        
        // Animate progress
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            simulationProgress += 0.02
            if simulationProgress >= 1.0 {
                timer.invalidate()
                
                // Complete payment
                let result = KNETPaymentResult(
                    paymentId: paymentResponse?.paymentId ?? UUID().uuidString,
                    trackId: paymentResponse?.trackId ?? "",
                    tranId: "TRN\(Int.random(in: 100000...999999))",
                    authCode: "\(Int.random(in: 100000...999999))",
                    result: "CAPTURED",
                    postDate: ISO8601DateFormatter().string(from: Date()),
                    referenceId: "REF\(Int.random(in: 100000...999999))",
                    amount: 0,
                    status: .captured
                )
                
                onSuccess(result)
            }
        }
    }
    
    private func simulateDeclinedPayment() {
        isSimulating = true
        simulationProgress = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            simulationProgress += 0.02
            if simulationProgress >= 1.0 {
                timer.invalidate()
                isSimulating = false
                onError("Payment declined. Please try again or use a different payment method.")
            }
        }
    }
}

// MARK: - Test Card Row

struct TestCardRow: View {
    let label: String
    let value: String
    var isCopyable: Bool = false
    @State private var copied = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            if isCopyable {
                Button {
                    UIPasteboard.general.string = value.replacingOccurrences(of: " ", with: "")
                    withAnimation {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            copied = false
                        }
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                        .foregroundColor(copied ? .primaryGreen : .primaryPurple)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DepositFlowView()
        .environmentObject(AppCoordinator())
}
