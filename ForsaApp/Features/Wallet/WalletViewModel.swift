//
//  WalletViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import Foundation
import SwiftUI

/// ViewModel responsible for managing wallet/cash reserve data and operations
@MainActor
class WalletViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var cashAccount: CashAccount
    @Published var allTransactions: [DepositTransaction] = []
    @Published var pendingTransactions: [DepositTransaction] = []
    @Published var completedTransactions: [DepositTransaction] = []

    @Published var showingDepositFlow = false
    @Published var showingWithdrawFlow = false

    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var hasLoadedOnce = false
    
    @Published var buyingPower: Double = 0
    
    // MARK: - Private Properties
    
    private let alpacaService = AlpacaTradingService.shared

    // MARK: - Computed Properties
    
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
    
    var hasPendingTransactions: Bool {
        !pendingTransactions.isEmpty
    }

    // MARK: - Init
    
    init() {
        self.cashAccount = CashAccount(
            userId: UUID(),
            balance: 0,
            totalDeposited: 0,
            kycStatus: .verified,
            verificationLevel: .full
        )
    }

    // MARK: - Public Methods
    
    func loadData() {
        Task {
            await fetchAlpacaAccountData()
        }
    }

    func refreshData() async {
        isRefreshing = true
        await fetchAlpacaAccountData()
        isRefreshing = false
    }
    
    func showDepositFlow() {
        showingDepositFlow = true
    }

    func showWithdrawFlow() {
        showingWithdrawFlow = true
    }

    func handleDepositCompleted(_ transaction: DepositTransaction) {
        Task {
            await fetchAlpacaAccountData()
        }
    }
    
    func clearError() {
        withAnimation(.easeOut(duration: 0.2)) {
            errorMessage = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchAlpacaAccountData() async {
        guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
            errorMessage = WalletStrings.noAccountFound
            hasLoadedOnce = true
            return
        }

        // Only show loading indicator on initial load, not on refresh
        if !hasLoadedOnce {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            let account = try await alpacaService.fetchAccountDetails(accountId: accountId)
            
            let cashValue = account.cashValue
            let buyingPowerValue = account.buyingPowerValue
            
            self.buyingPower = buyingPowerValue
            
            let transfers = try await alpacaService.getTransfers(accountId: accountId)
            
            var completed: [DepositTransaction] = []
            var pending: [DepositTransaction] = []
            var totalDeposited: Double = 0
            var totalWithdrawn: Double = 0
            
            for transfer in transfers {
                let amount = Double(transfer["amount"] as? String ?? "0") ?? 0
                let direction = transfer["direction"] as? String ?? "INCOMING"
                let status = transfer["status"] as? String ?? "COMPLETE"
                let createdAtString = transfer["created_at"] as? String ?? ""
                
                let dateFormatter = ISO8601DateFormatter()
                let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
                
                let transaction = DepositTransaction(
                    accountId: self.cashAccount.id,
                    amount: amount,
                    currency: "USD",
                    paymentMethod: direction == "INCOMING" ? .wireTransfer : .wireTransfer,
                    estimatedSettlementTime: "1-2 business days",
                    createdAt: createdAt
                )
                
                switch status.uppercased() {
                case "COMPLETE", "APPROVED":
                    completed.append(transaction)
                    if direction.uppercased() == "INCOMING" {
                        totalDeposited += amount
                    } else {
                        totalWithdrawn += amount
                    }
                case "QUEUED", "PENDING", "SENT_TO_CLEARING":
                    pending.append(transaction)
                default:
                    break
                }
            }
            
            self.cashAccount = CashAccount(
                id: self.cashAccount.id,
                userId: self.cashAccount.userId,
                balance: cashValue,
                currency: "USD",
                dailyDepositLimit: 50000,
                monthlyDepositLimit: 200000,
                totalDeposited: totalDeposited,
                totalWithdrawn: totalWithdrawn,
                kycStatus: .verified,
                verificationLevel: .full,
                createdAt: self.cashAccount.createdAt,
                updatedAt: Date()
            )
            
            self.completedTransactions = completed.sorted { $0.createdAt > $1.createdAt }
            self.pendingTransactions = pending.sorted { $0.createdAt > $1.createdAt }
            self.allTransactions = (completed + pending).sorted { $0.createdAt > $1.createdAt }
            
            hasLoadedOnce = true
            
        } catch {
            // Only show error message if this is the initial load (no data yet)
            // During refresh, silently fail to avoid disrupting the user experience
            if !hasLoadedOnce {
                errorMessage = WalletStrings.failedToLoadData
            }
            hasLoadedOnce = true
        }

        isLoading = false
    }
}
