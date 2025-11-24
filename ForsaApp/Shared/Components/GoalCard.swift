//
//  GoalCard.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct GoalCard: View {
    let goal: Goal
    
    var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(goal.currentValue / goal.targetAmount, 1.0)
    }
    
    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(goal.assignedPortfolio.title)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.0f", goal.currentValue))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                }
                
                // Progress Bar
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(.primaryPurple)
                    
                    HStack {
                        Text("\(String(format: "%.0f%%", progress * 100))")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        Text("Target: $\(String(format: "%.0f", goal.targetAmount))")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
}

