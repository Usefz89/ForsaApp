//
//  GoalCreationView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct GoalCreationView: View {
    let riskScore: Int
    let onComplete: (Goal) -> Void
    
    @State private var goalName = ""
    @State private var targetAmount = ""
    @State private var durationYears = 5
    @State private var selectedPreset: InvestmentGoal?
    @State private var showingPresets = false
    
    private let durations = Array(1...30)
    
    private var isValid: Bool {
        !goalName.isEmpty && !targetAmount.isEmpty && Double(targetAmount) != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Create Your First Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("What are you investing for?")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Preset Goals
                    ForsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Popular Goals")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(InvestmentGoal.presetGoals.prefix(4)) { preset in
                                    PresetGoalButton(goal: preset) {
                                        selectedPreset = preset
                                        goalName = preset.name
                                        durationYears = preset.suggestedDuration
                                    }
                                }
                            }
                        }
                    }
                    
                    // Goal Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Name")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("e.g., Retirement Fund", text: $goalName)
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                            .foregroundColor(.textPrimary)
                    }
                    
                    // Target Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Amount (KWD)")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("e.g., 100000", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                            .foregroundColor(.textPrimary)
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Horizon")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)
                        
                        Picker("Duration", selection: $durationYears) {
                            ForEach(durations, id: \.self) { years in
                                Text("\(years) \(years == 1 ? "year" : "years")")
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            
            // Continue Button
            VStack(spacing: 8) {
                ForsaButton("Continue", style: .primary, isDisabled: !isValid) {
                    createGoal()
                }
                
                Text("We'll recommend the best portfolio for your goal")
                    .font(.caption1)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.backgroundPrimary)
        }
        .background(Color.backgroundPrimary)
    }
    
    private func createGoal() {
        guard let amount = Double(targetAmount) else { return }
        
        let portfolio = RiskEngine.shared.recommendPortfolio(
            userRiskScore: riskScore,
            goalDuration: durationYears
        )
        
        let targetDate = Calendar.current.date(byAdding: .year, value: durationYears, to: Date()) ?? Date()
        
        let goal = Goal(
            name: goalName,
            targetAmount: amount,
            currentValue: 0,
            targetDate: targetDate,
            assignedPortfolio: portfolio
        )
        
        onComplete(goal)
    }
}

struct PresetGoalButton: View {
    let goal: InvestmentGoal
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: goal.iconName)
                    .font(.title2)
                    .foregroundColor(.primaryPurple)
                
                Text(goal.name)
                    .font(.caption1)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
}

#Preview {
    GoalCreationView(riskScore: 65) { _ in }
}
