//
//  DashboardLoadingView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

struct DashboardLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            iconSection
            textSection
            loadingIndicator
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading portfolio data")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.primaryPurple.opacity(0.1))
                .frame(width: DashboardConstants.loadingIconSize, 
                       height: DashboardConstants.loadingIconSize)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 40))
                .foregroundColor(.primaryPurple)
                .rotationEffect(.degrees(isAnimating ? 10 : -10))
        }
        .accessibilityHidden(true)
    }
    
    private var textSection: some View {
        VStack(spacing: 8) {
            Text("Loading Portfolio")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text("Fetching your investment data...")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
    }
    
    private var loadingIndicator: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .primaryPurple))
            .scaleEffect(1.2)
            .accessibilityHidden(true)
    }
}

// MARK: - Investing Overlay

struct InvestingOverlay: View {
    let isVisible: Bool
    let portfolioTitle: String?
    
    var body: some View {
        Group {
            if isVisible {
                overlayContent
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
    }
    
    private var overlayContent: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Investing your funds...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let title = portfolioTitle {
                    Text("Building your \(title) portfolio")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(30)
            .background(Color.primaryPurple)
            .cornerRadius(16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Investing your funds. Please wait.")
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

// MARK: - Error Banner

struct DashboardErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.errorRed)
                .accessibilityHidden(true)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.errorRed)
                .lineLimit(2)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.errorRed.opacity(0.6))
                }
                .accessibilityLabel("Dismiss error")
            }
        }
        .padding()
        .background(Color.errorRed.opacity(0.1))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Create Account Card

struct CreateAccountCard: View {
    let onCreateAccount: () -> Void
    
    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .font(.title2)
                        .foregroundColor(.primaryPurple)
                        .accessibilityHidden(true)
                    
                    Text("Setup Your Trading Account")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                }
                
                Text("To start trading with real market data, create your sandbox account.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                Button(action: onCreateAccount) {
                    Text("Create Account")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primaryPurple)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Create trading account")
                .accessibilityHint("Sets up your sandbox account for trading")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("Loading") {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        DashboardLoadingView()
    }
}

#Preview("Investing Overlay") {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        Text("Dashboard Content")
        InvestingOverlay(isVisible: true, portfolioTitle: "Moderate")
    }
}

#Preview("Error Banner") {
    VStack {
        DashboardErrorBanner(
            message: "Failed to load portfolio data. Please try again.",
            onDismiss: {}
        )
        .padding()
        
        DashboardErrorBanner(
            message: "Network connection lost."
        )
        .padding()
    }
}

#Preview("Create Account") {
    CreateAccountCard(onCreateAccount: {})
        .padding()
}

