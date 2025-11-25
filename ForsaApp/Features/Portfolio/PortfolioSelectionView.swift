//
//  PortfolioSelectionView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct PortfolioSelectionView: View {
    let recommendedRisk: RiskLevel
    let onSelect: (RiskLevel) -> Void
    
    @State private var selectedRisk: RiskLevel
    @State private var detailsRisk: RiskLevel // Non-optional to avoid nil issues
    @State private var showDetails = false
    @Environment(\.presentationMode) var presentationMode
    
    init(recommendedRisk: RiskLevel, onSelect: @escaping (RiskLevel) -> Void) {
        self.recommendedRisk = recommendedRisk
        self.onSelect = onSelect
        _selectedRisk = State(initialValue: recommendedRisk)
        _detailsRisk = State(initialValue: recommendedRisk) // Initialize with recommended
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Recommended Portfolio Card
                        RecommendedPortfolioCard(risk: recommendedRisk) {
                             detailsRisk = recommendedRisk
                             showDetails = true
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Choose portfolio")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Text("Explore our investment portfolios:")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            
                            VStack(spacing: 12) {
                                ForEach(RiskLevel.allCases, id: \.self) { risk in
                                    PortfolioSelectionCard(
                                        risk: risk,
                                        isSelected: selectedRisk == risk,
                                        isRecommended: risk == recommendedRisk
                                    ) {
                                        selectedRisk = risk
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Space for sticky button
                }
                
                // Sticky Button
                VStack {
                    Button(action: {
                        onSelect(selectedRisk)
                    }) {
                        Text("Confirm Selection")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryPurple) // Keeping existing app color
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color.white.opacity(0.9).ignoresSafeArea())
            }
            .navigationBarTitle("Choose Portfolio", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showDetails) {
                PortfolioDetailView(risk: detailsRisk)
            }
        }
    }
}

struct PortfolioSelectionCard: View {
    let risk: RiskLevel
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(alignment: .center, spacing: 16) {
                    // Radio Button
                    ZStack {
                        Circle()
                            .stroke(isSelected ? risk.color : Color.borderPrimary, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(risk.color)
                                .frame(width: 14, height: 14)
                        }
                    }
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(risk.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: risk.icon)
                            .font(.system(size: 20))
                            .foregroundColor(risk.color)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(risk.title)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            if isRecommended {
                                Text("★")
                                    .font(.caption)
                                    .foregroundColor(.warningYellow)
                            }
                        }
                        
                        HStack {
                            Text("Risk:")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            // Risk Meter using riskScore
                            HStack(spacing: 2) {
                                ForEach(0..<4) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(index < risk.riskScore ? risk.color : Color.gray.opacity(0.3))
                                        .frame(width: 16, height: 4)
                                }
                            }
                        }
                        
                        Text("Expected Return: \(risk.averageReturn)")
                            .font(.caption)
                            .foregroundColor(.primaryGreen)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .padding(.horizontal)
            
            Button(action: { showDetails = true }) {
                HStack {
                    Text("View Details")
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(risk.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? risk.color : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.shadowLight, radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showDetails) {
            PortfolioDetailView(risk: risk)
        }
    }
}

struct RecommendedPortfolioCard: View {
    let risk: RiskLevel
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.warningYellow)
                Text("Recommended for You")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: risk.icon)
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(risk.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(risk.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Stats row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Expected Return")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.7))
                            Text(risk.averageReturn)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time Horizon")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.7))
                            Text(risk.timeHorizon)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            Button(action: action) {
                HStack {
                    Text("View Details")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(risk.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(risk.color)
        .cornerRadius(16)
    }
}

