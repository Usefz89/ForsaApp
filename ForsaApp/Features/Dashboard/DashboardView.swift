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
    @State private var showingAddFunds = false
    @State private var showingWithdraw = false
    @State private var isInvesting = false
    @State private var showInvestmentResult = false
    @State private var showingPortfolioSelection = false
    @State private var showingPortfolioDetail = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if viewModel.needsAccountCreation {
                        createAccountCard
                    }
                    
                    // Header with user greeting
                    headerView
                    
                    // Current Portfolio Section - Always show
                    currentPortfolioSection
                    
                    // Prompt to invest if cash available but no positions
                    if viewModel.canInvestNow && coordinator.selectedPortfolio != nil {
                        investNowCard
                    }

                    // Portfolio Progress Chart
                    portfolioProgressSection
                    
                    // Holdings Section (if user has positions)
                    if viewModel.hasPositions {
                        holdingsSection
                    }

                    // Cash Balance & Actions
                    cashBalanceSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Account for tab bar
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showingAddFunds, onDismiss: {
                Task { await viewModel.refreshData() }
            }) {
                DepositFlowView()
                    .environmentObject(coordinator)
            }
            .sheet(isPresented: $showingWithdraw, onDismiss: {
                Task { await viewModel.refreshData() }
            }) {
                WithdrawFlowView()
            }
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
            Task {
                await viewModel.checkAccountStatus()
            }
        }
        .overlay(isLoadingOverlay)
        .overlay(investingOverlay)
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
                // Show selected portfolio
                ForsaCard {
                    VStack(spacing: 16) {
                        // Portfolio Header
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
                        
                        // Allocation Summary by Asset Class
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
            } else {
                // No portfolio selected - prompt to choose one
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
        }
    }
    
    private var isLoadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Processing...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
    }
    
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
                    
                    // Portfolio allocation preview
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
                    Task {
                        await investNow()
                    }
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
        
        // Refresh data regardless
        await viewModel.refreshData()
    }
    
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
                        Task {
                            await viewModel.createAccountForUser(user: user)
                        }
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

            HStack(spacing: 12) {
                // Profile
                Button(action: {}) {
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
            }
        }
        .padding(.top, 10)
    }

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
                    
                    // Detailed Stats Stack
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
                        Chart(viewModel.chartData) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Value", data.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primaryPurple, .primaryPurpleDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", data.date),
                                y: .value("Value", data.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primaryPurple.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 200)
                        .chartYAxis(.hidden)
                        .chartXAxis(.hidden)
                    } else {
                        Text("No chart data available")
                            .font(.caption)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.backgroundSecondary)
                    }
                    
                    // Timeframe Selector
                    HStack {
                        ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                            Button(action: {
                                withAnimation {
                                    viewModel.selectedTimeframe = timeframe
                                    Task { await viewModel.refreshData() }
                                }
                            }) {
                                Text(timeframe.displayName)
                                    .font(.caption1)
                                    .fontWeight(.medium)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(viewModel.selectedTimeframe == timeframe ? Color.primaryPurple.opacity(0.1) : Color.clear)
                                    .foregroundColor(viewModel.selectedTimeframe == timeframe ? .primaryPurple : .textSecondary)
                                    .cornerRadius(8)
                            }
                            if timeframe != TimeFrame.allCases.last {
                                Spacer()
                            }
                        }
                    }
                }
                .padding(4)
            }
        }
    }

    private var cashBalanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Cash & Actions")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            ForsaCard {
                VStack(spacing: 20) {
                    NavigationLink(destination: CashReserveView().environmentObject(coordinator)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Available Balance")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)
                                Text(viewModel.availableBalanceText)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                            }
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .background(Color.borderLight)
                    
                    HStack(spacing: 16) {
                        Button(action: { showingAddFunds = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Funds")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryPurple)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.needsAccountCreation)
                        .opacity(viewModel.needsAccountCreation ? 0.5 : 1)
                        
                        Button(action: { showingWithdraw = true }) {
                            HStack {
                                Image(systemName: "arrow.down")
                                Text("Withdraw")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryPurple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryPurple.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Holding Row View

struct HoldingRow: View {
    let position: AlpacaPosition
    
    private var gainLoss: Double {
        position.marketValueValue - (Double(position.costBasis) ?? 0)
    }
    
    private var gainLossPercentage: Double {
        let costBasis = Double(position.costBasis) ?? 0
        guard costBasis > 0 else { return 0 }
        return (gainLoss / costBasis) * 100
    }
    
    private var isPositive: Bool {
        gainLoss >= 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Symbol Badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(String(position.symbol.prefix(2)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryPurple)
            }
            
            // Symbol & Quantity
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("\(String(format: "%.4f", position.qtyValue)) shares")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Value & Change
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", position.marketValueValue))")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 2) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    
                    Text("\(isPositive ? "+" : "")\(String(format: "%.2f", gainLossPercentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(isPositive ? .gainGreen : .lossRed)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Portfolio Selection Sheet

struct PortfolioSelectionSheet: View {
    let currentPortfolio: RiskLevel?
    let onSelect: (RiskLevel) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPortfolio: RiskLevel?
    
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
                                isCurrent: currentPortfolio == risk
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedPortfolio = risk
                                }
                            }
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
        }
    }
}

struct PortfolioOptionCard: View {
    let risk: RiskLevel
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? risk.color : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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
        .background(Color.backgroundSecondary)
        .cornerRadius(6)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AppCoordinator())
}
