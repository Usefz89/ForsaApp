//
//  DashboardView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = DashboardViewModel()
    @State private var isInvesting = false
    @State private var showInvestmentResult = false
    @State private var showingPortfolioSelection = false
    @State private var showingPortfolioDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    portfolioLoadingView
                } else {
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showInvestmentResult) {
                if let result = coordinator.portfolioInvestmentResult {
                    InvestmentResultView(result: result, depositAmount: viewModel.cashBalance) {
                        showInvestmentResult = false
                        Task { await viewModel.refreshData() }
                    }
                }
            }
            .sheet(isPresented: $showingPortfolioSelection) {
                PortfolioSelectionSheet(
                    currentPortfolio: coordinator.selectedPortfolio,
                    onSelect: { newPortfolio in
                        coordinator.updateSelectedPortfolio(newPortfolio)
                        showingPortfolioSelection = false
                    }
                )
            }
            .sheet(isPresented: $showingPortfolioDetail) {
                if let portfolio = coordinator.selectedPortfolio {
                    PortfolioDetailView(risk: portfolio)
                }
            }
        }
        .onAppear {
            Task { await viewModel.checkAccountStatus() }
        }
        .overlay(investingOverlay)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
                
                if viewModel.needsAccountCreation {
                    createAccountCard
                }
                
                headerView
                currentPortfolioSection
                
                if viewModel.canInvestNow && coordinator.selectedPortfolio != nil {
                    investNowCard
                }

                portfolioProgressSection
                
                if viewModel.hasPositions {
                    holdingsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Loading View
    
    private var portfolioLoadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Loading Portfolio")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Fetching your investment data...")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryPurple))
                .scaleEffect(1.2)
            
            Spacer()
        }
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            ForsaLogo(size: .small, style: .iconOnly)

            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning,")
                    .font(.callout)
                    .foregroundColor(.textSecondary)

                Text(coordinator.currentUser?.firstName ?? "Investor")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            if let user = coordinator.currentUser {
                Circle()
                    .fill(Color.gradientPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(user.initials)
                            .font(.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Current Portfolio Section
    
    private var currentPortfolioSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Investment Strategy")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                
                Button(action: { showingPortfolioSelection = true }) {
                    Text("Change")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryPurple)
                }
            }
            
            if let portfolio = coordinator.selectedPortfolio {
                selectedPortfolioCard(portfolio)
            } else {
                noPortfolioCard
            }
        }
    }
    
    private func selectedPortfolioCard(_ portfolio: RiskLevel) -> some View {
        ForsaCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(portfolio.color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: portfolio.icon)
                            .font(.title2)
                            .foregroundColor(portfolio.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(portfolio.title)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<4) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index < portfolio.riskScore ? portfolio.color : Color.gray.opacity(0.3))
                                    .frame(width: 16, height: 4)
                            }
                            Text("Risk Level")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showingPortfolioDetail = true }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Divider()
                
                // Allocation Summary
                HStack(spacing: 0) {
                    ForEach(Array(portfolio.allocationByClass.sorted { $0.value > $1.value }.prefix(3)), id: \.key) { assetClass, percentage in
                        VStack(spacing: 4) {
                            Image(systemName: assetClass.icon)
                                .font(.caption)
                                .foregroundColor(assetClass.color)
                            
                            Text("\(Int(percentage * 100))%")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            Text(assetClass.rawValue)
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Expected Returns
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
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var noPortfolioCard: some View {
        ForsaCard {
            VStack(spacing: 16) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 40))
                    .foregroundColor(.primaryPurple.opacity(0.6))
                
                Text("No Portfolio Selected")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Choose an investment strategy to automatically invest your funds based on your risk tolerance.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { showingPortfolioSelection = true }) {
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
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Invest Now Card
    
    private var investNowCard: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.primaryGreen)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to Invest!")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text("You have \(viewModel.availableBalanceText) available")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                
                if let portfolio = coordinator.selectedPortfolio {
                    Text("Invest in your \(portfolio.title) portfolio")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
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
                        }
                    }
                }
                
                Button(action: {
                    Task { await investNow() }
                }) {
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
            }
        }
    }
    
    // MARK: - Portfolio Progress Section
    
    private var portfolioProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Portfolio Performance")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            ForsaCard {
                VStack(alignment: .leading, spacing: 20) {
                    // Value and Change
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Portfolio Value")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                        
                        Text(viewModel.portfolioValueText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isPortfolioPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption1)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.isPortfolioPositive ? .gainGreen : .lossRed)
                            
                            Text(viewModel.portfolioChangeText)
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.isPortfolioPositive ? .gainGreen : .lossRed)
                            
                            Text("All time")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Invested")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                            Text("$\(String(format: "%.2f", viewModel.totalInvested))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gain/Loss")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                            Text(viewModel.totalGainLossText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.isPortfolioPositive ? .gainGreen : .lossRed)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Balance")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                            Text(viewModel.availableBalanceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 8)
                    
                    // Chart
                    if !viewModel.chartData.isEmpty {
                        TradingViewChart(
                            chartData: viewModel.chartData,
                            selectedTimeframe: viewModel.selectedTimeframe,
                            isPositive: viewModel.isPortfolioPositive
                        )
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundColor(.textTertiary)
                            Text("No chart data available")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundSecondary.opacity(0.5))
                        .cornerRadius(12)
                    }
                    
                    // Timeframe Selector
                    timeframeSelector
                }
                .padding(4)
            }
        }
    }
    
    private var timeframeSelector: some View {
        HStack(spacing: 4) {
            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedTimeframe = timeframe
                        Task { await viewModel.refreshData() }
                    }
                }) {
                    Text(timeframe.displayName)
                        .font(.system(size: 12, weight: viewModel.selectedTimeframe == timeframe ? .bold : .medium))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            ZStack {
                                if viewModel.selectedTimeframe == timeframe {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.isPortfolioPositive ? Color.gainGreen : Color.lossRed)
                                }
                            }
                        )
                        .foregroundColor(viewModel.selectedTimeframe == timeframe ? .white : .textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - Holdings Section
    
    private var holdingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Holdings")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                
                Text("\(viewModel.positions.count) assets")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            ForsaCard {
                VStack(spacing: 12) {
                    ForEach(viewModel.positions) { position in
                        HoldingRow(position: position)
                        
                        if position.id != viewModel.positions.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Create Account Card
    
    private var createAccountCard: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Setup Your Trading Account")
                    .font(.headline)
                Text("To start trading with real market data, create your sandbox account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    if let user = coordinator.currentUser {
                        Task { await viewModel.createAccountForUser(user: user) }
                    }
                }) {
                    Text("Create Account")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primaryPurple)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Investing Overlay
    
    private var investingOverlay: some View {
        Group {
            if isInvesting || coordinator.isInvestingPortfolio {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Investing your funds...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let portfolio = coordinator.selectedPortfolio {
                            Text("Building your \(portfolio.title) portfolio")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(30)
                    .background(Color.primaryPurple)
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Invest Now Action
    
    private func investNow() async {
        isInvesting = true
        
        do {
            if let result = try await coordinator.investInPortfolio() {
                await MainActor.run {
                    isInvesting = false
                    if result.successCount > 0 {
                        showInvestmentResult = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                isInvesting = false
                viewModel.errorMessage = "Investment failed: \(error.localizedDescription)"
            }
        }
        
        await viewModel.refreshData()
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AppCoordinator())
}
