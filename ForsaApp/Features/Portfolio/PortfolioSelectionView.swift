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
    @State private var detailsRisk: RiskLevel?
    @State private var showDetails = false
    @Environment(\.presentationMode) var presentationMode
    
    init(recommendedRisk: RiskLevel, onSelect: @escaping (RiskLevel) -> Void) {
        self.recommendedRisk = recommendedRisk
        self.onSelect = onSelect
        _selectedRisk = State(initialValue: recommendedRisk)
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
                if let risk = detailsRisk {
                    PortfolioDetailView(risk: risk)
                }
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
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .primaryPurple : .textTertiary)
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.backgroundSecondary)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: iconName(for: risk))
                            .font(.system(size: 20))
                            .foregroundColor(.primaryPurple)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(risk.title)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            Text("Risk level:")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            // Risk Meter
                            HStack(spacing: 2) {
                                ForEach(0..<4) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colorForRiskMeter(index: index))
                                        .frame(width: 20, height: 4)
                                }
                            }
                        }
                        
                        Text("Average Return: \(averageReturnRange(for: risk))")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    if isRecommended {
                        // Maybe a small star badge?
                        Image(systemName: "star.fill")
                            .foregroundColor(.warningYellow)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .padding(.horizontal)
            
            Button(action: { showDetails = true }) {
                Text("View Details")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen) // Changed to Green/Teal as requested or keeping theme
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.shadowLight, radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showDetails) {
            PortfolioDetailView(risk: risk)
        }
    }
    
    private func iconName(for risk: RiskLevel) -> String {
        switch risk {
        case .conservative: return "shield.fill"
        case .moderate: return "scale.3d"
        case .growth: return "chart.xyaxis.line"
        case .aggressive: return "flame.fill"
        }
    }
    
    private func averageReturnRange(for risk: RiskLevel) -> String {
        switch risk {
        case .conservative: return "4% - 6%"
        case .moderate: return "6% - 8%"
        case .growth: return "8% - 10%"
        case .aggressive: return "10% - 12%"
        }
    }
    
    private func colorForRiskMeter(index: Int) -> Color {
        let riskIndex: Int
        switch risk {
        case .conservative: riskIndex = 0
        case .moderate: riskIndex = 1
        case .growth: riskIndex = 2
        case .aggressive: riskIndex = 3
        }
        
        return index <= riskIndex ? Color.primaryGreen : Color.gray.opacity(0.3)
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
                Text("Recommended Portfolio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(risk.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Based on the answers that you have brought, we advise you to invest in \(risk.title) portfolio")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 8)
            }
            
            Button(action: action) {
                Text("View Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.primaryPurple) // Using our main brand color
        .cornerRadius(16)
    }
}

