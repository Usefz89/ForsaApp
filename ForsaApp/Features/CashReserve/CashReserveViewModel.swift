//
//  CashReserveViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import Foundation
import SwiftUI

@MainActor
class CashReserveViewModel: ObservableObject {
    @Published var cashAccount: CashAccount
    @Published var allTransactions: [DepositTransaction] = []
    @Published var pendingTransactions: [DepositTransaction] = []
    @Published var completedTransactions: [DepositTransaction] = []

    @Published var showingDepositFlow = false
    @Published var showingWithdrawFlow = false

    @Published var isLoading = false
    @Published var refreshing = false

    // Computed properties
    var pendingAmount: Double {
        pendingTransactions.reduce(0) { $0 + $1.netAmount }
    }

    var availableBalance: Double {
        cashAccount.balance - pendingAmount
    }

    var formattedAvailableBalance: String {
        "KWD \(String(format: "%.3f", availableBalance))"
    }

    var formattedPendingAmount: String {
        "KWD \(String(format: "%.3f", pendingAmount))"
    }

    var recentTransactions: [DepositTransaction] {
        Array(completedTransactions.prefix(5))
    }

    var hasTransactions: Bool {
        !allTransactions.isEmpty
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

        loadMockData()
    }

    func loadData() {
        Task {
            isLoading = true

            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // In real app, would fetch from API
            loadMockData()

            isLoading = false
        }
    }

    func refreshData() async {
        refreshing = true

        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Refresh account balance and transactions
        loadMockData()

        refreshing = false
    }

    func showDepositFlow() {
        showingDepositFlow = true
    }

    func showWithdrawFlow() {
        showingWithdrawFlow = true
    }

    func handleDepositCompleted(_ transaction: DepositTransaction) {
        // Update cash account balance
        let newBalance = cashAccount.balance + transaction.netAmount
        cashAccount = CashAccount(
            id: cashAccount.id,
            userId: cashAccount.userId,
            balance: newBalance,
            currency: cashAccount.currency,
            dailyDepositLimit: cashAccount.dailyDepositLimit,
            monthlyDepositLimit: cashAccount.monthlyDepositLimit,
            totalDeposited: cashAccount.totalDeposited + transaction.netAmount,
            totalWithdrawn: cashAccount.totalWithdrawn,
            kycStatus: cashAccount.kycStatus,
            verificationLevel: cashAccount.verificationLevel,
            createdAt: cashAccount.createdAt,
            updatedAt: Date()
        )

        // Add to completed transactions
        completedTransactions.insert(transaction, at: 0)
        allTransactions.insert(transaction, at: 0)
    }

    private func loadMockData() {
        // Generate mock transactions
        let mockTransactions: [DepositTransaction] = [
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 1000,
                paymentMethod: .knet,
                estimatedSettlementTime: "Instant",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 500,
                paymentMethod: .applePay,
                estimatedSettlementTime: "Instant",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 250,
                paymentMethod: .creditCard,
                processingFee: 7.25,
                estimatedSettlementTime: "Instant",
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 2000,
                paymentMethod: .wireTransfer,
                processingFee: 30.0,
                estimatedSettlementTime: "1-3 business days",
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            ),
            DepositTransaction(
                accountId: cashAccount.id,
                amount: 750,
                paymentMethod: .knet,
                estimatedSettlementTime: "Instant",
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
            )
        ]

        // Simulate some pending transactions
        let pendingTransaction = DepositTransaction(
            accountId: cashAccount.id,
            amount: 300,
            paymentMethod: .wireTransfer,
            processingFee: 4.5,
            estimatedSettlementTime: "1-2 business days",
            createdAt: Date()
        )

        self.allTransactions = mockTransactions + [pendingTransaction]
        self.completedTransactions = mockTransactions
        self.pendingTransactions = [pendingTransaction]
    }
}