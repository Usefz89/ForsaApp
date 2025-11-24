import SwiftUI

struct RiskQuestionnaireView: View {
    let onComplete: (Int, Int) -> Void // Score, Duration Answer Index
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [Int: Int] = [:] // Question ID : Option Index
    
    private let riskEngine = RiskEngine.shared
    
    var progress: Double {
        Double(currentQuestionIndex) / Double(riskEngine.questions.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Risk Assessment")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Question \(currentQuestionIndex + 1) of \(riskEngine.questions.count)")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 16)
            
            // Progress Bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .primaryPurple))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            
            if currentQuestionIndex < riskEngine.questions.count {
                let question = riskEngine.questions[currentQuestionIndex]
                
                QuestionView(
                    question: question,
                    selectedOptionIndex: answers[question.id]
                ) { selectedIndex in
                    answers[question.id] = selectedIndex
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
                Spacer()
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentQuestionIndex > 0 {
                        ForsaButton("Back", style: .outline) {
                            withAnimation {
                                currentQuestionIndex -= 1
                            }
                        }
                    }
                    
                    ForsaButton(
                        currentQuestionIndex == riskEngine.questions.count - 1 ? "Finish" : "Next",
                        style: .primary,
                        isDisabled: answers[question.id] == nil
                    ) {
                        if currentQuestionIndex < riskEngine.questions.count - 1 {
                            withAnimation {
                                currentQuestionIndex += 1
                            }
                        } else {
                            finishQuestionnaire()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.backgroundPrimary)
    }
    
    private func finishQuestionnaire() {
        let calculatedScore = riskEngine.calculateScore(answers: answers)
        let durationIndex = answers[2] ?? 1 // Default to middle option (3-7 years) if missing
        onComplete(calculatedScore, durationIndex)
    }
}

#Preview {
    RiskQuestionnaireView { score, duration in
        print("Risk score: \(score), Duration index: \(duration)")
    }
}
