import Foundation

struct AssetAllocation: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let percentage: Double // 0.0 to 1.0
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

    var allocations: [AssetAllocation] {
        switch self {
        case .conservative:
            return [
                AssetAllocation(ticker: "SPSK", name: "Global Sukuk", percentage: 0.70),
                AssetAllocation(ticker: "GLDM", name: "Gold", percentage: 0.20),
                AssetAllocation(ticker: "SPUS", name: "US Islamic Equity", percentage: 0.10)
            ]
        case .moderate:
            return [
                AssetAllocation(ticker: "SPSK", name: "Global Sukuk", percentage: 0.40),
                AssetAllocation(ticker: "SPUS", name: "US Islamic Equity", percentage: 0.30),
                AssetAllocation(ticker: "UMMA", name: "Int'l Islamic Equity", percentage: 0.20),
                AssetAllocation(ticker: "GLDM", name: "Gold", percentage: 0.10)
            ]
        case .growth:
            return [
                AssetAllocation(ticker: "SPUS", name: "US Islamic Equity", percentage: 0.50),
                AssetAllocation(ticker: "UMMA", name: "Int'l Islamic Equity", percentage: 0.30),
                AssetAllocation(ticker: "SPSK", name: "Global Sukuk", percentage: 0.10),
                AssetAllocation(ticker: "SPRE", name: "Islamic REITs", percentage: 0.10)
            ]
        case .aggressive:
            return [
                AssetAllocation(ticker: "SPUS", name: "US Islamic Equity", percentage: 0.60),
                AssetAllocation(ticker: "UMMA", name: "Int'l Islamic Equity", percentage: 0.30),
                AssetAllocation(ticker: "SPRE", name: "Islamic REITs", percentage: 0.10)
            ]
        }
    }
}
