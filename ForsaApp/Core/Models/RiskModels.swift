import Foundation

enum RiskLevel: String, Codable, CaseIterable {
    case conservative
    case moderate
    case growth
    case aggressive
    
    var title: String {
        switch self {
        case .conservative: return "Protection (Himaya)"
        case .moderate: return "Balanced (Tawazun)"
        case .growth: return "Growth (Numo)"
        case .aggressive: return "Aggressive (Jare'e)"
        }
    }
    
    var description: String {
        switch self {
        case .conservative: return "Focus on capital preservation. Mostly Sukuk."
        case .moderate: return "A mix of growth and stability. Balanced between Equity and Sukuk."
        case .growth: return "Focus on high growth. Mostly Equities."
        case .aggressive: return "High risk, maximum growth potential. 100% Equities."
        }
    }
}

struct RiskProfile: Codable {
    var score: Int
    var answers: [Int: Int] // Question ID : Option Index
}

struct Goal: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var targetAmount: Double
    var currentValue: Double
    var targetDate: Date
    var assignedPortfolio: RiskLevel
    
    var durationYears: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: Date(), to: targetDate)
        return max(0, components.year ?? 0)
    }
}

struct Question: Identifiable {
    let id: Int
    let text: String
    let options: [QuestionOption]
}

struct QuestionOption: Identifiable {
    let id: UUID = UUID()
    let text: String
    let points: Int
}
