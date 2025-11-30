import Foundation

// MARK: - Risk Scoring Configuration

/// Weights for different risk dimensions
struct RiskWeights {
    static let investmentGoal: Double = 3.0      // Primary psychological factor
    static let marketReaction: Double = 2.5      // Key risk tolerance indicator
    static let investmentHorizon: Double = 2.0   // Time-based capacity
    static let incomeCapacity: Double = 1.5      // Financial capacity
    static let investmentExperience: Double = 1.5 // Knowledge-based capacity
}

/// Enum for risk tolerance level (psychological willingness)
enum RiskToleranceLevel: Int, CaseIterable {
    case low = 1
    case moderate = 2
    case high = 3
    case veryHigh = 4
    
    var description: String {
        switch self {
        case .low: return "Conservative"
        case .moderate: return "Moderate"
        case .high: return "Growth-Oriented"
        case .veryHigh: return "Aggressive"
        }
    }
}

/// Enum for risk capacity level (financial ability)
enum RiskCapacityLevel: Int, CaseIterable {
    case limited = 1
    case moderate = 2
    case substantial = 3
    case extensive = 4
    
    var description: String {
        switch self {
        case .limited: return "Limited Capacity"
        case .moderate: return "Moderate Capacity"
        case .substantial: return "Substantial Capacity"
        case .extensive: return "Extensive Capacity"
        }
    }
}

/// Detailed scoring result
struct RiskAssessmentResult {
    let totalScore: Int
    let normalizedScore: Double // 0.0 to 1.0
    let toleranceLevel: RiskToleranceLevel
    let capacityLevel: RiskCapacityLevel
    let toleranceScore: Double
    let capacityScore: Double
    let recommendedPortfolio: RiskLevel
    let alternativePortfolios: [RiskLevel]
    let explanation: String
    
    var tolerancePercentage: Int {
        Int(toleranceScore * 100)
    }
    
    var capacityPercentage: Int {
        Int(capacityScore * 100)
    }
}

// MARK: - Risk Engine

class RiskEngine {
    
    static let shared = RiskEngine()
    
    // MARK: - Question Categories
    
    enum QuestionCategory {
        case tolerance  // Psychological willingness to take risk
        case capacity   // Financial/situational ability to take risk
    }
    
    // MARK: - Enhanced Question Configuration
    
    struct QuestionConfig {
        let id: Int
        let category: QuestionCategory
        let weight: Double
        let text: String
        let options: [QuestionOption]
    }
    
    // MARK: - The 6 Key Questions
    
    /// Comprehensive risk assessment questions
    let questionConfigs: [QuestionConfig] = [
        // Q1: Investment Goal (Tolerance - Primary)
        QuestionConfig(
            id: 1,
            category: .tolerance,
            weight: RiskWeights.investmentGoal,
            text: "What is your primary investment goal?",
            options: [
                QuestionOption(text: "Preserve my capital - I can't afford to lose money", points: 1),
                QuestionOption(text: "Generate steady income with some growth", points: 4),
                QuestionOption(text: "Grow my wealth steadily over time", points: 7),
                QuestionOption(text: "Maximize returns - I accept high volatility", points: 10)
            ]
        ),
        
        // Q2: Investment Horizon (Capacity)
        QuestionConfig(
            id: 2,
            category: .capacity,
            weight: RiskWeights.investmentHorizon,
            text: "When do you expect to need this money?",
            options: [
                QuestionOption(text: "Within 2 years", points: 1),
                QuestionOption(text: "2 - 5 years", points: 4),
                QuestionOption(text: "5 - 10 years", points: 7),
                QuestionOption(text: "More than 10 years", points: 10)
            ]
        ),
        
        // Q3: Income/Savings Capacity (Capacity)
        QuestionConfig(
            id: 3,
            category: .capacity,
            weight: RiskWeights.incomeCapacity,
            text: "How much of your monthly income can you invest?",
            options: [
                QuestionOption(text: "Less than 10% - Most goes to essentials", points: 2),
                QuestionOption(text: "10% - 20% - Comfortable savings rate", points: 5),
                QuestionOption(text: "20% - 40% - Strong savings capacity", points: 8),
                QuestionOption(text: "More than 40% - Significant surplus", points: 10)
            ]
        ),
        
        // Q4: Market Reaction (Tolerance - Key)
        QuestionConfig(
            id: 4,
            category: .tolerance,
            weight: RiskWeights.marketReaction,
            text: "If your portfolio dropped 25% in a month, what would you do?",
            options: [
                QuestionOption(text: "Sell everything to prevent further losses", points: 0),
                QuestionOption(text: "Sell some and move to safer investments", points: 3),
                QuestionOption(text: "Hold steady and wait for recovery", points: 6),
                QuestionOption(text: "Buy more - it's a buying opportunity", points: 10)
            ]
        ),
        
        // Q5: Investment Experience (Capacity)
        QuestionConfig(
            id: 5,
            category: .capacity,
            weight: RiskWeights.investmentExperience,
            text: "What is your investment experience?",
            options: [
                QuestionOption(text: "None - This is my first time investing", points: 2),
                QuestionOption(text: "Basic - I've used savings accounts or deposits", points: 4),
                QuestionOption(text: "Intermediate - I've invested in stocks or funds", points: 7),
                QuestionOption(text: "Advanced - I actively manage my investments", points: 10)
            ]
        )
    ]
    
