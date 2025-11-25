//
//  PortfolioDetailViewModel.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation
import Combine

class PortfolioDetailViewModel: ObservableObject {
    @Published var isInvesting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var accountCash: Double = 0
    
    private let alpacaService = AlpacaTradingService.shared
    private let currencyService = CurrencyService.shared
    
    @MainActor
    func loadAccountData() async {
        guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else { return }
        do {
            let account = try await alpacaService.fetchAccountDetails(accountId: accountId)
            self.accountCash = account.cashValue
        } catch {
            print("Failed to load account cash: \(error)")
        }
    }
    
    @MainActor
    func invest(amountKD: Double, riskLevel: RiskLevel) async {
        guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
            errorMessage = "No account found. Please create one in Dashboard."
            return
        }
        
        let amountUSD = currencyService.convertKWDtoUSD(amountKD)
        
        if amountUSD > accountCash {
            errorMessage = "Insufficient funds. You have \(currencyService.formatUSD(accountCash)) available."
            return
        }
        
        isInvesting = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await alpacaService.placeBasketOrder(accountId: accountId, amount: amountUSD, portfolio: riskLevel)
            successMessage = "Successfully invested \(currencyService.formatUSD(amountUSD)) in \(riskLevel.title)."
            // Refresh cash
            await loadAccountData()
        } catch {
            errorMessage = "Investment failed: \(error.localizedDescription)"
        }
        
        isInvesting = false
    }
}

