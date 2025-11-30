import SwiftUI

struct RiskQuestionnaireView: View {
    let onComplete: (RiskAssessmentResult, [Int: Int]) -> Void
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [Int: Int] = [:] // Question ID : Option Index
    @State private var showingResults = false
    @State private var assessmentResult: RiskAssessmentResult?
    
    private let riskEngine = RiskEngine.shared
    
    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(riskEngine.questions.count)
    }
    
    var currentQuestion: Question? {
        guard currentQuestionIndex < riskEngine.questions.count else { return nil }
        return riskEngine.questions[currentQuestionIndex]
    }
    
    var currentConfig: RiskEngine.QuestionConfig? {
        guard currentQuestionIndex < riskEngine.questionConfigs.count else { return nil }
        return riskEngine.questionConfigs[currentQuestionIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Risk Assessment")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text(categoryLabel)
                            .font(.caption)
                            .foregroundColor(.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.15))
                            .foregroundColor(categoryColor)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Question counter
                    Text("\(currentQuestionIndex + 1)/\(riskEngine.questions.count)")
                        .font(.calloutMedium)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                }
                
                // Segmented progress bar
                HStack(spacing: 4) {
                    ForEach(0..<riskEngine.questions.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressColor(for: index))
                            .frame(height: 4)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            if let question = currentQuestion {
                ScrollView {
                    VStack(spacing: 24) {
                        // Question Card
                        VStack(alignment: .leading, spacing: 20) {
                            // Question text
                            Text(question.text)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Helper text
                            if let helperText = getHelperText(for: question.id) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.primaryBlue)
                                        .font(.caption)
                                    
                                    Text(helperText)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .background(Color.primaryBlue.opacity(0.08))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Options
                        VStack(spacing: 12) {
                            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                                OptionButton(
                                    text: option.text,
                                    isSelected: answers[question.id] == index,
                                    riskLevel: getRiskIndicator(points: option.points)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        answers[question.id] = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 120)
                }
                
                // Navigation Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        if currentQuestionIndex > 0 {
                            ForsaButton("Back", style: .outline) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentQuestionIndex -= 1
                                }
                            }
                        }
                        
                        ForsaButton(
                            currentQuestionIndex == riskEngine.questions.count - 1 ? "See Results" : "Continue",
                            style: .primary,
                            isDisabled: answers[question.id] == nil
                        ) {
                            if currentQuestionIndex < riskEngine.questions.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentQuestionIndex += 1
                                }
                            } else {
                                finishQuestionnaire()
                            }
                        }
                    }
                    
                    // Skip indicator
                    if answers[question.id] == nil {
                        Text("Select an option to continue")
                            .font(.caption)
                            .foregroundColor(.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Color.backgroundPrimary
                        .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
                )
            }
        }
        .background(Color.backgroundPrimary)
    }
    
    // MARK: - Helper Properties
    
    private var categoryLabel: String {
        guard let config = currentConfig else { return "" }
        switch config.category {
        case .tolerance:
            return "Risk Tolerance"
        case .capacity:
            return "Risk Capacity"
        }
    }
    
    private var categoryColor: Color {
        guard let config = currentConfig else { return .textSecondary }
        switch config.category {
        case .tolerance:
            return .primaryPurple
        case .capacity:
            return .primaryBlue
        }
    }
    
    private func progressColor(for index: Int) -> Color {
        if index < currentQuestionIndex {
            return .primaryGreen
        } else if index == currentQuestionIndex {
            return .primaryPurple
        } else {
            return Color.textMuted.opacity(0.3)
        }
    }
    
    private func getRiskIndicator(points: Int) -> RiskIndicator {
        switch points {
        case 0...2:
            return .low
        case 3...5:
            return .moderate
        case 6...8:
            return .high
        default:
            return .veryHigh
        }
    }
    
    private func getHelperText(for questionId: Int) -> String? {
        switch questionId {
        case 1:
            return "Your investment goal helps us understand your priorities - whether you value safety, income, or growth."
        case 2:
            return "Longer time horizons generally allow for more aggressive strategies since you have time to recover from market downturns."
        case 4:
            return "This reveals your emotional response to volatility - a key factor in staying committed to your investment plan."
        case 5:
            return "Your experience level helps us calibrate educational support and strategy complexity."
        default:
            return nil
        }
    }
    
    // MARK: - Actions
    
    private func finishQuestionnaire() {
        let result = riskEngine.calculateDetailedAssessment(answers: answers)
        onComplete(result, answers)
    }
}

// MARK: - Risk Indicator

enum RiskIndicator {
    case low, moderate, high, veryHigh
    
    var color: Color {
        switch self {
        case .low: return .primaryBlue
        case .moderate: return .primaryGreen
        case .high: return .primaryOrange
        case .veryHigh: return .errorRed
        }
    }
    
    var label: String {
        switch self {
        case .low: return "Conservative"
        case .moderate: return "Moderate"
        case .high: return "Growth"
        case .veryHigh: return "Aggressive"
        }
    }
}

// MARK: - Option Button

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let riskLevel: RiskIndicator
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.primaryPurple : Color.textMuted.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.primaryPurple)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Option text
                Text(text)
                    .font(.callout)
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Risk level indicator
                RiskLevelBadge(level: riskLevel, isCompact: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primaryPurple.opacity(0.08) : Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryPurple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Risk Level Badge

struct RiskLevelBadge: View {
    let level: RiskIndicator
    var isCompact: Bool = false
    
    var body: some View {
        if isCompact {
            Circle()
                .fill(level.color.opacity(0.2))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(level.color)
                        .frame(width: 4, height: 4)
                )
        } else {
            Text(level.label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(level.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(level.color.opacity(0.15))
                .cornerRadius(4)
        }
    }
}

// MARK: - Preview

#Preview {
    RiskQuestionnaireView { result, answers in
        print("Risk Assessment Complete!")
        print("Score: \(result.totalScore)")
        print("Tolerance: \(result.toleranceLevel.description)")
        print("Capacity: \(result.capacityLevel.description)")
        print("Recommended: \(result.recommendedPortfolio.title)")
    }
}