    // MARK: - Computed Properties
    
    /// Questions array for compatibility with existing views
    var questions: [Question] {
        questionConfigs.map { config in
            Question(id: config.id, text: config.text, options: config.options)
        }
    }
    
    /// Maximum possible raw score
    var maxPossibleScore: Int {
        questionConfigs.reduce(0) { sum, config in
            sum + (config.options.map { $0.points }.max() ?? 0)
        }
    }
    
    /// Minimum possible raw score
    var minPossibleScore: Int {
        questionConfigs.reduce(0) { sum, config in
            sum + (config.options.map { $0.points }.min() ?? 0)
        }
    }
    
    /// Maximum weighted score
    var maxWeightedScore: Double {
        questionConfigs.reduce(0) { sum, config in
            sum + (Double(config.options.map { $0.points }.max() ?? 0) * config.weight)
        }
    }
    
    // MARK: - Score Calculation
    
    /// Calculate simple raw score (for backward compatibility)
    func calculateScore(answers: [Int: Int]) -> Int {
        var totalScore = 0
        for (questionId, optionIndex) in answers {
            if let config = questionConfigs.first(where: { $0.id == questionId }),
               optionIndex < config.options.count {
                totalScore += config.options[optionIndex].points
            }
        }
        return totalScore
    }
    
