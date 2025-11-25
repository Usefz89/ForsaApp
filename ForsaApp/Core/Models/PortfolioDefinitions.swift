import Foundation
import SwiftUI

struct AssetAllocation: Identifiable, Codable {
    let id: UUID
    let ticker: String
    let name: String
    let fullName: String
    let percentage: Double // 0.0 to 1.0
    let assetClass: AssetClass
    let fallbackTicker: String?
    let expenseRatio: Double // Annual expense ratio
    
    init(
        id: UUID = UUID(),
        ticker: String,
        name: String,
        fullName: String = "",
        percentage: Double,
        assetClass: AssetClass = .equity,
        fallbackTicker: String? = nil,
        expenseRatio: Double = 0.0
    ) {
        self.id = id
        self.ticker = ticker
        self.name = name
        self.fullName = fullName.isEmpty ? name : fullName
        self.percentage = percentage
        self.assetClass = assetClass
        self.fallbackTicker = fallbackTicker
        self.expenseRatio = expenseRatio
    }
}

enum AssetClass: String, Codable, CaseIterable {
    case equity = "Equity"
    case sukuk = "Sukuk"
    case gold = "Gold"
    case reit = "REIT"
    case international = "International"
    case emergingMarkets = "Emerging Markets"
    
    var color: Color {
        switch self {
        case .equity: return .primaryBlue
        case .sukuk: return .primaryGreen
        case .gold: return .warningYellow
        case .reit: return .primaryPurple
        case .international: return .primaryOrange
        case .emergingMarkets: return .errorRed
        }
    }
    
    var icon: String {
        switch self {
        case .equity: return "chart.line.uptrend.xyaxis"
        case .sukuk: return "building.columns.fill"
        case .gold: return "bitcoinsign.circle.fill"
        case .reit: return "building.2.fill"
        case .international: return "globe"
        case .emergingMarkets: return "globe.asia.australia.fill"
        }
    }
}

// MARK: - Portfolio Statistics

struct PortfolioStatistics {
    let expectedReturn: Double      // Annual expected return
    let standardDeviation: Double   // Volatility
    let sharpeRatio: Double         // Risk-adjusted return
    let maxDrawdown: Double         // Historical max drawdown
    let equityPercentage: Double    // Total equity exposure
    let fixedIncomePercentage: Double // Total fixed income/sukuk
    let alternativesPercentage: Double // Gold, REITs, etc.
}

extension RiskLevel {
    
    // MARK: - Display Properties
    
    var icon: String {
        switch self {
        case .conservative: return "shield.fill"
        case .moderate: return "scale.3d"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .aggressive: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .conservative: return .primaryBlue
        case .moderate: return .primaryGreen
        case .growth: return .primaryOrange
        case .aggressive: return .errorRed
        }
    }
    
    var riskScore: Int {
        switch self {
        case .conservative: return 1
        case .moderate: return 2
        case .growth: return 3
        case .aggressive: return 4
        }
    }
    
    // MARK: - Financial Metrics (Based on historical data and financial theory)
    
    var statistics: PortfolioStatistics {
        switch self {
        case .conservative:
            return PortfolioStatistics(
                expectedReturn: 0.045,   // 4.5% expected annual return
                standardDeviation: 0.055, // 5.5% volatility
                sharpeRatio: 0.55,
                maxDrawdown: -0.08,      // -8% max drawdown
                equityPercentage: 0.15,
                fixedIncomePercentage: 0.65,
                alternativesPercentage: 0.20
            )
        case .moderate:
            return PortfolioStatistics(
                expectedReturn: 0.065,   // 6.5% expected annual return
                standardDeviation: 0.095, // 9.5% volatility
                sharpeRatio: 0.58,
                maxDrawdown: -0.15,      // -15% max drawdown
                equityPercentage: 0.45,
                fixedIncomePercentage: 0.35,
                alternativesPercentage: 0.20
            )
        case .growth:
            return PortfolioStatistics(
                expectedReturn: 0.085,   // 8.5% expected annual return
                standardDeviation: 0.135, // 13.5% volatility
                sharpeRatio: 0.52,
                maxDrawdown: -0.25,      // -25% max drawdown
                equityPercentage: 0.75,
                fixedIncomePercentage: 0.10,
                alternativesPercentage: 0.15
            )
        case .aggressive:
            return PortfolioStatistics(
                expectedReturn: 0.105,   // 10.5% expected annual return
                standardDeviation: 0.185, // 18.5% volatility
                sharpeRatio: 0.49,
                maxDrawdown: -0.35,      // -35% max drawdown
                equityPercentage: 0.95,
                fixedIncomePercentage: 0.0,
                alternativesPercentage: 0.05
            )
        }
    }
    
    var averageReturn: String {
        let stats = statistics
        let low = (stats.expectedReturn - 0.015) * 100
        let high = (stats.expectedReturn + 0.015) * 100
        return "\(String(format: "%.1f", low))% - \(String(format: "%.1f", high))%"
    }
    
