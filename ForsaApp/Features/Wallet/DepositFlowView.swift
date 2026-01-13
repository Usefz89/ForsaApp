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
                    VStack(spacing: 20) {
                        // Payment Method Selector (Compact)
                        paymentMethodSelector

                        // Amount Section
                        amountSection

                        // Quick Select
                        quickSelectSection

                        // Payment Method Details (Conditional)
                        paymentMethodDetails

                        // Auto Invest Toggle
                        if coordinator.selectedPortfolio != nil && selectedPaymentMethod != .bankWire {
                            autoInvestToggle
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }

                // Bottom Button
                bottomActionButton

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

    // MARK: - Payment Method Selector (Compact Pills)

    private var paymentMethodSelector: some View {
        HStack(spacing: 8) {
            ForEach(DepositPaymentMethod.allCases) { method in
                PaymentPill(
                    title: method.title,
                    icon: method.icon,
                    isSelected: selectedPaymentMethod == method,
                    color: method.iconColor
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPaymentMethod = method
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(spacing: 12) {
            // Large Amount Display
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("KWD")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textSecondary)

                TextField("0", text: $amountKWD)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryPurple)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .onChange(of: amountKWD) { _, _ in
                        selectedQuickAmount = nil
                    }
            }
            .padding(.vertical, 20)

            // Conversion Display
            if amountUSD > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text("$\(String(format: "%.2f", amountUSD)) USD")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.primaryGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primaryGreen.opacity(0.1))
                .cornerRadius(20)
                .transition(.scale.combined(with: .opacity))
            }

            // Fee Info (Subtle)
            if let amount = Double(amountKWD), amount > 0 {
                feeInfo(for: amount)
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: amountUSD)
    }

    private func feeInfo(for amount: Double) -> some View {
        let fee = selectedPaymentMethod.calculateFee(for: amount)

        return HStack(spacing: 4) {
            if fee > 0 {
                Text("Fee: KWD \(String(format: "%.3f", fee))")
                    .foregroundColor(.textTertiary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primaryGreen)
                Text("No fees")
                    .foregroundColor(.primaryGreen)
            }
        }
        .font(.caption)
    }

    // MARK: - Quick Select Section

    private var quickSelectSection: some View {
        HStack(spacing: 8) {
            ForEach(WalletConstants.quickSelectAmountsKWD, id: \.self) { value in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        amountKWD = "\(value)"
                        selectedQuickAmount = value
                    }
                } label: {
                    Text("KWD \(value)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedQuickAmount == value ? .white : .primaryPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedQuickAmount == value ? Color.primaryPurple : Color.primaryPurple.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Payment Method Details

    @ViewBuilder
    private var paymentMethodDetails: some View {
        switch selectedPaymentMethod {
        case .knet:
            knetDetails
        case .creditCard:
            creditCardForm
        case .bankWire:
            bankWireDetails
        }
    }

    private var knetDetails: some View {
        HStack(spacing: 12) {
            KNETLogoView(size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pay with KNET")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                Text("Instant • No fees • All Kuwaiti banks")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    private var creditCardForm: some View {
        VStack(spacing: 12) {
            // Card Number
            HStack {
                TextField("Card number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .onChange(of: cardNumber) { _, newValue in
                        cardNumber = formatCardNumber(newValue)
                    }
                CardBrandIcon(cardNumber: cardNumber)
            }
            .padding(14)
            .background(Color.backgroundSecondary)
            .cornerRadius(10)

            // Expiry & CVV
            HStack(spacing: 12) {
                TextField("MM/YY", text: $expiryDate)
                    .keyboardType(.numberPad)
                    .onChange(of: expiryDate) { _, newValue in
                        expiryDate = formatExpiryDate(newValue)
                    }
                    .padding(14)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)

                SecureField("CVV", text: $cvv)
                    .keyboardType(.numberPad)
                    .onChange(of: cvv) { _, newValue in
                        cvv = String(newValue.prefix(4))
                    }
                    .padding(14)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)
                    .frame(width: 100)
            }

            // Name
            TextField("Name on card", text: $cardholderName)
                .textContentType(.name)
                .autocapitalization(.words)
                .padding(14)
                .background(Color.backgroundSecondary)
                .cornerRadius(10)

            // Fee Warning
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                Text("2.5% processing fee applies")
            }
            .font(.caption)
            .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    private var bankWireDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .foregroundColor(.primaryGreen)
                Text("Transfer to this account")
                    .font(.callout)
                    .fontWeight(.medium)
            }

            VStack(spacing: 8) {
                BankInfoRow(label: "Bank", value: "Kuwait Finance House")
                BankInfoRow(label: "IBAN", value: "KW81CBKU...0101", copyable: "KW81CBKU0000000000001234560101")
                BankInfoRow(label: "Reference", value: "FORSA-\(String(Int.random(in: 100000...999999)))")
            }

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("1-3 business days • KWD 5 fee")
            }
            .font(.caption)
            .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.primaryGreen.opacity(0.08))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    // MARK: - Auto Invest Toggle

    private var autoInvestToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.title3)
                .foregroundColor(.primaryGreen)
                .frame(width: 32, height: 32)
                .background(Color.primaryGreen.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Auto-Invest")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                Text("Invest in \(selectedPortfolioName)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $autoInvestEnabled)
                .tint(.primaryGreen)
                .labelsHidden()
        }
        .padding(16)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom Action Button

    private var bottomActionButton: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                if amountUSD > 0 {
                    Text("You'll deposit $\(String(format: "%.2f", amountUSD)) USD")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Button {
                    Task { await processDeposit() }
                } label: {
                    HStack {
                        if isProcessing || isInvesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(actionButtonTitle)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canProceed ? Color.primaryPurple : Color.textTertiary)
                    .cornerRadius(12)
                }
                .disabled(!canProceed || isProcessing || isInvesting)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    colors: [Color.backgroundPrimary.opacity(0), Color.backgroundPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            )
        }
    }

    // MARK: - Helpers

    private func formatCardNumber(_ input: String) -> String {
        let cleaned = input.replacingOccurrences(of: " ", with: "")
        let limited = String(cleaned.prefix(16))
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        return formatted
    }

    private func formatExpiryDate(_ input: String) -> String {
        let cleaned = input.replacingOccurrences(of: "/", with: "")
        let limited = String(cleaned.prefix(4))
        if limited.count > 2 {
            return String(limited.prefix(2)) + "/" + String(limited.suffix(limited.count - 2))
        }
        return limited
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

// MARK: - Payment Pill

struct PaymentPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isSelected ? color : Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
}

