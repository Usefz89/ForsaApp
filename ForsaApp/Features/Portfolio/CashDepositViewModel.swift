//
//  CashDepositViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import Foundation
import SwiftUI

@MainActor
class CashDepositViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var depositAmount: Double = 0
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var isProcessing: Bool = false
    @Published var depositCompleted: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    @Published var twoFactorEnabled: Bool = false
    @Published var biometricVerified: Bool = false
    @Published var autoInvestExistingPies: Bool = false

    // Mock data
    @Published var cashAccount: CashAccount
    @Published var recentTransactions: [DepositTransaction] = []

    let suggestedAmounts: [Double] = [100, 500, 1000, 2000]
    let maxSteps: Int = 5

    var depositAmountText: String {
        get {
            depositAmount > 0 ? String(format: "%.0f", depositAmount) : ""
        }
        set {
            depositAmount = Double(newValue) ?? 0
        }
    }

    var canProceedFromAmount: Bool {
        depositAmount >= 5 && depositAmount <= cashAccount.availableDailyLimit
    }

    var canProceedFromPayment: Bool {
        selectedPaymentMethod != nil
    }

    var processingFee: Double {
        guard let paymentMethod = selectedPaymentMethod else { return 0 }
        return depositAmount * (paymentMethod.processingFeePercentage / 100)
    }

    var netAmount: Double {
        depositAmount - processingFee
    }

    var estimatedSettlementTime: String {
        selectedPaymentMethod?.processingTime ?? "Unknown"
    }

    var requiresTwoFactor: Bool {
        depositAmount >= 1000
    }

    var canConfirmDeposit: Bool {
        canProceedFromPayment && (!requiresTwoFactor || twoFactorEnabled)
    }

    init() {
        // Initialize with mock cash account
        self.cashAccount = CashAccount(
            userId: UUID(),
            balance: 5250.0,
            totalDeposited: 12500.0,
            kycStatus: .verified,
            verificationLevel: .full
        )

        // Generate mock recent transactions
        self.recentTransactions = generateMockTransactions()
    }

    func nextStep() {
        if currentStep < maxSteps {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }

    func goToStep(_ step: Int) {
        if step >= 1 && step <= maxSteps {
            currentStep = step
        }
    }

    func selectAmount(_ amount: Double) {
        depositAmount = amount
    }

    func selectPaymentMethod(_ method: PaymentMethod) {
        selectedPaymentMethod = method
    }

    func enableTwoFactor() {
        // Mock 2FA process
        Task {
            isProcessing = true
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            twoFactorEnabled = true
            isProcessing = false
        }
    }

    func enableBiometric() {
        // Mock biometric verification
        Task {
            isProcessing = true
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            biometricVerified = true
            isProcessing = false
        }
    }

    func confirmDeposit() {
        guard canConfirmDeposit, let paymentMethod = selectedPaymentMethod else { return }

        Task {
            isProcessing = true

            // Create transaction
            let transaction = DepositTransaction(
                accountId: cashAccount.id,
                amount: depositAmount,
                paymentMethod: paymentMethod,
                processingFee: processingFee,
                estimatedSettlementTime: estimatedSettlementTime
            )

            // Mock processing delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // Add to recent transactions
            recentTransactions.insert(transaction, at: 0)

            // Update cash account balance (mock)
            cashAccount = CashAccount(
                id: cashAccount.id,
                userId: cashAccount.userId,
                balance: cashAccount.balance + netAmount,
                currency: cashAccount.currency,
                dailyDepositLimit: cashAccount.dailyDepositLimit,
                monthlyDepositLimit: cashAccount.monthlyDepositLimit,
                totalDeposited: cashAccount.totalDeposited + netAmount,
                totalWithdrawn: cashAccount.totalWithdrawn,
                kycStatus: cashAccount.kycStatus,
                verificationLevel: cashAccount.verificationLevel,
                createdAt: cashAccount.createdAt,
                updatedAt: Date()
            )

            // Handle auto-invest in existing pies if enabled
            if autoInvestExistingPies {
                handleAutoInvestInExistingPies()
            }

            isProcessing = false
            depositCompleted = true
        }
    }

    private func handleAutoInvestInExistingPies() {
        // Mock implementation - in real app, this would distribute funds among existing pies
        // based on their current allocation percentages or user preferences

        // For demo purposes, we'll just log this action
        print("Auto-investing KWD \(String(format: "%.2f", netAmount)) across existing pies")

        // In a real implementation, this would:
        // 1. Get user's existing investment pies
        // 2. Calculate allocation based on current pie sizes or user preferences
        // 3. Execute buy orders for each pie's underlying stocks
        // 4. Update pie balances and holdings
    }

    func reset() {
        currentStep = 1
        depositAmount = 0
        selectedPaymentMethod = nil
        isProcessing = false
        depositCompleted = false
        twoFactorEnabled = false
        biometricVerified = false
        autoInvestExistingPies = false
        errorMessage = ""
        showingError = false
    }

    private func generateMockTransactions() -> [DepositTransaction] {
        let transactions: [DepositTransaction] = [
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 1000,
                paymentMethod: .knet,
                estimatedSettlementTime: "Instant"
            ),
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 500,
                paymentMethod: .applePay,
                estimatedSettlementTime: "Instant"
            ),
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 250,
                paymentMethod: .creditCard,
                processingFee: 7.25,
                estimatedSettlementTime: "Instant"
            )
        ]

        return transactions
    }

    // MARK: - Step Validation
    func canProceed(from step: Int) -> Bool {
        switch step {
        case 1:
            return true // Can always proceed from step 1
        case 2:
            return canProceedFromAmount
        case 3:
            return canProceedFromPayment
        case 4:
            return canConfirmDeposit
        case 5:
            return depositCompleted
        default:
            return false
        }
    }

    // MARK: - Progress Calculation
    var progressPercentage: Double {
        Double(currentStep) / Double(maxSteps)
    }

    var currentStepTitle: String {
        switch currentStep {
        case 1:
            return "Deposit Amount"
        case 2:
            return "Payment Method"
        case 3:
            return "Security Verification"
        case 4:
            return "Confirmation"
        case 5:
            return "Complete"
        default:
            return "Deposit"
        }
    }
}