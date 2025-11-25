//
//  DashboardViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var totalPortfolioValue: Double = 0
    @Published var totalInvested: Double = 0
    @Published var totalGainLoss: Double = 0
    @Published var totalGainLossPercentage: Double = 0
    @Published var totalDividends: Double = 0
    @Published var cashBalance: Double = 0
    @Published var chartData: [ChartDataPoint] = []
    @Published var selectedTimeframe: TimeFrame = .oneWeek
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Alpaca Integration
    @Published var accountId: String?
    @Published var needsAccountCreation = false
    
    private let alpacaService = AlpacaTradingService.shared
    private let currencyService = CurrencyService.shared
    
    var isPortfolioPositive: Bool {
        totalGainLoss >= 0
    }
    
    var portfolioChangeText: String {
        let sign = totalGainLoss >= 0 ? "+" : ""
        let amount = currencyService.formatUSD(abs(totalGainLoss))
        let percentage = String(format: "%.2f", abs(totalGainLossPercentage))
        return "\(sign)\(amount) (\(sign)\(percentage)%)"
    }
    
    var totalGainLossText: String {
        let sign = totalGainLoss >= 0 ? "+" : ""
        return "\(sign)\(currencyService.formatUSD(abs(totalGainLoss)))"
    }
    
    var portfolioValueText: String {
        currencyService.formatUSD(totalPortfolioValue)
    }
    
    var cashBalanceText: String {
        currencyService.formatUSD(cashBalance)
    }
    
    var availableBalanceText: String {
        currencyService.formatUSD(cashBalance)
    }
    
    init() {
        Task { await checkAccountStatus() }
    }
    
    @MainActor
    func checkAccountStatus() async {
        // 1. Initialize Service (Check keys)
        _ = await alpacaService.initializeSession()
        
        // Check the actual mode from the service (not the return value which indicates success)
        if alpacaService.isTradingMode {
            // Keys are for Trading API -> No creation needed
            if let account = alpacaService.currentAccount {
                self.accountId = account.id
                UserDefaults.standard.set(account.id, forKey: "alpaca_account_id")
            }
            self.needsAccountCreation = false
            await refreshData()
        } else {
            // Broker Mode: Check if we have a stored ID
            if let id = UserDefaults.standard.string(forKey: "alpaca_account_id") {
                self.accountId = id
                self.needsAccountCreation = false
                await refreshData()
            } else {
                // If missing, we prompt creation (but user likely should have done this at signup)
                // But for existing users or dev testing, we might still need this.
                // However, user requested: "create account on the first page... then having create account button again in the home page. fix this."
                // So we likely shouldn't show it if we can avoid it, OR the user means "remove the button".
                // Let's keep the state logic but maybe the View won't show the button if we are clever.
                self.needsAccountCreation = true
            }
        }
    }
    
    @MainActor
    func createAccountForUser(user: User) async {
        isLoading = true
        do {
            let id = try await alpacaService.createAccount(
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName
            )
            UserDefaults.standard.set(id, forKey: "alpaca_account_id")
            self.accountId = id
            self.needsAccountCreation = false
            await refreshData()
        } catch {
            self.errorMessage = "Failed to create account: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    func refreshData() async {
        guard let accountId = accountId else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch Account Details
            let account = try await alpacaService.fetchAccountDetails(accountId: accountId)
            self.totalPortfolioValue = account.equityValue
            self.cashBalance = account.cashValue
            // Buying power or other stats can be added
            
            // 2. Fetch Positions to calculate Total Invested (Cost Basis)
            let positions = try await alpacaService.fetchPositions(accountId: accountId)
            let totalCostBasis = positions.reduce(0.0) { $0 + (Double($1.costBasis) ?? 0) }
            self.totalInvested = totalCostBasis
            
            // Calculate Gain/Loss
            // Equity - Cost Basis (approximate, doesn't account for realized gains/losses fully in this simple view)
            // Better to use Account's equity - cash? No.
            // Total Gain/Loss usually comes from (Equity - Net Deposits).
            // For simplicity in this MVP, we compare Current Equity vs Cost Basis of open positions + Cash? No.
            // We will use (Equity - TotalInvested) if we assume Cash is uninvested.
            // Actually, let's rely on positions for "Unrealized P&L" which is what users usually see for "Portfolio Performance".
            // Or use Alpaca's `equity - last_equity` for day change.
            
            // Let's sum up Unrealized PL from positions
            let unrealizedPL = positions.reduce(0.0) { $0 + ((Double($1.marketValue ?? "0") ?? 0) - (Double($1.costBasis) ?? 0)) }
            self.totalGainLoss = unrealizedPL
            self.totalGainLossPercentage = totalCostBasis > 0 ? (unrealizedPL / totalCostBasis) * 100 : 0
            
            // 3. Fetch History for Chart
            let points = try await alpacaService.fetchPortfolioHistory(
                accountId: accountId,
                period: mapTimeframeToPeriod(selectedTimeframe),
                timeframe: mapTimeframeToInterval(selectedTimeframe)
            )
            self.chartData = points
            
        } catch {
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("Dashboard Data Error: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func depositFunds(amountKD: Double) async {
        guard let accountId = accountId else { return }
        let amountUSD = currencyService.convertKWDtoUSD(amountKD)
        
        isLoading = true
        do {
            try await alpacaService.fundAccount(accountId: accountId, amount: amountUSD)
            await refreshData()
        } catch {
            self.errorMessage = "Deposit failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // MARK: - Helpers
    
    private func mapTimeframeToPeriod(_ timeframe: TimeFrame) -> String {
        switch timeframe {
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        case .threeMonths: return "3M" // Alpaca supports 3M
        case .oneYear: return "1A" // 1A for 1 Year
        }
    }
    
    private func mapTimeframeToInterval(_ timeframe: TimeFrame) -> String {
        switch timeframe {
        case .oneDay: return "5Min"
        case .oneWeek: return "1H"
        case .oneMonth: return "1D"
        case .threeMonths: return "1D"
        case .oneYear: return "1D"
        }
    }
}

enum TimeFrame: CaseIterable {
    case oneDay
    case oneWeek
    case oneMonth
    case threeMonths
    case oneYear

    var displayName: String {
        switch self {
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .oneYear: return "1Y"
        }
    }
    
    var days: Int {
        switch self {
        case .oneDay: return 1
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .oneYear: return 365
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
