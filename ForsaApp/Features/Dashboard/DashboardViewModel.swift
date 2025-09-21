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
    @Published var topHoldings: [Holding] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var chartData: [ChartDataPoint] = []
    @Published var selectedTimeframe: TimeFrame = .oneWeek
    @Published var isLoading = false

    var isPortfolioPositive: Bool {
        totalGainLoss >= 0
    }

    var portfolioChangeText: String {
        let sign = totalGainLoss >= 0 ? "+" : ""
        let amount = String(format: "%.2f", abs(totalGainLoss))
        let percentage = String(format: "%.2f", abs(totalGainLossPercentage))
        return "\(sign)$\(amount) (\(sign)\(percentage)%)"
    }

    var totalGainLossText: String {
        let sign = totalGainLoss >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.0f", abs(totalGainLoss)))"
    }

    init() {
        loadData()
    }

    func loadData() {
        // Load demo data
        loadPortfolioSummary()
        loadTopHoldings()
        loadRecentTransactions()
        generateChartData()
    }

    @MainActor
    func refreshData() async {
        isLoading = true

        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        loadData()
        isLoading = false
    }

    private func loadPortfolioSummary() {
        totalPortfolioValue = 25420.50
        totalInvested = 22580.20
        totalGainLoss = 2840.30
        totalGainLossPercentage = 12.6
        totalDividends = 485.75
    }

    private func loadTopHoldings() {
        let mockHoldings = [
            Holding(
                stockId: UUID(),
                symbol: "AAPL",
                name: "Apple Inc.",
                shares: 15.2543,
                averagePrice: 165.30,
                currentPrice: 175.43,
                allocation: 35.2
            ),
            Holding(
                stockId: UUID(),
                symbol: "MSFT",
                name: "Microsoft Corporation",
                shares: 8.7321,
                averagePrice: 285.50,
                currentPrice: 298.75,
                allocation: 28.7
            ),
            Holding(
                stockId: UUID(),
                symbol: "KFH",
                name: "Kuwait Finance House",
                shares: 250.0,
                averagePrice: 0.85,
                currentPrice: 0.92,
                allocation: 15.3
            ),
            Holding(
                stockId: UUID(),
                symbol: "GOOGL",
                name: "Alphabet Inc.",
                shares: 3.1234,
                averagePrice: 125.80,
                currentPrice: 132.45,
                allocation: 12.1
            )
        ]

        topHoldings = mockHoldings
    }

    private func loadRecentTransactions() {
        let calendar = Calendar.current
        let now = Date()

        let mockTransactions = [
            Transaction(
                type: .buy,
                stockId: UUID(),
                symbol: "AAPL",
                stockName: "Apple Inc.",
                shares: 2.5,
                pricePerShare: 175.43,
                totalAmount: 438.58,
                executedAt: now
            ),
            Transaction(
                type: .dividend,
                stockId: UUID(),
                symbol: "MSFT",
                stockName: "Microsoft Corporation",
                totalAmount: 12.50,
                executedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            Transaction(
                type: .sell,
                stockId: UUID(),
                symbol: "KFH",
                stockName: "Kuwait Finance House",
                shares: 100.0,
                pricePerShare: 0.92,
                totalAmount: 92.00,
                executedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            ),
            Transaction(
                type: .deposit,
                totalAmount: 1000.00,
                executedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now
            )
        ]

        recentTransactions = Array(mockTransactions.prefix(3))
    }

    private func generateChartData() {
        let calendar = Calendar.current
        let now = Date()
        var data: [ChartDataPoint] = []

        let baseValue = 22000.0
        let currentValue = totalPortfolioValue

        // Generate data points based on selected timeframe
        let days = selectedTimeframe.days
        let increment = (currentValue - baseValue) / Double(days)

        for i in 0...days {
            let date = calendar.date(byAdding: .day, value: -days + i, to: now) ?? now
            let randomVariation = Double.random(in: -200...200)
            let value = baseValue + (Double(i) * increment) + randomVariation

            data.append(ChartDataPoint(date: date, value: max(value, baseValue * 0.9)))
        }

        chartData = data
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