// MARK: - Bank Info Row

struct BankInfoRow: View {
    let label: String
    let value: String
    var copyable: String? = nil
    @State private var copied = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)

            Spacer()

            if let copyValue = copyable {
                Button {
                    UIPasteboard.general.string = copyValue
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
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

// MARK: - KNET Payment WebView (Preserved)

struct KNETPaymentWebView: View {
    let paymentResponse: KNETPaymentResponse?
    let onSuccess: (KNETPaymentResult) -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void

    @State private var isSimulating = false
    @State private var simulationProgress: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // KNET Logo
                    KNETLogoView(size: 64)

                    Text("KNET Sandbox")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let response = paymentResponse {
                        Text("Transaction: \(response.trackId)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(8)
                    }

                    if isSimulating {
                        ProgressView(value: simulationProgress)
                            .tint(Color(hex: "0066B3") ?? .blue)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            simulatePayment()
                        } label: {
                            Text("Simulate Success")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.primaryGreen)
                                .cornerRadius(12)
                        }
                        .disabled(isSimulating)

                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.callout)
                                .foregroundColor(.textSecondary)
                        }
                        .disabled(isSimulating)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("KNET Payment")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func simulatePayment() {
        isSimulating = true
        simulationProgress = 0

        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            simulationProgress += 0.02
            if simulationProgress >= 1.0 {
                timer.invalidate()

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
}

// MARK: - Preview

#Preview {
    DepositFlowView()
        .environmentObject(AppCoordinator())
}
