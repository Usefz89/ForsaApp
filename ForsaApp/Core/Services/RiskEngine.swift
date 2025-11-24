import Foundation

class RiskEngine {
    
    static let shared = RiskEngine()
    
    // The 4 Key Questions
    let questions: [Question] = [
        Question(
            id: 1,
            text: "What is your primary investment goal?",
            options: [
                QuestionOption(text: "Preserve my capital", points: 1),
                QuestionOption(text: "Grow my wealth steadily", points: 5),
                QuestionOption(text: "Aggressive growth, maximizing returns", points: 10)
            ]
        ),
        Question(
            id: 2,
            text: "What is your investment horizon?",
            options: [
                QuestionOption(text: "Less than 3 years", points: 1),
                QuestionOption(text: "3 - 7 years", points: 5),
                QuestionOption(text: "10+ years", points: 10)
            ]
        ),
        Question(
            id: 3,
            text: "How much of your income can you invest?",
            options: [
                QuestionOption(text: "Less than 10%", points: 2),
                QuestionOption(text: "10% - 30%", points: 5),
                QuestionOption(text: "More than 30%", points: 8)
            ]
        ),
        Question(
            id: 4,
            text: "If the market drops 20% in a month, what would you do?",
            options: [
                QuestionOption(text: "Sell everything immediately", points: 0),
                QuestionOption(text: "Wait it out", points: 5),
                QuestionOption(text: "Buy more", points: 10)
            ]
        )
    ]
    
    func calculateScore(answers: [Int: Int]) -> Int {
        var totalScore = 0
        for (questionId, optionIndex) in answers {
            if let question = questions.first(where: { $0.id == questionId }),
               optionIndex < question.options.count {
                totalScore += question.options[optionIndex].points
            }
        }
        return totalScore
    }
    
    func recommendPortfolio(userRiskScore: Int, goalDuration: Int) -> RiskLevel {
        // Tamra Matrix Logic
        
        // 1. Short term (< 2 years) -> Always Conservative
        if goalDuration < 2 {
            return .conservative
        }
        
        // 2. Medium term (3-5 years) -> Moderate
        if goalDuration >= 3 && goalDuration <= 5 {
            return .moderate
        }
        
        // 3. 5-10 Years -> Growth
        if goalDuration > 5 && goalDuration <= 10 {
            return .growth
        }
        
        // 4. Long term (> 10 years) AND High Risk Score -> Aggressive
        // Assuming High Risk Score is > 20 (High tolerance) based on max possible score approx 30-40?
        // Let's assume max score is around 40. "High Tolerance" could be top tier.
        if goalDuration > 10 && userRiskScore > 25 {
            return .aggressive
        }
        
        // Fallback Logic
        if goalDuration > 10 {
            return .growth
        }
        
        // Gap filling for 2-3 years? Or default
        return .moderate
    }
}
