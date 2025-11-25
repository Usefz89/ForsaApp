//
//  PortfolioDetailView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI
import Charts

struct PortfolioDetailView: View {
    let risk: RiskLevel
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = PortfolioDetailViewModel()
    @State private var showingInvestSheet = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Messages
                    if let success = viewModel.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Header
                    portfolioHeader
                    
                    // Key Statistics
                    keyStatisticsSection
                    
                    // Asset Allocation Pie Chart
                    allocationChartSection
                    
                    // Fund Distribution List
                    fundDistributionSection
                    
                    // Portfolio Suitability
                    suitabilitySection
                    
                    // Confirm Button
                    selectPortfolioButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadAccountData()
                }
            }
            .sheet(isPresented: $showingInvestSheet) {
                InvestSheet(viewModel: viewModel, riskLevel: risk)
            }
        }
    }
    
    // MARK: - Portfolio Header
    
    private var portfolioHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Portfolio Icon
                ZStack {
                    Circle()
                        .fill(risk.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: risk.icon)
                        .font(.title2)
                        .foregroundColor(risk.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(risk.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    // Risk Level Indicator
                    HStack(spacing: 4) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index < risk.riskScore ? risk.color : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 6)
                        }
                        Text("Risk Level \(risk.riskScore)/4")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                            .padding(.leading, 4)
                    }
                }
                
                Spacer()
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.textTertiary)
                }
            }
            
            // Description
            Text(risk.detailedDescription)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.backgroundCard)
        .cornerRadius(16)
    }
    
    // MARK: - Key Statistics
    
    private var keyStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Statistics")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Expected Return",
                    value: risk.averageReturn,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .primaryGreen
                )
                
                StatCard(
                    title: "Volatility",
                    value: risk.standardDeviation,
                    icon: "waveform.path.ecg",
                    color: .primaryOrange
                )
                
                StatCard(
                    title: "Max Drawdown",
                    value: "\(String(format: "%.0f", risk.statistics.maxDrawdown * 100))%",
                    icon: "arrow.down.right",
                    color: .errorRed
                )
                
                StatCard(
                    title: "Expense Ratio",
                    value: risk.totalExpenseRatioFormatted,
                    icon: "percent",
                    color: .primaryBlue
                )
                
                StatCard(
                    title: "Time Horizon",
                    value: risk.timeHorizon,
                    icon: "clock",
                    color: .primaryPurple
                )
                
                StatCard(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", risk.statistics.sharpeRatio),
                    icon: "gauge",
                    color: .primaryGreen
                )
            }
        }
    }
    
    // MARK: - Allocation Chart
    
    private var allocationChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset Allocation")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            ForsaCard {
                VStack(spacing: 20) {
                    // Donut Chart
                    ZStack {
                        Chart(risk.allocations) { allocation in
                            SectorMark(
                                angle: .value("Percentage", allocation.percentage),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(allocation.assetClass.color)
                        }
                        .frame(height: 200)
                        
                        // Center text showing dominant asset class
                        VStack(spacing: 4) {
                            let dominantClass = risk.allocationByClass.max { $0.value < $1.value }
                            if let dominant = dominantClass {
                                Text(dominant.key.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text("\(Int(dominant.value * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    
                    // Legend
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Array(risk.allocationByClass.sorted { $0.value > $1.value }), id: \.key) { assetClass, percentage in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(assetClass.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(assetClass.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                
                                Spacer()
                                
                                Text("\(Int(percentage * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Fund Distribution
    
    private var fundDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fund Distribution")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(risk.allocations.sorted { $0.percentage > $1.percentage }) { allocation in
                    FundDetailRow(allocation: allocation)
                }
            }
        }
    }
    
    // MARK: - Suitability
    
    private var suitabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Best Suited For")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            ForsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(risk.suitableFor, id: \.self) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.primaryGreen)
                            
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Select Button
    
    private var selectPortfolioButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                coordinator.updateSelectedPortfolio(risk)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Select This Portfolio")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(risk.color)
                    .cornerRadius(12)
            }
            
            if viewModel.accountCash > 0 {
                Button(action: {
                    showingInvestSheet = true
                }) {
                    Text("Invest Now (\(CurrencyService.shared.formatUSD(viewModel.accountCash)) available)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(risk.color)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
    }
}

struct FundDetailRow: View {
    let allocation: AssetAllocation
    
    var body: some View {
        HStack(spacing: 12) {
            // Asset Class Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(allocation.assetClass.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: allocation.assetClass.icon)
                    .font(.body)
                    .foregroundColor(allocation.assetClass.color)
            }
            
            // Fund Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(allocation.ticker)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("•")
                        .foregroundColor(.textSecondary)
                    
                    Text(allocation.assetClass.rawValue)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Text(allocation.fullName)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Percentage
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(allocation.percentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("ER: \(String(format: "%.2f", allocation.expenseRatio * 100))%")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(12)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .shadow(color: Color.shadowLight, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Invest Sheet

struct InvestSheet: View {
    @ObservedObject var viewModel: PortfolioDetailViewModel
    let riskLevel: RiskLevel
    @Environment(\.presentationMode) var presentationMode
    @State private var amountKD: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Invest in \(riskLevel.title)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading) {
                    Text("Amount to Invest (KWD)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $amountKD)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                .padding()
                
                if let amount = Double(amountKD) {
                    VStack(spacing: 4) {
                        Text("Equivalent to")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(CurrencyService.shared.formatUSD(CurrencyService.shared.convertKWDtoUSD(amount)))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    if let amount = Double(amountKD) {
                        Task {
                            await viewModel.invest(amountKD: amount, riskLevel: riskLevel)
                            if viewModel.errorMessage == nil {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }) {
                    if viewModel.isInvesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Confirm Investment")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(riskLevel.color)
                .cornerRadius(10)
                .disabled(amountKD.isEmpty || Double(amountKD) == nil || viewModel.isInvesting)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Preview

#Preview {
    PortfolioDetailView(risk: .moderate)
        .environmentObject(AppCoordinator())
}
