//
//  PiesViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation
import Combine

class PiesViewModel: ObservableObject {
    @Published var myPies: [InvestmentPie] = []
    @Published var communityPies: [Portfolio] = []
    @Published var piePerformances: [UUID: PiePerformance] = [:]
    @Published var isLoading = false
    @Published var showingCopySuccess = false
    @Published var cashAccount: CashAccount
    @Published var recentCashTransactions: [DepositTransaction] = []

    private let mockDataService = MockDataService.shared

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
        self.recentCashTransactions = generateMockCashTransactions()
    }

    var totalPieValue: Double {
        myPies.reduce(0) { $0 + $1.totalInvested }
    }

    var totalAutoInvest: Double {
        myPies.filter { $0.autoInvestEnabled }.reduce(0) { $0 + ($1.autoInvestAmount ?? 0) }
    }

    var averagePerformance: String {
        let performances = piePerformances.values
        guard !performances.isEmpty else { return "+0.0%" }

        let average = performances.reduce(0) { $0 + $1.percentage } / Double(performances.count)
        let sign = average >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", average))%"
    }

    var isAveragePositive: Bool {
        let performances = piePerformances.values
        guard !performances.isEmpty else { return true }

        let average = performances.reduce(0) { $0 + $1.percentage } / Double(performances.count)
        return average >= 0
    }

    func loadData() {
        // Load user's investment pies
        myPies = mockDataService.investmentPies

        // Load community portfolios as pies
        communityPies = mockDataService.communityPortfolios

        // Generate mock performance data
        generatePerformanceData()

        // Refresh cash account data (in real app, would fetch from API)
        refreshCashAccount()
    }

    func getCreator(for pie: Portfolio) -> User? {
        return mockDataService.demoUsers.first { $0.id == pie.creatorId }
    }

    func getPerformance(for pie: InvestmentPie) -> PiePerformance {
        return piePerformances[pie.id] ?? PiePerformance(totalReturn: 0, percentage: 0, isPositive: true)
    }

    func getPerformance(for pie: Portfolio) -> PiePerformance {
        return piePerformances[pie.id] ?? PiePerformance(
            totalReturn: pie.totalGainLoss,
            percentage: pie.totalGainLossPercentage,
            isPositive: pie.isPositive
        )
    }

    func copyPie(_ portfolio: Portfolio) {
        // Convert portfolio to investment pie
        let allocations = portfolio.holdings.map { holding in
            PieAllocation(
                stockId: holding.stockId,
                symbol: holding.symbol,
                name: holding.name,
                percentage: holding.allocation
            )
        }

        let newPie = InvestmentPie(
            name: "Copy of \(portfolio.name)",
            description: portfolio.description,
            allocations: allocations,
            totalInvested: 0,
            autoInvestEnabled: false,
            rebalanceFrequency: .monthly
        )

        // Add to user's pies
        myPies.append(newPie)

        // Generate performance for the new pie
        piePerformances[newPie.id] = PiePerformance(
            totalReturn: 0,
            percentage: Double.random(in: -5...15),
            isPositive: Bool.random()
        )

        showingCopySuccess = true

        // In a real app, this would save to backend
        print("Copied pie: \(newPie.name)")
    }

    func copyPie(_ pie: InvestmentPie) {
        let copiedPie = InvestmentPie(
            name: "Copy of \(pie.name)",
            description: pie.description,
            allocations: pie.allocations,
            totalInvested: 0,
            autoInvestEnabled: false,
            rebalanceFrequency: pie.rebalanceFrequency
        )

        myPies.append(copiedPie)
        showingCopySuccess = true
    }

    func deletePie(_ pie: InvestmentPie) {
        myPies.removeAll { $0.id == pie.id }
        piePerformances.removeValue(forKey: pie.id)
    }

    private func generatePerformanceData() {
        // Generate performance for user's pies
        for pie in myPies {
            let performance = generateRandomPerformance()
            piePerformances[pie.id] = performance
        }

        // Performance for community pies is already in the portfolio model
        for pie in communityPies {
            piePerformances[pie.id] = PiePerformance(
                totalReturn: pie.totalGainLoss,
                percentage: pie.totalGainLossPercentage,
                isPositive: pie.isPositive
            )
        }
    }

    private func generateRandomPerformance() -> PiePerformance {
        let percentage = Double.random(in: -8...20)
        let totalReturn = Double.random(in: -500...2000)

        return PiePerformance(
            totalReturn: totalReturn,
            percentage: percentage,
            isPositive: percentage >= 0
        )
    }

    private func refreshCashAccount() {
        // In a real app, this would fetch updated cash account data from API
        // For now, just simulate some changes
    }

    private func generateMockCashTransactions() -> [DepositTransaction] {
        let transactions: [DepositTransaction] = [
            DepositTransaction(
                accountId: UUID(),
                amount: 1000,
                paymentMethod: .knet,
                estimatedSettlementTime: "Instant",
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            DepositTransaction(
                accountId: UUID(),
                amount: 500,
                paymentMethod: .applePay,
                estimatedSettlementTime: "Instant",
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            DepositTransaction(
                accountId: UUID(),
                amount: 250,
                paymentMethod: .creditCard,
                processingFee: 7.25,
                estimatedSettlementTime: "Instant",
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            )
        ]

        return transactions
    }
}

// MARK: - Copy Trading Service
class CopyTradingService: ObservableObject {
    @Published var copiedPies: [CopiedPie] = []
    @Published var isAutoSyncEnabled = true

    func copyPortfolio(_ portfolio: Portfolio, withAmount amount: Double) -> InvestmentPie {
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
            description: "Copied from \(portfolio.name) - Auto-synced",
            allocations: allocations,
            totalInvested: amount,
            autoInvestEnabled: true,
            autoInvestAmount: amount * 0.1, // 10% monthly auto-invest
            rebalanceFrequency: .monthly
        )

        // Track as copied pie for sync
        let copiedPieRecord = CopiedPie(
            pieId: copiedPie.id,
            originalPortfolioId: portfolio.id,
            creatorId: portfolio.creatorId,
            lastSyncDate: Date(),
            autoSyncEnabled: true
        )

        copiedPies.append(copiedPieRecord)

        return copiedPie
    }

    func syncPie(_ pieId: UUID) {
        // In a real app, this would sync with the original portfolio
        if let index = copiedPies.firstIndex(where: { $0.pieId == pieId }) {
            copiedPies[index].lastSyncDate = Date()
        }
    }

    func stopSyncing(_ pieId: UUID) {
        if let index = copiedPies.firstIndex(where: { $0.pieId == pieId }) {
            copiedPies[index].autoSyncEnabled = false
        }
    }
}

struct CopiedPie {
    let pieId: UUID
    let originalPortfolioId: UUID
    let creatorId: UUID
    var lastSyncDate: Date
    var autoSyncEnabled: Bool
}