    /// Calculate comprehensive risk assessment
    func calculateDetailedAssessment(answers: [Int: Int]) -> RiskAssessmentResult {
        var toleranceWeightedSum: Double = 0
        var toleranceMaxPossible: Double = 0
        var capacityWeightedSum: Double = 0
        var capacityMaxPossible: Double = 0
        
        for config in questionConfigs {
            let maxPoints = Double(config.options.map { $0.points }.max() ?? 10)
            
            if let optionIndex = answers[config.id],
               optionIndex < config.options.count {
                let points = Double(config.options[optionIndex].points)
                let weightedPoints = points * config.weight
                
                switch config.category {
                case .tolerance:
                    toleranceWeightedSum += weightedPoints
                    toleranceMaxPossible += maxPoints * config.weight
                case .capacity:
                    capacityWeightedSum += weightedPoints
                    capacityMaxPossible += maxPoints * config.weight
                }
            } else {
                // Add max possible even if not answered (for percentage calculation)
                switch config.category {
                case .tolerance:
                    toleranceMaxPossible += maxPoints * config.weight
                case .capacity:
                    capacityMaxPossible += maxPoints * config.weight
                }
            }
        }
        
        // Calculate normalized scores (0.0 to 1.0)
        let toleranceScore = toleranceMaxPossible > 0 ? toleranceWeightedSum / toleranceMaxPossible : 0.5
        let capacityScore = capacityMaxPossible > 0 ? capacityWeightedSum / capacityMaxPossible : 0.5
        
        // Combined weighted score (tolerance weighted slightly higher as it's the user's preference)
        let combinedScore = (toleranceScore * 0.55) + (capacityScore * 0.45)
        
        // Determine tolerance level
        let toleranceLevel = determineToleranceLevel(score: toleranceScore)
        let capacityLevel = determineCapacityLevel(score: capacityScore)
        
        // Get investment duration from answers
        let durationIndex = answers[2] ?? 1
        let duration = mapDurationIndexToYears(durationIndex)
        
        // Calculate recommended portfolio using matrix approach
        let recommendedPortfolio = recommendPortfolioFromMatrix(
            toleranceScore: toleranceScore,
            capacityScore: capacityScore,
            duration: duration
        )
        
        // Get alternative portfolios
        let alternatives = getAlternativePortfolios(
            recommended: recommendedPortfolio,
            toleranceLevel: toleranceLevel,
            capacityLevel: capacityLevel
        )
        
        // Generate explanation
        let explanation = generateExplanation(
            portfolio: recommendedPortfolio,
            toleranceLevel: toleranceLevel,
            capacityLevel: capacityLevel,
            duration: duration
        )
        
        return RiskAssessmentResult(
            totalScore: calculateScore(answers: answers),
            normalizedScore: combinedScore,
            toleranceLevel: toleranceLevel,
            capacityLevel: capacityLevel,
            toleranceScore: toleranceScore,
            capacityScore: capacityScore,
            recommendedPortfolio: recommendedPortfolio,
            alternativePortfolios: alternatives,
            explanation: explanation
        )
    }
    
    // MARK: - Level Determination
    
    private func determineToleranceLevel(score: Double) -> RiskToleranceLevel {
        switch score {
        case 0..<0.30: return .low
        case 0.30..<0.55: return .moderate
        case 0.55..<0.80: return .high
        default: return .veryHigh
        }
    }
    
    private func determineCapacityLevel(score: Double) -> RiskCapacityLevel {
        switch score {
        case 0..<0.30: return .limited
        case 0.30..<0.55: return .moderate
        case 0.55..<0.80: return .substantial
        default: return .extensive
        }
    }
    
    // MARK: - Portfolio Recommendation Matrix
    
    /// Matrix-based portfolio recommendation
    /// Uses both risk tolerance and capacity with time horizon adjustment
    func recommendPortfolioFromMatrix(toleranceScore: Double, capacityScore: Double, duration: Int) -> RiskLevel {
        
        // Step 1: Calculate base risk level from tolerance and capacity
        let combinedScore = (toleranceScore * 0.55) + (capacityScore * 0.45)
        
        // Step 2: Apply time horizon adjustment
        // Shorter horizons reduce risk, longer horizons can increase it
        let durationAdjustment = calculateDurationAdjustment(duration: duration)
        let adjustedScore = min(1.0, max(0.0, combinedScore + durationAdjustment))
        
        // Step 3: Apply the "lesser of" principle
        // Final risk level should not exceed either tolerance OR capacity
        let effectiveScore = calculateEffectiveScore(
            adjustedScore: adjustedScore,
            toleranceScore: toleranceScore,
            capacityScore: capacityScore,
            duration: duration
        )
        
        // Step 4: Map to portfolio
        return mapScoreToPortfolio(score: effectiveScore)
    }
    
    /// Duration adjustment factor
    private func calculateDurationAdjustment(duration: Int) -> Double {
        switch duration {
        case 0..<2:
            return -0.20  // Short term: reduce risk significantly
        case 2..<4:
            return -0.10  // Near-medium: slight reduction
        case 4..<7:
            return 0.0    // Medium term: no adjustment
        case 7..<12:
            return 0.05   // Long term: slight increase
        default:
            return 0.10   // Very long term: can take more risk
        }
    }
    
