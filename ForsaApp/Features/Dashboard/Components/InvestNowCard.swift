//
//  InvestNowCard.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

struct InvestNowCard: View {
    let availableBalance: String
    let portfolio: RiskLevel
    let onInvestTapped: () -> Void
    
    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                portfolioPreview
                investButton
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ready to invest")
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.primaryGreen)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ready to Invest!")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("You have \(availableBalance) available")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ready to invest. You have \(availableBalance) available")
    }
    
    // MARK: - Portfolio Preview
    
    private var portfolioPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invest in your \(portfolio.title) portfolio")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            allocationPreview
        }
    }
    
    private var allocationPreview: some View {
        HStack(spacing: 4) {
            ForEach(portfolio.allocations.prefix(4)) { allocation in
                VStack(spacing: 2) {
                    Text(allocation.ticker)
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text("\(Int(allocation.percentage * 100))%")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.backgroundSecondary)
                .cornerRadius(6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(allocation.ticker): \(Int(allocation.percentage * 100)) percent")
            }
        }
    }
    
    // MARK: - Invest Button
    
    private var investButton: some View {
        Button(action: onInvestTapped) {
            HStack {
                Image(systemName: "chart.pie.fill")
                Text("Invest Now")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.primaryGreen)
            .cornerRadius(10)
        }
        .accessibilityLabel("Invest now")
        .accessibilityHint("Invests your available balance in the \(portfolio.title) portfolio")
    }
}

// MARK: - Preview

#Preview {
    InvestNowCard(
        availableBalance: "$500.00",
        portfolio: .moderate,
        onInvestTapped: {}
    )
    .padding()
}

