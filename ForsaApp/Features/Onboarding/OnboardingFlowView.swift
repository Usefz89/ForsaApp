//
//  OnboardingFlowView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var currentStep: OnboardingStep = .riskAssessment
    @State private var assessmentResult: RiskAssessmentResult?
    @State private var riskAnswers: [Int: Int] = [:]
    @State private var estimatedDuration: Int = 5
    
    enum OnboardingStep {
        case welcome
        case riskAssessment
        case resultsSummary
        case portfolioSelection
    }
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            switch currentStep {
            case .welcome:
                WelcomeOnboardingView {
                    withAnimation {
                        currentStep = .riskAssessment
                    }
                }
            case .riskAssessment:
                RiskQuestionnaireView { result, answers in
                    assessmentResult = result
                    riskAnswers = answers
                    
                    // Extract duration from answers (Question 2)
                    if let durationIndex = answers[2] {
                        switch durationIndex {
                        case 0: estimatedDuration = 1   // Within 2 years
                        case 1: estimatedDuration = 4   // 2-5 years
                        case 2: estimatedDuration = 7   // 5-10 years
                        case 3: estimatedDuration = 15  // More than 10 years
                        default: estimatedDuration = 5
                        }
                    }
                    
                    withAnimation {
                        currentStep = .resultsSummary
                    }
                }
                
            case .resultsSummary:
                if let result = assessmentResult {
                    RiskResultsSummaryView(result: result) {
                        withAnimation {
                            currentStep = .portfolioSelection
                        }
                    }
                }
                
            case .portfolioSelection:
                if let result = assessmentResult {
                    PortfolioSelectionView(
                        recommendedRisk: result.recommendedPortfolio,
                        alternativePortfolios: result.alternativePortfolios
                    ) { selectedRisk in
                        // Create a default goal with the selected portfolio
                        let targetDate = Calendar.current.date(byAdding: .year, value: estimatedDuration, to: Date()) ?? Date()
                        
                        let goal = Goal(
                            name: "My Investment Goal",
                            targetAmount: 10000, // Default placeholder
                            currentValue: 0,
                            targetDate: targetDate,
                            assignedPortfolio: selectedRisk
                        )
                        
                        coordinator.completeOnboarding(riskScore: result.totalScore, goal: goal)
                    }
                }
            }
        }
    }
}

// MARK: - Risk Results Summary View

struct RiskResultsSummaryView: View {
    let result: RiskAssessmentResult
    let onContinue: () -> Void
    
    @State private var showDetails = false
    @State private var animateScores = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.primaryPurple)
                            .padding(.top, 24)
                        
                        Text("Your Risk Profile")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Based on your answers, we've analyzed your investment personality")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Score Cards
                    HStack(spacing: 16) {
                        ScoreCard(
                            title: "Risk Tolerance",
                            subtitle: "Psychological",
                            percentage: animateScores ? result.tolerancePercentage : 0,
                            level: result.toleranceLevel.description,
                            color: .primaryPurple,
                            icon: "brain.head.profile"
                        )
                        
                        ScoreCard(
                            title: "Risk Capacity",
                            subtitle: "Financial",
                            percentage: animateScores ? result.capacityPercentage : 0,
                            level: result.capacityLevel.description,
                            color: .primaryBlue,
                            icon: "banknote.fill"
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Recommended Portfolio Card
                    ForsaCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: result.recommendedPortfolio.icon)
                                    .font(.title2)
                                    .foregroundColor(result.recommendedPortfolio.color)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Recommended Portfolio")
                                        .font(.caption)
                                        .foregroundColor(.textMuted)
                                    
                                    Text(result.recommendedPortfolio.title)
                                        .font(.headline)
                                        .foregroundColor(.textPrimary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundColor(.primaryGreen)
                            }
                            
                            Divider()
                            
                            Text(result.explanation)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Portfolio metrics preview
                            HStack(spacing: 24) {
                                MetricItem(
                                    label: "Expected Return",
                                    value: result.recommendedPortfolio.averageReturn,
                                    color: .primaryGreen
                                )
                                
                                MetricItem(
                                    label: "Risk Level",
                                    value: result.recommendedPortfolio.standardDeviation,
                                    color: .primaryOrange
                                )
                                
                                MetricItem(
                                    label: "Time Horizon",
                                    value: result.recommendedPortfolio.timeHorizon,
                                    color: .primaryBlue
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // What This Means
                    ForsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What This Means")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ExplanationRow(
                                    icon: "shield.fill",
                                    text: getToleranceExplanation()
                                )
                                
                                ExplanationRow(
                                    icon: "chart.bar.fill",
                                    text: getCapacityExplanation()
                                )
                                
                                ExplanationRow(
                                    icon: "arrow.triangle.merge",
                                    text: "Your portfolio balances both factors for optimal results"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Alternative Options
                    if !result.alternativePortfolios.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other Options Available")
                                .font(.caption)
                                .foregroundColor(.textMuted)
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(result.alternativePortfolios, id: \.self) { portfolio in
                                        AlternativePortfolioChip(portfolio: portfolio)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .padding(.bottom, 120)
            }
            
            // Continue Button
            VStack(spacing: 8) {
                ForsaButton("Choose Your Portfolio", style: .primary) {
                    onContinue()
                }
                
                Text("You can change your portfolio selection later")
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.backgroundPrimary)
        }
        .background(Color.backgroundPrimary)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateScores = true
            }
        }
    }
    
    private func getToleranceExplanation() -> String {
        switch result.toleranceLevel {
        case .low:
            return "You prefer stability over volatility and prioritize capital preservation"
        case .moderate:
            return "You're comfortable with some fluctuation for moderate growth potential"
        case .high:
            return "You accept significant volatility in pursuit of higher returns"
        case .veryHigh:
            return "You're comfortable with high volatility and market swings"
        }
    }
    
    private func getCapacityExplanation() -> String {
        switch result.capacityLevel {
        case .limited:
            return "Your current situation calls for a more cautious approach"
        case .moderate:
            return "You have a reasonable buffer to handle market fluctuations"
        case .substantial:
            return "Your financial position supports a growth-oriented strategy"
        case .extensive:
            return "You have strong capacity to weather market downturns"
        }
    }
}

// MARK: - Score Card

struct ScoreCard: View {
    let title: String
    let subtitle: String
    let percentage: Int
    let level: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.textMuted)
                }
                
                Spacer()
            }
            
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                Text("\(percentage)%")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
            }
            
            Text(level)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.15))
                .cornerRadius(4)
        }
        .padding(16)
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }
}

// MARK: - Metric Item

struct MetricItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Explanation Row

struct ExplanationRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primaryPurple)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Alternative Portfolio Chip

struct AlternativePortfolioChip: View {
    let portfolio: RiskLevel
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: portfolio.icon)
                .font(.caption)
                .foregroundColor(portfolio.color)
            
            Text(portfolio.title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .cornerRadius(20)
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppCoordinator())
}
