//
//  SelectedPortfolioCard.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

struct SelectedPortfolioCard: View {
    let portfolio: RiskLevel
    let onInfoTapped: () -> Void
    
    var body: some View {
        ForsaCard {
            VStack(spacing: 16) {
                headerSection
                
                Divider()
                
                allocationSummary
                
                expectedReturnsSection
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your \(portfolio.title) portfolio")
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            portfolioIcon
            portfolioInfo
            Spacer()
            infoButton
        }
    }
    
    private var portfolioIcon: some View {
        ZStack {
            Circle()
                .fill(portfolio.color.opacity(0.15))
                .frame(width: DashboardConstants.portfolioIconSize, 
                       height: DashboardConstants.portfolioIconSize)
            
            Image(systemName: portfolio.icon)
                .font(.title2)
                .foregroundColor(portfolio.color)
        }
        .accessibilityHidden(true)
    }
    
    private var portfolioInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(portfolio.title)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            riskLevelIndicator
        }
    }
    
    private var riskLevelIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<DashboardConstants.maxRiskLevel, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < portfolio.riskScore ? portfolio.color : Color.gray.opacity(0.3))
                    .frame(width: DashboardConstants.riskIndicatorWidth, 
                           height: DashboardConstants.riskIndicatorHeight)
            }
            Text("Risk Level")
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .accessibilityLabel("Risk level \(portfolio.riskScore) out of \(DashboardConstants.maxRiskLevel)")
    }
    
    private var infoButton: some View {
        Button(action: onInfoTapped) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundColor(.textSecondary)
        }
        .accessibilityLabel("Portfolio details")
        .accessibilityHint("Shows full portfolio breakdown and allocation")
    }
    
    // MARK: - Allocation Summary
    
    private var allocationSummary: some View {
        HStack(spacing: 0) {
            ForEach(Array(portfolio.allocationByClass.sorted { $0.value > $1.value }.prefix(3)), id: \.key) { assetClass, percentage in
                VStack(spacing: 4) {
                    Image(systemName: assetClass.icon)
                        .font(.caption)
                        .foregroundColor(assetClass.color)
                        .accessibilityHidden(true)
                    
                    Text("\(Int(percentage * 100))%")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(assetClass.rawValue)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Int(percentage * 100)) percent in \(assetClass.rawValue)")
            }
        }
    }
    
    // MARK: - Expected Returns
    
    private var expectedReturnsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Expected Return")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                Text(portfolio.averageReturn)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Expected return: \(portfolio.averageReturn)")
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Time Horizon")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                Text(portfolio.timeHorizon)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Time horizon: \(portfolio.timeHorizon)")
        }
        .padding(.top, 4)
    }
}

// MARK: - No Portfolio Card

struct NoPortfolioCard: View {
    let onChoosePortfolio: () -> Void
    
    var body: some View {
        ForsaCard {
            VStack(spacing: 16) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 40))
                    .foregroundColor(.primaryPurple.opacity(0.6))
                    .accessibilityHidden(true)
                
                Text("No Portfolio Selected")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Choose an investment strategy to automatically invest your funds based on your risk tolerance.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: onChoosePortfolio) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Choose Portfolio")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primaryPurple)
                    .cornerRadius(10)
                }
                .accessibilityLabel("Choose portfolio")
                .accessibilityHint("Opens portfolio selection to choose your investment strategy")
            }
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview("Selected Portfolio") {
    SelectedPortfolioCard(
        portfolio: .moderate,
        onInfoTapped: {}
    )
    .padding()
}

#Preview("No Portfolio") {
    NoPortfolioCard(onChoosePortfolio: {})
        .padding()
}

