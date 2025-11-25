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
        // Initial empty state
    }

    func loadData(user: User?) {
        guard let user = user else { return }
        
        // For now, we'll use the user's totalPortfolioValue if available, or calculate from goals/holdings if we had them.
        // Since we are moving away from "Goals" as the primary driver, we might want to rely on the User object's aggregated stats
        // or fetch a Portfolio object.
        // For this refactor, let's assume the User object has the latest stats or we calculate from a "Main Portfolio".
        
        self.totalPortfolioValue = user.totalPortfolioValue
        self.cashBalance = user.cashBalance
        self.totalGainLoss = user.totalGainLoss
        self.totalGainLossPercentage = user.totalGainLossPercentage
        self.totalDividends = 0 // Placeholder, or add to User model if needed
        
        // If values are zero (e.g. new user), let's mock some data for the "Rich Aesthetics" demo if needed,
        // but strictly speaking we should show real data.
        // However, the user asked to "polish the home page", so let's ensure we have data to show.
        
        if self.totalPortfolioValue == 0 && self.cashBalance == 0 {
             // Fallback for demo purposes if user is empty
             // self.loadPortfolioSummary() // Uncomment to force demo data
        }
        
        generateChartData()
    }
    
    @MainActor
    func refreshData(user: User?) async {
        isLoading = true

        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        loadData(user: user)
        isLoading = false
    }

    private func loadPortfolioSummary() {
        totalPortfolioValue = 25420.50
        totalInvested = 22580.20
        totalGainLoss = 2840.30
        totalGainLossPercentage = 12.6
        cashBalance = 5000.00
    }

    private func generateChartData() {
        let calendar = Calendar.current
        let now = Date()
        var data: [ChartDataPoint] = []

        let baseValue = totalPortfolioValue > 0 ? totalPortfolioValue * 0.9 : 10000 // Fallback for empty
        let currentValue = totalPortfolioValue > 0 ? totalPortfolioValue : 10000

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