//
//  PortfolioRecommendationView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct PortfolioRecommendationView: View {
    let goal: Goal
    let riskScore: Int
    let onComplete: () -> Void
    
    @State private var showSelection = false
    @State private var showDetails = false
    @State private var selectedRisk: RiskLevel?
    
    var body: some View {
        VStack(spacing: 0) {
            // ... (Header remains same) ...
            // Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryGreen)
                    .padding(.bottom, 16)
                
                Text("Your Portfolio is Ready!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Based on your risk profile and goal timeline")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Goal Summary
                    // ... (Goal Card remains same) ...
                     ForsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Goal")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.name)
                                        .font(.headline)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Target: KWD \(String(format: "%.0f", goal.targetAmount))")
                                        .font(.caption1)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(goal.durationYears) years")
                                        .font(.calloutMedium)
                                        .foregroundColor(.primaryPurple)
                                    
                                    Text("Time Horizon")
                                        .font(.caption2)
                                        .foregroundColor(.textMuted)
                                }
                            }
                        }
                    }
                    
                    // Recommended Portfolio (Updated to new Card Style)
                    RecommendedPortfolioCard(risk: goal.assignedPortfolio) {
                        selectedRisk = goal.assignedPortfolio
                        showDetails = true
                    }
                    .shadow(color: Color.shadowLight, radius: 4, x: 0, y: 2)
                    
                    // Why This Portfolio
                    // ... (Benefit Card remains same) ...
                    ForsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Why This Portfolio?")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BenefitRow(
                                    icon: "checkmark.seal.fill",
                                    text: "100% Sharia-compliant ETFs"
                                )
                                
                                BenefitRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    text: "Risk-adjusted for your profile"
                                )
                                
                                BenefitRow(
                                    icon: "target",
                                    text: "Optimized for your \(goal.durationYears)-year goal"
                                )
                                
                                BenefitRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    text: "Auto-rebalanced quarterly"
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                ForsaButton("Start Investing", style: .primary) {
                    onComplete()
                }
                
                Button(action: {
                    showSelection = true
                }) {
                    Text("Choose another portfolio")
                        .font(.calloutMedium)
                        .foregroundColor(.primaryPurple)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.backgroundPrimary)
        }
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $showSelection) {
            PortfolioSelectionView(recommendedRisk: goal.assignedPortfolio) { newRisk in
                // Update goal with new risk (In real app, you'd update state/binding)
                // For now, we just close sheet, ideally we update the view model
                showSelection = false
            }
        }
        .sheet(isPresented: $showDetails) {
            if let risk = selectedRisk {
                PortfolioDetailView(risk: risk)
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(.primaryGreen)
                .frame(width: 20)
            
            Text(text)
                .font(.caption1)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    PortfolioRecommendationView(
        goal: Goal(
            name: "Retirement Fund",
            targetAmount: 100000,
            currentValue: 0,
            targetDate: Calendar.current.date(byAdding: .year, value: 20, to: Date())!,
            assignedPortfolio: .growth
        ),
        riskScore: 65
    ) {}
}