    /// Apply the "lesser of" principle - prevents taking more risk than user can handle
    private func calculateEffectiveScore(adjustedScore: Double, toleranceScore: Double, capacityScore: Double, duration: Int) -> Double {
        
        // For very short durations, always cap at conservative-moderate
        if duration < 2 {
            return min(adjustedScore, 0.35)
        }
        
        // For short durations (2-3 years), cap at moderate
        if duration < 4 {
            return min(adjustedScore, 0.50)
        }
        
        // For medium+ durations, use the lesser of tolerance or capacity
        // This prevents recommending aggressive to someone with high capacity but low tolerance
        let capScore = min(toleranceScore, capacityScore)
        
        // Allow the adjusted score to go up to the capped level
        return min(adjustedScore, capScore + 0.15)
    }
    
    /// Map final score to portfolio
    private func mapScoreToPortfolio(score: Double) -> RiskLevel {
        switch score {
        case 0..<0.30:
            return .conservative
        case 0.30..<0.55:
            return .moderate
        case 0.55..<0.75:
            return .growth
        default:
            return .aggressive
        }
    }
    
    // MARK: - Legacy Method (Backward Compatibility)
    
    /// Original method for backward compatibility
    func recommendPortfolio(userRiskScore: Int, goalDuration: Int) -> RiskLevel {
        // Convert raw score to normalized (0-1)
        let normalizedScore = Double(userRiskScore) / Double(maxPossibleScore)
        
        return recommendPortfolioFromMatrix(
            toleranceScore: normalizedScore,
            capacityScore: normalizedScore,
            duration: goalDuration
        )
    }
    
    // MARK: - Helpers
    
    private func mapDurationIndexToYears(_ index: Int) -> Int {
        switch index {
        case 0: return 1   // Within 2 years
        case 1: return 3   // 2-5 years
        case 2: return 7   // 5-10 years
        case 3: return 15  // More than 10 years
        default: return 5
        }
    }
    
    private func getAlternativePortfolios(recommended: RiskLevel, toleranceLevel: RiskToleranceLevel, capacityLevel: RiskCapacityLevel) -> [RiskLevel] {
        var alternatives: [RiskLevel] = []
        
        // Add adjacent risk levels as alternatives
        switch recommended {
        case .conservative:
            alternatives = [.moderate]
        case .moderate:
            alternatives = [.conservative, .growth]
        case .growth:
            alternatives = [.moderate, .aggressive]
        case .aggressive:
            alternatives = [.growth]
        }
        
        // Filter based on capacity constraints
        if capacityLevel == .limited {
            alternatives = alternatives.filter { $0 == .conservative || $0 == .moderate }
        }
        
        return alternatives
    }
    
    private func generateExplanation(portfolio: RiskLevel, toleranceLevel: RiskToleranceLevel, capacityLevel: RiskCapacityLevel, duration: Int) -> String {
        var reasons: [String] = []
        
        // Tolerance-based reason
        switch toleranceLevel {
        case .low:
            reasons.append("Your preference for capital preservation")
        case .moderate:
            reasons.append("Your balanced approach to risk and reward")
        case .high:
            reasons.append("Your comfort with market volatility")
        case .veryHigh:
            reasons.append("Your strong appetite for growth")
        }
        
        // Duration-based reason
        if duration < 3 {
            reasons.append("your short investment timeline")
        } else if duration < 7 {
            reasons.append("your medium-term horizon")
        } else {
            reasons.append("your long-term investment horizon")
        }
        
        // Capacity-based adjustment
        if capacityLevel.rawValue < toleranceLevel.rawValue {
            reasons.append("adjusted for your current financial capacity")
        }
        
        let reasonsText = reasons.joined(separator: ", ")
        return "Based on \(reasonsText), the \(portfolio.title) portfolio is recommended for you."
    }
    
    // MARK: - Validation
    
    /// Check if all questions are answered
    func isComplete(answers: [Int: Int]) -> Bool {
        for config in questionConfigs {
            guard answers[config.id] != nil else { return false }
        }
        return true
    }
    
    /// Get unanswered question IDs
    func getUnansweredQuestions(answers: [Int: Int]) -> [Int] {
        return questionConfigs.compactMap { config in
            answers[config.id] == nil ? config.id : nil
        }
    }
}
