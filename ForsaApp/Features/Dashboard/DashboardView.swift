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
                        // If needsAccountCreation is true, it means we might be in Broker Mode
                        // and the user hasn't created a sub-account yet.
                        // However, we now try to handle this during Sign Up.
                        // If this is still true here, something might have failed,
                        // so we offer a retry button.
                        createAccountCard
                    }
                    
                    // Header with user greeting
                    headerView
                    
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
                // Refresh data after deposit
                Task {
                    await viewModel.refreshData()
                }
            }) {
                DepositFlowView()
                    .environmentObject(coordinator)
            }
            .sheet(isPresented: $showingWithdraw, onDismiss: {
                // Refresh data after withdraw
                Task {
                    await viewModel.refreshData()
                }
            }) {
                WithdrawFlowView()
            }
            .sheet(isPresented: $showInvestmentResult) {
                if let result = coordinator.portfolioInvestmentResult {
                    InvestmentResultView(result: result, depositAmount: viewModel.cashBalance) {
                        showInvestmentResult = false
                        Task {
                            await viewModel.refreshData()
                        }
                    }
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

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AppCoordinator())
}
