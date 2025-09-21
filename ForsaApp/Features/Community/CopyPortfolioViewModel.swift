//
//  CopyPortfolioViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

class CopyPortfolioViewModel: ObservableObject {
    @Published var portfolio: Portfolio?
    @Published var copyExactAllocations = true
    @Published var enableAutoRebalancing = true
    @Published var enableAutoSync = true
    @Published var rebalanceFrequency: RebalanceFrequency = .monthly
    @Published var initialInvestmentText = ""
    @Published var enableAutoInvest = false
    @Published var autoInvestAmountText = ""
    @Published var isCopying = false
    @Published var showingSuccess = false

    var initialInvestment: Double {
        Double(initialInvestmentText) ?? 0
    }

    var autoInvestAmount: Double {
        Double(autoInvestAmountText) ?? 0
    }

    var canCopyPortfolio: Bool {
        initialInvestment > 0
    }

    func setPortfolio(_ portfolio: Portfolio) {
        self.portfolio = portfolio
    }

    @MainActor
    func copyPortfolio() async {
        guard let portfolio = portfolio else { return }

        isCopying = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Create investment pie from portfolio
        let allocations = portfolio.holdings.map { holding in
            PieAllocation(
                stockId: holding.stockId,
                symbol: holding.symbol,
                name: holding.name,
                percentage: holding.allocation
            )
        }

        let copiedPie = InvestmentPie(
            name: "Copy of \(portfolio.name)",
            description: "\(portfolio.description ?? "") - Auto-synced with creator",
            allocations: allocations,
            totalInvested: initialInvestment,
            autoInvestEnabled: enableAutoInvest,
            autoInvestAmount: enableAutoInvest ? autoInvestAmount : nil,
            rebalanceFrequency: rebalanceFrequency
        )

        // In a real app, this would:
        // 1. Create the pie on the backend
        // 2. Set up auto-sync relationship
        // 3. Place initial orders
        // 4. Configure auto-invest if enabled

        print("Created copied pie: \(copiedPie.name)")
        print("Initial investment: $\(initialInvestment)")
        print("Auto-sync enabled: \(enableAutoSync)")
        print("Auto-invest: \(enableAutoInvest ? "$\(autoInvestAmount)/month" : "disabled")")

        isCopying = false
        showingSuccess = true
    }

    func presetInvestmentAmount(_ amount: Double) {
        initialInvestmentText = String(format: "%.0f", amount)
    }
}