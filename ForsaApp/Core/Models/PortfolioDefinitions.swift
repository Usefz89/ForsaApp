import Foundation

struct AssetAllocation: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let percentage: Double // 0.0 to 1.0
    let assetClass: AssetClass
    let fallbackTicker: String? // Alternative if primary ticker not available
    
    init(ticker: String, name: String, percentage: Double, assetClass: AssetClass = .equity, fallbackTicker: String? = nil) {
        self.ticker = ticker
        self.name = name
        self.percentage = percentage
        self.assetClass = assetClass
        self.fallbackTicker = fallbackTicker
    }
}

enum AssetClass: String, Codable {
    case equity = "Equity"
    case sukuk = "Sukuk"        // Islamic bonds
    case gold = "Gold"
    case reit = "REIT"          // Real Estate Investment Trust
    case international = "International"
}

extension RiskLevel {
    var averageReturn: String {
        switch self {
        case .conservative: return "4% - 6%"
        case .moderate: return "6% - 8%"
        case .growth: return "8% - 10%"
        case .aggressive: return "10% - 12%"
        }
    }
    
    var standardDeviation: String {
        switch self {
        case .conservative: return "5.5%"
        case .moderate: return "11.0%"
        case .growth: return "14.2%"
        case .aggressive: return "17.8%"
        }
    }

    /// Portfolio allocations with Sharia-compliant ETFs
    /// Primary tickers with fallbacks for maximum compatibility with Alpaca
    var allocations: [AssetAllocation] {
        switch self {
        case .conservative:
            // Focus on capital preservation - mostly Sukuk (Islamic bonds) and Gold
            return [
                AssetAllocation(
                    ticker: "SPSK",      // SP Funds Dow Jones Global Sukuk ETF
                    name: "Global Sukuk",
                    percentage: 0.70,
                    assetClass: .sukuk,
                    fallbackTicker: "BND" // Fallback to broad bond ETF
                ),
                AssetAllocation(
                    ticker: "GLDM",      // SPDR Gold MiniShares Trust
                    name: "Gold",
                    percentage: 0.20,
                    assetClass: .gold,
                    fallbackTicker: "GLD"
                ),
                AssetAllocation(
                    ticker: "SPUS",      // SP Funds S&P 500 Sharia ETF
                    name: "US Islamic Equity",
                    percentage: 0.10,
                    assetClass: .equity,
                    fallbackTicker: "HLAL" // Wahed FTSE USA Shariah ETF
                )
            ]
        case .moderate:
            // Balanced growth and stability - mix of Equity and Sukuk
            return [
                AssetAllocation(
                    ticker: "SPSK",
                    name: "Global Sukuk",
                    percentage: 0.40,
                    assetClass: .sukuk,
                    fallbackTicker: "BND"
                ),
                AssetAllocation(
                    ticker: "SPUS",
                    name: "US Islamic Equity",
                    percentage: 0.30,
                    assetClass: .equity,
                    fallbackTicker: "HLAL"
                ),
                AssetAllocation(
                    ticker: "UMMA",      // Wahed Dow Jones Islamic World ETF
                    name: "Int'l Islamic Equity",
                    percentage: 0.20,
                    assetClass: .international,
                    fallbackTicker: "VEU" // Fallback to Vanguard All-World ex-US
                ),
                AssetAllocation(
                    ticker: "GLDM",
                    name: "Gold",
                    percentage: 0.10,
                    assetClass: .gold,
                    fallbackTicker: "GLD"
                )
            ]
        case .growth:
            // Focus on high growth - mostly Equities
            return [
                AssetAllocation(
                    ticker: "SPUS",
                    name: "US Islamic Equity",
                    percentage: 0.50,
                    assetClass: .equity,
                    fallbackTicker: "HLAL"
                ),
                AssetAllocation(
                    ticker: "UMMA",
                    name: "Int'l Islamic Equity",
                    percentage: 0.30,
                    assetClass: .international,
                    fallbackTicker: "VEU"
                ),
                AssetAllocation(
                    ticker: "SPSK",
                    name: "Global Sukuk",
                    percentage: 0.10,
                    assetClass: .sukuk,
                    fallbackTicker: "BND"
                ),
                AssetAllocation(
                    ticker: "VNQ",       // Vanguard Real Estate ETF (widely available)
                    name: "Real Estate",
                    percentage: 0.10,
                    assetClass: .reit,
                    fallbackTicker: "IYR" // iShares US Real Estate ETF
                )
            ]
        case .aggressive:
            // Maximum growth potential - 100% Equities
            return [
                AssetAllocation(
                    ticker: "SPUS",
                    name: "US Islamic Equity",
                    percentage: 0.60,
                    assetClass: .equity,
                    fallbackTicker: "HLAL"
                ),
                AssetAllocation(
                    ticker: "UMMA",
                    name: "Int'l Islamic Equity",
                    percentage: 0.30,
                    assetClass: .international,
                    fallbackTicker: "VEU"
                ),
                AssetAllocation(
                    ticker: "VNQ",
                    name: "Real Estate",
                    percentage: 0.10,
                    assetClass: .reit,
                    fallbackTicker: "IYR"
                )
            ]
        }
    }
    
    /// Returns the color associated with each portfolio type
    var themeColor: String {
        switch self {
        case .conservative: return "blue"
        case .moderate: return "green"
        case .growth: return "orange"
        case .aggressive: return "red"
        }
    }
}