    var standardDeviation: String {
        return "\(String(format: "%.1f", statistics.standardDeviation * 100))%"
    }
    
    var detailedDescription: String {
        switch self {
        case .conservative:
            return "Designed for investors who prioritize capital preservation over growth. This portfolio focuses on stable, income-generating Sukuk (Islamic bonds) with minimal equity exposure. Ideal for short-term goals (1-3 years) or risk-averse investors."
        case .moderate:
            return "A balanced approach combining growth potential with stability. This portfolio splits between Sharia-compliant equities and Sukuk, suitable for medium-term goals (3-7 years) and investors comfortable with moderate market fluctuations."
        case .growth:
            return "Focused on long-term capital appreciation with majority equity allocation. Suitable for investors with 7-15 year horizons who can tolerate significant market volatility in pursuit of higher returns."
        case .aggressive:
            return "Maximum growth strategy with almost full equity exposure across global Islamic markets. Designed for experienced investors with 15+ year horizons who can withstand substantial short-term losses for potential long-term gains."
        }
    }
    
    var suitableFor: [String] {
        switch self {
        case .conservative:
            return ["Emergency fund building", "Short-term goals (1-3 years)", "Near-retirement investors", "Risk-averse individuals"]
        case .moderate:
            return ["Medium-term goals (3-7 years)", "First-time investors", "Balanced risk tolerance", "General wealth building"]
        case .growth:
            return ["Long-term goals (7-15 years)", "Retirement savings", "Education funds", "Experienced investors"]
        case .aggressive:
            return ["Very long-term goals (15+ years)", "Young investors", "High risk tolerance", "Maximum growth seekers"]
        }
    }
    
    var timeHorizon: String {
        switch self {
        case .conservative: return "1-3 years"
        case .moderate: return "3-7 years"
        case .growth: return "7-15 years"
        case .aggressive: return "15+ years"
        }
    }

    // MARK: - Portfolio Allocations
    // Based on Modern Portfolio Theory adapted for Sharia-compliant investing

