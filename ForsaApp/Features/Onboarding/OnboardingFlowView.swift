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
    @State private var riskScore: Int = 0
    @State private var recommendedRisk: RiskLevel = .moderate
    @State private var estimatedDuration: Int = 5
    
    enum OnboardingStep {
        case welcome
        case riskAssessment
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
                RiskQuestionnaireView { score, durationIndex in
                    riskScore = score
                    // Map duration index to years
                    // 0: < 3 years -> 2
                    // 1: 3-7 years -> 5
                    // 2: 10+ years -> 15
                    switch durationIndex {
                    case 0: estimatedDuration = 2
                    case 1: estimatedDuration = 5
                    case 2: estimatedDuration = 15
                    default: estimatedDuration = 5
                    }
                    
                    recommendedRisk = RiskEngine.shared.recommendPortfolio(userRiskScore: score, goalDuration: estimatedDuration)
                    
                    withAnimation {
                        currentStep = .portfolioSelection
                    }
                }
            case .portfolioSelection:
                PortfolioSelectionView(recommendedRisk: recommendedRisk) { selectedRisk in
                    // Create a default goal with the selected portfolio
                    let targetDate = Calendar.current.date(byAdding: .year, value: estimatedDuration, to: Date()) ?? Date()
                    
                    let goal = Goal(
                        name: "My Investment Goal",
                        targetAmount: 10000, // Default placeholder
                        currentValue: 0,
                        targetDate: targetDate,
                        assignedPortfolio: selectedRisk
                    )
                    
                    coordinator.completeOnboarding(riskScore: riskScore, goal: goal)
                }
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppCoordinator())
}
