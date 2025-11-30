//
//  PortfolioSelectionView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct PortfolioSelectionView: View {
    let recommendedRisk: RiskLevel
    let alternativePortfolios: [RiskLevel]
    let onSelect: (RiskLevel) -> Void
    
    @State private var selectedRisk: RiskLevel
    @State private var detailsRisk: RiskLevel // Non-optional to avoid nil issues
    @State private var showDetails = false
    @Environment(\.presentationMode) var presentationMode
    
    init(recommendedRisk: RiskLevel, alternativePortfolios: [RiskLevel] = [], onSelect: @escaping (RiskLevel) -> Void) {
        self.recommendedRisk = recommendedRisk
        self.alternativePortfolios = alternativePortfolios
        self.onSelect = onSelect
        _selectedRisk = State(initialValue: recommendedRisk)
        _detailsRisk = State(initialValue: recommendedRisk) // Initialize with recommended
    }
    
    /// Check if a portfolio is an alternative (but not recommended)
    private func isAlternative(_ risk: RiskLevel) -> Bool {
        alternativePortfolios.contains(risk) && risk != recommendedRisk
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
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
                                        isRecommended: risk == recommendedRisk,
                                        isAlternative: isAlternative(risk),
                                        onSelect: {
                                            selectedRisk = risk
                                        },
                                        onInfoTapped: {
                                            detailsRisk = risk
                                            showDetails = true
                                        }
                                    )
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
                            .background(Color.primaryPurple)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .background(
                    Color.backgroundPrimary
                        .opacity(0.95)
                        .ignoresSafeArea()
                )
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
    var isAlternative: Bool = false
    let onSelect: () -> Void
    let onInfoTapped: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
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
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: risk.icon)
                        .font(.system(size: 18))
                        .foregroundColor(risk.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(risk.title)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        if isRecommended {
                            Text("★ RECOMMENDED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.warningYellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.warningYellow.opacity(0.15))
                                .cornerRadius(4)
                        } else if isAlternative {
                            Text("SUITABLE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.primaryGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primaryGreen.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("Risk:")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        // Risk Meter using riskScore
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index < risk.riskScore ? risk.color : Color.gray.opacity(0.3))
                                    .frame(width: 14, height: 4)
                            }
                        }
                        
                        Spacer()
                        
                        Text(risk.averageReturn)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryGreen)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Info Button
                Button(action: onInfoTapped) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(risk.color.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(14)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? risk.color : (isAlternative ? risk.color.opacity(0.3) : Color.borderPrimary), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.shadowLight, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
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
                    Image(systemName: "info.circle")
                        .font(.caption)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(risk.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.backgroundPrimary)
                .cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(risk.color)
        .cornerRadius(16)
    }
}