    var allocations: [AssetAllocation] {
        switch self {
        case .conservative:
            // Capital preservation focus: 65% Sukuk, 15% Equity, 20% Gold
            return [
                AssetAllocation(
                    ticker: "SPSK",
                    name: "Global Sukuk",
                    fullName: "SP Funds Dow Jones Global Sukuk ETF",
                    percentage: 0.50,
                    assetClass: .sukuk,
                    fallbackTicker: "BND",
                    expenseRatio: 0.0055
                ),
                AssetAllocation(
                    ticker: "GLDM",
                    name: "Gold",
                    fullName: "SPDR Gold MiniShares Trust",
                    percentage: 0.20,
                    assetClass: .gold,
                    fallbackTicker: "GLD",
                    expenseRatio: 0.001
                ),
                AssetAllocation(
                    ticker: "SPUS",
                    name: "US Sharia Equity",
                    fullName: "SP Funds S&P 500 Sharia Industry Exclusions ETF",
                    percentage: 0.15,
                    assetClass: .equity,
                    fallbackTicker: "HLAL",
                    expenseRatio: 0.0049
                ),
                AssetAllocation(
                    ticker: "SPRE",
                    name: "Sukuk Reserve",
                    fullName: "SP Funds Short-Term Sukuk ETF",
                    percentage: 0.15,
                    assetClass: .sukuk,
                    fallbackTicker: "SHY",
                    expenseRatio: 0.0045
                )
            ]
            
        case .moderate:
            // Balanced: 35% Sukuk, 45% Equity, 20% Alternatives
            return [
                AssetAllocation(
                    ticker: "SPUS",
                    name: "US Sharia Equity",
                    fullName: "SP Funds S&P 500 Sharia Industry Exclusions ETF",
                    percentage: 0.30,
                    assetClass: .equity,
                    fallbackTicker: "HLAL",
                    expenseRatio: 0.0049
                ),
                AssetAllocation(
                    ticker: "SPSK",
                    name: "Global Sukuk",
                    fullName: "SP Funds Dow Jones Global Sukuk ETF",
                    percentage: 0.25,
                    assetClass: .sukuk,
                    fallbackTicker: "BND",
                    expenseRatio: 0.0055
                ),
                AssetAllocation(
                    ticker: "UMMA",
                    name: "Global Islamic Equity",
                    fullName: "Wahed Dow Jones Islamic World ETF",
                    percentage: 0.15,
                    assetClass: .international,
                    fallbackTicker: "VEU",
                    expenseRatio: 0.0065
                ),
                AssetAllocation(
                    ticker: "GLDM",
                    name: "Gold",
                    fullName: "SPDR Gold MiniShares Trust",
                    percentage: 0.15,
                    assetClass: .gold,
                    fallbackTicker: "GLD",
                    expenseRatio: 0.001
                ),
                AssetAllocation(
                    ticker: "SPRE",
                    name: "Sukuk Reserve",
                    fullName: "SP Funds Short-Term Sukuk ETF",
                    percentage: 0.10,
                    assetClass: .sukuk,
                    fallbackTicker: "SHY",
                    expenseRatio: 0.0045
                ),
                AssetAllocation(
                    ticker: "VNQ",
                    name: "Real Estate",
                    fullName: "Vanguard Real Estate ETF",
                    percentage: 0.05,
                    assetClass: .reit,
                    fallbackTicker: "IYR",
                    expenseRatio: 0.0012
                )
            ]
            
        case .growth:
            // Growth focus: 10% Sukuk, 75% Equity, 15% Alternatives
            return [
                AssetAllocation(
                    ticker: "SPUS",
                    name: "US Sharia Equity",
                    fullName: "SP Funds S&P 500 Sharia Industry Exclusions ETF",
                    percentage: 0.40,
                    assetClass: .equity,
                    fallbackTicker: "HLAL",
                    expenseRatio: 0.0049
                ),
                AssetAllocation(
                    ticker: "UMMA",
                    name: "Global Islamic Equity",
                    fullName: "Wahed Dow Jones Islamic World ETF",
                    percentage: 0.25,
                    assetClass: .international,
                    fallbackTicker: "VEU",
                    expenseRatio: 0.0065
                ),
                AssetAllocation(
                    ticker: "HLAL",
                    name: "US Shariah ETF",
                    fullName: "Wahed FTSE USA Shariah ETF",
                    percentage: 0.10,
                    assetClass: .equity,
                    fallbackTicker: "SPY",
                    expenseRatio: 0.005
                ),
                AssetAllocation(
                    ticker: "SPSK",
                    name: "Global Sukuk",
                    fullName: "SP Funds Dow Jones Global Sukuk ETF",
                    percentage: 0.10,
                    assetClass: .sukuk,
                    fallbackTicker: "BND",
                    expenseRatio: 0.0055
                ),
                AssetAllocation(
                    ticker: "VNQ",
                    name: "Real Estate",
                    fullName: "Vanguard Real Estate ETF",
                    percentage: 0.10,
                    assetClass: .reit,
                    fallbackTicker: "IYR",
                    expenseRatio: 0.0012
                ),
                AssetAllocation(
                    ticker: "GLDM",
                    name: "Gold",
                    fullName: "SPDR Gold MiniShares Trust",
                    percentage: 0.05,
                    assetClass: .gold,
                    fallbackTicker: "GLD",
                    expenseRatio: 0.001
                )
            ]
            
        case .aggressive:
            // Maximum growth: 0% Sukuk, 95% Equity, 5% Alternatives
            return [
                AssetAllocation(
                    ticker: "SPUS",
                    name: "US Sharia Equity",
                    fullName: "SP Funds S&P 500 Sharia Industry Exclusions ETF",
                    percentage: 0.45,
                    assetClass: .equity,
                    fallbackTicker: "HLAL",
                    expenseRatio: 0.0049
                ),
                AssetAllocation(
                    ticker: "UMMA",
                    name: "Global Islamic Equity",
                    fullName: "Wahed Dow Jones Islamic World ETF",
                    percentage: 0.25,
                    assetClass: .international,
                    fallbackTicker: "VEU",
                    expenseRatio: 0.0065
                ),
                AssetAllocation(
                    ticker: "HLAL",
                    name: "US Shariah ETF",
                    fullName: "Wahed FTSE USA Shariah ETF",
                    percentage: 0.15,
                    assetClass: .equity,
                    fallbackTicker: "SPY",
                    expenseRatio: 0.005
                ),
                AssetAllocation(
                    ticker: "VNQ",
                    name: "Real Estate",
                    fullName: "Vanguard Real Estate ETF",
                    percentage: 0.10,
                    assetClass: .reit,
                    fallbackTicker: "IYR",
                    expenseRatio: 0.0012
                ),
                AssetAllocation(
                    ticker: "GLDM",
                    name: "Gold",
                    fullName: "SPDR Gold MiniShares Trust",
                    percentage: 0.05,
                    assetClass: .gold,
                    fallbackTicker: "GLD",
                    expenseRatio: 0.001
                )
            ]
        }
    }
    
    // MARK: - Computed Properties
    
    var totalExpenseRatio: Double {
        allocations.reduce(0) { $0 + ($1.percentage * $1.expenseRatio) }
    }
    
    var totalExpenseRatioFormatted: String {
        return "\(String(format: "%.2f", totalExpenseRatio * 100))%"
    }
    
    /// Returns allocation breakdown by asset class
    var allocationByClass: [AssetClass: Double] {
        var result: [AssetClass: Double] = [:]
        for allocation in allocations {
            result[allocation.assetClass, default: 0] += allocation.percentage
        }
        return result
    }
}
