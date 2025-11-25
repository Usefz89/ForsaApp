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
    @Published var errorMessage: String?
    
    private let alpacaService = AlpacaTradingService.shared

    // Computed properties
    var pendingAmount: Double {
        pendingTransactions.reduce(0) { $0 + $1.netAmount }
    }

    var availableBalance: Double {
        cashAccount.balance
    }

    var formattedAvailableBalance: String {
        "$\(String(format: "%.2f", availableBalance))"
    }

    var formattedPendingAmount: String {
        "$\(String(format: "%.2f", pendingAmount))"
    }

    var recentTransactions: [DepositTransaction] {
        Array(completedTransactions.prefix(5))
    }

    var hasTransactions: Bool {
        !allTransactions.isEmpty
    }

    init() {
        // Initialize with empty account - will be populated from Alpaca
        self.cashAccount = CashAccount(
            userId: UUID(),
            balance: 0,
            totalDeposited: 0,
            kycStatus: .verified,
            verificationLevel: .full
        )
    }

    func loadData() {
        Task {
            await fetchAlpacaAccountData()
        }
    }

    func refreshData() async {
        refreshing = true
        await fetchAlpacaAccountData()
        refreshing = false
    }
    
    private func fetchAlpacaAccountData() async {
        guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
            print("❌ No Alpaca account ID found")
            errorMessage = "No account found. Please sign up first."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch Account Details from Alpaca
            print("📊 Fetching Alpaca account details...")
            let account = try await alpacaService.fetchAccountDetails(accountId: accountId)
            
            let cashValue = account.cashValue
            let buyingPower = account.buyingPowerValue
            
            print("💰 Cash Balance: $\(cashValue)")
            print("💳 Buying Power: $\(buyingPower)")
            
            // Update cash account with real data
            self.cashAccount = CashAccount(
                id: self.cashAccount.id,
                userId: self.cashAccount.userId,
                balance: cashValue,
                currency: "USD",
                dailyDepositLimit: 50000,
                monthlyDepositLimit: 200000,
                totalDeposited: cashValue, // We don't have historical data, use current
                totalWithdrawn: 0,
                kycStatus: .verified,
                verificationLevel: .full,
                createdAt: self.cashAccount.createdAt,
                updatedAt: Date()
            )
            
            // 2. Fetch Transfer History from Alpaca
            print("📋 Fetching transfer history...")
            let transfers = try await alpacaService.getTransfers(accountId: accountId)
            
            var completed: [DepositTransaction] = []
            var pending: [DepositTransaction] = []
            
            for transfer in transfers {
                let amount = Double(transfer["amount"] as? String ?? "0") ?? 0
                let direction = transfer["direction"] as? String ?? "INCOMING"
                let status = transfer["status"] as? String ?? "COMPLETE"
                let createdAtString = transfer["created_at"] as? String ?? ""
                
                // Parse date
                let dateFormatter = ISO8601DateFormatter()
                let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
                
                let transaction = DepositTransaction(
                    accountId: self.cashAccount.id,
                    amount: amount,
                    paymentMethod: .wireTransfer,
                    estimatedSettlementTime: "1-2 business days",
                    createdAt: createdAt
                )
                
                if status == "COMPLETE" || status == "APPROVED" {
                    completed.append(transaction)
                } else if status == "PENDING" || status == "QUEUED" {
                    pending.append(transaction)
                }
            }
            
            self.completedTransactions = completed.sorted { $0.createdAt > $1.createdAt }
            self.pendingTransactions = pending.sorted { $0.createdAt > $1.createdAt }
            self.allTransactions = (completed + pending).sorted { $0.createdAt > $1.createdAt }
            
            print("✅ Loaded \(completed.count) completed and \(pending.count) pending transfers")
            
        } catch {
            print("❌ Failed to fetch Alpaca data: \(error)")
            errorMessage = "Failed to load account data"
        }
        
        isLoading = false
    }

    func showDepositFlow() {
        showingDepositFlow = true
    }

    func showWithdrawFlow() {
        showingWithdrawFlow = true
    }

    func handleDepositCompleted(_ transaction: DepositTransaction) {
        // Refresh data from Alpaca after deposit
        Task {
            await fetchAlpacaAccountData()
        }
    }
}