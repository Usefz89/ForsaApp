//
//  WelcomeOnboardingView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo
            ForsaLogo(size: .xlarge, style: .iconOnly)
                .padding(.bottom, 24)
            
            Text("Welcome to Forsa")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.bottom, 8)
            
            Text("Sharia-Compliant Robo-Investment")
                .font(.title3)
                .foregroundColor(.textSecondary)
                .padding(.bottom, 48)
            
            // Features
            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Passive Investing",
                    description: "Goal-based portfolios managed for you"
                )
                
                FeatureRow(
                    icon: "checkmark.seal.fill",
                    title: "100% Sharia-Compliant",
                    description: "Invest with confidence in halal ETFs"
                )
                
                FeatureRow(
                    icon: "target",
                    title: "Goal-Oriented",
                    description: "Plan for retirement, education, and more"
                )
                
                FeatureRow(
                    icon: "sparkles",
                    title: "Automated Zakat",
                    description: "Track and calculate your obligations"
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            
            Spacer()
            
            // CTA Button
            VStack(spacing: 16) {
                ForsaButton("Get Started", style: .primary) {
                    onContinue()
                }
                
                Text("Takes less than 3 minutes")
                    .font(.caption1)
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.backgroundPrimary)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primaryPurple)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    WelcomeOnboardingView {}
}
