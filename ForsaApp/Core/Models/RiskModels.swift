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
    
    /// Short description for UI display
    var shortDescription: String {
        switch self {
        case .conservative: return "Low risk, steady returns"
        case .moderate: return "Balanced risk and growth"
        case .growth: return "Higher risk, higher potential"
        case .aggressive: return "Maximum growth potential"
        }
    }
    
    /// Risk level as a percentage (for visual display)
    var riskPercentage: Int {
        switch self {
        case .conservative: return 25
        case .moderate: return 50
        case .growth: return 75
        case .aggressive: return 95
        }
    }
}

// MARK: - Risk Profile

struct RiskProfile: Codable {
    var score: Int
    var normalizedScore: Double // 0.0 to 1.0
    var answers: [Int: Int] // Question ID : Option Index
    var toleranceScore: Double
    var capacityScore: Double
    var assessmentDate: Date
    
    init(score: Int = 0, normalizedScore: Double = 0.5, answers: [Int: Int] = [:], toleranceScore: Double = 0.5, capacityScore: Double = 0.5, assessmentDate: Date = Date()) {
        self.score = score
        self.normalizedScore = normalizedScore
        self.answers = answers
        self.toleranceScore = toleranceScore
        self.capacityScore = capacityScore
        self.assessmentDate = assessmentDate
    }
    
    /// Check if reassessment is recommended (e.g., after 1 year)
    var needsReassessment: Bool {
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return assessmentDate < oneYearAgo
    }
    
    /// Create from detailed assessment result
    static func from(result: RiskAssessmentResult, answers: [Int: Int]) -> RiskProfile {
        RiskProfile(
            score: result.totalScore,
            normalizedScore: result.normalizedScore,
            answers: answers,
            toleranceScore: result.toleranceScore,
            capacityScore: result.capacityScore,
            assessmentDate: Date()
        )
    }
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
