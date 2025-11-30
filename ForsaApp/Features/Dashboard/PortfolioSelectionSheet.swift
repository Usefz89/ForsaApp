//
//  PortfolioSelectionSheet.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct PortfolioSelectionSheet: View {
    let currentPortfolio: RiskLevel?
    let onSelect: (RiskLevel) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPortfolio: RiskLevel?
    @State private var detailsRisk: RiskLevel?
    @State private var showDetails = false
    
    init(currentPortfolio: RiskLevel?, onSelect: @escaping (RiskLevel) -> Void) {
        self.currentPortfolio = currentPortfolio
        self.onSelect = onSelect
        _selectedPortfolio = State(initialValue: currentPortfolio)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Choose Your Strategy")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Select an investment portfolio that matches your risk tolerance and goals")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    
                    // Portfolio Options
                    VStack(spacing: 12) {
                        ForEach(RiskLevel.allCases, id: \.self) { risk in
                            PortfolioOptionCard(
                                risk: risk,
                                isSelected: selectedPortfolio == risk,
                                isCurrent: currentPortfolio == risk,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPortfolio = risk
                                    }
                                },
                                onInfoTapped: {
                                    detailsRisk = risk
                                    showDetails = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100)
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if let selected = selectedPortfolio {
                        VStack(spacing: 4) {
                            Text("Selected: \(selected.title)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("Expected Return: \(selected.averageReturn)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryGreen)
                        }
                    }
                    
                    Button(action: {
                        if let selected = selectedPortfolio {
                            onSelect(selected)
                        }
                    }) {
                        Text("Confirm Selection")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedPortfolio != nil ? Color.primaryPurple : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(selectedPortfolio == nil)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.backgroundPrimary)
            }
            .sheet(isPresented: $showDetails) {
                if let risk = detailsRisk {
                    PortfolioDetailView(risk: risk)
                }
            }
        }
    }
}

// MARK: - Portfolio Option Card

struct PortfolioOptionCard: View {
    let risk: RiskLevel
    let isSelected: Bool
    let isCurrent: Bool
    let onSelect: () -> Void
    let onInfoTapped: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Selection indicator
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
                            .font(.title3)
                            .foregroundColor(risk.color)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(risk.title)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            if isCurrent {
                                Text("CURRENT")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(risk.color)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(risk.description)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Info Button
                    Button(action: onInfoTapped) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(risk.color.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Stats Row
                HStack(spacing: 16) {
                    StatBadge(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Return",
                        value: risk.averageReturn,
                        color: .primaryGreen
                    )
                    
                    StatBadge(
                        icon: "waveform.path.ecg",
                        label: "Volatility",
                        value: risk.standardDeviation,
                        color: .primaryOrange
                    )
                    
                    StatBadge(
                        icon: "clock",
                        label: "Horizon",
                        value: risk.timeHorizon,
                        color: .primaryBlue
                    )
                }
            }
            .padding(16)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? risk.color : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.textSecondary)
            }
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.backgroundTertiary)
        .cornerRadius(6)
    }
}

