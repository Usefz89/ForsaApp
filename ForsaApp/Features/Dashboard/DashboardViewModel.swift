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
    @Published var buyingPower: Double = 0  // Actual available funds for trading
    @Published var chartData: [ChartDataPoint] = []
    @Published var selectedTimeframe: TimeFrame = .oneWeek
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedOnce = false  // Track if we've loaded data at least once
    
    // Alpaca Integration
    @Published var accountId: String?
    @Published var needsAccountCreation = false
    @Published var positions: [AlpacaPosition] = []
    
    // Order tracking - critical for understanding true investment state
    @Published var pendingOrders: [OpenOrder] = []
    @Published var pendingOrdersSummary: PendingOrdersSummary = .empty
    
    // Computed property to check if user has investments
    var hasPositions: Bool {
        !positions.isEmpty
    }
    
    // Check if there are pending orders (funds reserved but not yet invested)
    var hasPendingOrders: Bool {
        !pendingOrders.isEmpty
    }
    
    // The actual investment state considering positions, orders, and buying power
    var investmentState: InvestmentState {
        // If there are pending orders, funds are reserved
        if hasPendingOrders {
            return .ordersPending(summary: pendingOrdersSummary)
        }
        
        // Check if user can actually invest (using buying power, not cash)
        if buyingPower >= 1.0 {
            return .canInvest(availableAmount: buyingPower)
        }
        
        // Has cash but no buying power means funds are reserved elsewhere
        if cashBalance >= 1.0 && buyingPower < 1.0 {
            return .ordersPending(summary: pendingOrdersSummary)
        }
        
        return .insufficientFunds
    }
    
    // Check if user can invest - now uses buying power and checks pending orders
    var canInvestNow: Bool {
        buyingPower >= 1.0 && !hasPositions && !hasPendingOrders
    }
    
    // Amount available for new investments
    var availableForInvestment: Double {
        buyingPower
    }
    
    private let alpacaService = AlpacaTradingService.shared
    private let currencyService = CurrencyService.shared
    
    var isPortfolioPositive: Bool {
        totalGainLoss >= 0
    }
    
    var portfolioChangeText: String {
        let sign = totalGainLoss >= 0 ? "+" : "-"
        let amount = currencyService.formatUSD(abs(totalGainLoss))
        let percentage = String(format: "%.2f", abs(totalGainLossPercentage))
        return "\(sign)\(amount) (\(sign)\(percentage)%)"
    }
    
    var totalGainLossText: String {
        let sign = totalGainLoss >= 0 ? "+" : "-"
        return "\(sign)\(currencyService.formatUSD(abs(totalGainLoss)))"
    }
    
    var portfolioValueText: String {
        // Show actual portfolio value (can be negative)
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
        // Initialize Broker API session
        let isConnected = await alpacaService.initializeSession()
        
        if !isConnected {
            self.errorMessage = "Unable to connect to Alpaca. Please check your internet connection."
        }
        
        // Check if we have a stored account ID
        if let id = UserDefaults.standard.string(forKey: "alpaca_account_id") {
            self.accountId = id
            self.needsAccountCreation = false
            await refreshData()
        } else {
            // No account ID stored - user needs to create an account
            self.needsAccountCreation = true
            self.hasLoadedOnce = true  // No data to load, mark as complete
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
            // 1. Fetch Account Details (includes cash AND buying power)
            let account = try await alpacaService.fetchAccountDetails(accountId: accountId)
            self.cashBalance = account.cashValue
            self.buyingPower = account.buyingPowerValue  // Critical: track actual trading power
            
            // 2. Fetch Positions to calculate Total Invested (Cost Basis) and Market Value
            let fetchedPositions = try await alpacaService.fetchPositions(accountId: accountId)
            self.positions = fetchedPositions
            
            // 3. Fetch Open/Pending Orders - critical for understanding true state
            do {
                let openOrders = try await alpacaService.fetchOpenOrders(accountId: accountId)
                self.pendingOrders = openOrders
                self.pendingOrdersSummary = PendingOrdersSummary(orders: openOrders)
                
                if !openOrders.isEmpty {
                    print("⏳ Pending Orders: \(openOrders.count)")
                    for order in openOrders {
                        print("   - \(order.symbol): \(order.displayAmount) (\(order.statusDisplayName))")
                    }
                }
            } catch {
                print("⚠️ Failed to fetch open orders: \(error)")
                self.pendingOrders = []
                self.pendingOrdersSummary = .empty
            }
            
            // Calculate totals from positions
            let totalCostBasis = fetchedPositions.reduce(0.0) { $0 + (Double($1.costBasis) ?? 0) }
            let totalMarketValue = fetchedPositions.reduce(0.0) { $0 + (Double($1.marketValue ?? "0") ?? 0) }
            
            self.totalInvested = totalCostBasis
            
            // Total Portfolio Value = Market Value of Positions + Cash
            // If account.equityValue is available and > 0, use it; otherwise calculate from positions
            let accountEquity = account.equityValue
            if accountEquity > 0 {
                self.totalPortfolioValue = accountEquity
            } else {
                // Calculate from positions + cash
                self.totalPortfolioValue = totalMarketValue + self.cashBalance
            }
            
            // Calculate Gain/Loss (Unrealized P&L from positions)
            let unrealizedPL = totalMarketValue - totalCostBasis
            self.totalGainLoss = unrealizedPL
            self.totalGainLossPercentage = totalCostBasis > 0 ? (unrealizedPL / totalCostBasis) * 100 : 0
            
            print("📊 Portfolio Summary:")
            print("   Cash: $\(String(format: "%.2f", self.cashBalance))")
            print("   Buying Power: $\(String(format: "%.2f", self.buyingPower))")
            print("   Pending Orders: \(self.pendingOrders.count)")
            print("   Invested (Cost Basis): $\(String(format: "%.2f", totalCostBasis))")
            print("   Market Value: $\(String(format: "%.2f", totalMarketValue))")
            print("   Total Portfolio Value: $\(String(format: "%.2f", self.totalPortfolioValue))")
            print("   Gain/Loss: $\(String(format: "%.2f", unrealizedPL))")
            print("   Can Invest Now: \(self.canInvestNow)")
            
            // 4. Fetch History for Chart
            let points = try await alpacaService.fetchPortfolioHistory(
                accountId: accountId,
                period: mapTimeframeToPeriod(selectedTimeframe),
                timeframe: mapTimeframeToInterval(selectedTimeframe)
            )
            self.chartData = points
            
            hasLoadedOnce = true
            
        } catch {
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("Dashboard Data Error: \(error)")
            hasLoadedOnce = true  // Mark as loaded even on error
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
