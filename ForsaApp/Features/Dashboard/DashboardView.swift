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
    
    // MARK: - State
    @State private var isInvesting = false
    @State private var showInvestmentResult = false
    @State private var showingPortfolioSelection = false
    @State private var showingPortfolioDetail = false
    @State private var contentAppeared = false

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    DashboardLoadingView()
                        .transition(.opacity)
                } else {
                    mainContent
                        .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showInvestmentResult) {
                investmentResultSheet
            }
            .sheet(isPresented: $showingPortfolioSelection) {
                portfolioSelectionSheet
            }
            .sheet(isPresented: $showingPortfolioDetail) {
                portfolioDetailSheet
            }
        }
        .onAppear(perform: handleOnAppear)
        .overlay(investingOverlay)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: DashboardConstants.cardSpacing) {
                if let error = viewModel.errorMessage {
                    DashboardErrorBanner(message: error) {
                        viewModel.clearError()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if viewModel.needsAccountCreation {
                    CreateAccountCard {
                        if let user = coordinator.currentUser {
                            Task { await viewModel.createAccountForUser(user: user) }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                DashboardHeader(
                    userName: coordinator.currentUser?.firstName,
                    userInitials: coordinator.currentUser?.initials
                )
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)
                
                currentPortfolioSection
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: DashboardConstants.springResponse, 
                                       dampingFraction: DashboardConstants.springDamping)
                               .delay(DashboardConstants.cardAppearanceDelay), 
                               value: contentAppeared)
                
                if viewModel.canInvestNow, let portfolio = coordinator.selectedPortfolio {
                    InvestNowCard(
                        availableBalance: viewModel.availableBalanceText,
                        portfolio: portfolio,
                        onInvestTapped: { Task { await investNow() } }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: DashboardConstants.springResponse, 
                                       dampingFraction: DashboardConstants.springDamping)
                               .delay(DashboardConstants.cardAppearanceDelay * 2), 
                               value: contentAppeared)
                }

                portfolioPerformanceSection
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: DashboardConstants.springResponse, 
                                       dampingFraction: DashboardConstants.springDamping)
                               .delay(DashboardConstants.cardAppearanceDelay * 3), 
                               value: contentAppeared)
                
                if viewModel.hasPendingOrders {
                    pendingOrdersSection
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                if viewModel.hasPositions {
                    holdingsSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: DashboardConstants.springResponse, 
                                           dampingFraction: DashboardConstants.springDamping)
                                   .delay(DashboardConstants.cardAppearanceDelay * 4), 
                                   value: contentAppeared)
                }
            }
            .padding(.horizontal, DashboardConstants.horizontalPadding)
            .padding(.bottom, DashboardConstants.tabBarBottomPadding)
        }
        .refreshable {
            await handleRefresh()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentAppeared = true
            }
        }
    }
    
    // MARK: - Current Portfolio Section
    
    private var currentPortfolioSection: some View {
        VStack(spacing: DashboardConstants.sectionSpacing) {
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
                .accessibilityLabel("Change portfolio")
                .accessibilityHint("Opens portfolio selection")
            }
            
            if let portfolio = coordinator.selectedPortfolio {
                SelectedPortfolioCard(
                    portfolio: portfolio,
                    onInfoTapped: { showingPortfolioDetail = true }
                )
            } else {
                NoPortfolioCard(onChoosePortfolio: { showingPortfolioSelection = true })
            }
        }
    }
    
    // MARK: - Portfolio Performance Section
    
    private var portfolioPerformanceSection: some View {
        VStack(spacing: DashboardConstants.sectionSpacing) {
            HStack {
                Text("Portfolio Performance")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            PortfolioPerformanceCard(
                portfolioValue: viewModel.portfolioValueText,
                isPositive: viewModel.isPortfolioPositive,
                changeText: viewModel.portfolioChangeText,
                totalInvested: viewModel.totalInvested,
                totalGainLossText: viewModel.totalGainLossText,
                availableBalanceText: viewModel.availableBalanceText,
                chartData: viewModel.chartData,
                selectedTimeframe: viewModel.selectedTimeframe,
                onTimeframeChanged: { timeframe in
                    viewModel.selectedTimeframe = timeframe
                    Task { await viewModel.refreshChartData() }
                }
            )
        }
    }
    
    // MARK: - Pending Orders Section
    
    private var pendingOrdersSection: some View {
        PendingOrdersCard(summary: viewModel.pendingOrdersSummary) {
            Task { await viewModel.cancelAllPendingOrders() }
        }
    }
    
    // MARK: - Holdings Section
    
    private var holdingsSection: some View {
        VStack(spacing: DashboardConstants.sectionSpacing) {
            HStack {
                Text("Your Holdings")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                
                Text("\(viewModel.positions.count) assets")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your holdings, \(viewModel.positions.count) assets")
            
            ForsaCard {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.positions.enumerated()), id: \.element.id) { index, position in
                        HoldingRow(position: position)
                        
                        if index < viewModel.positions.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sheets
    
    @ViewBuilder
    private var investmentResultSheet: some View {
        if let result = coordinator.portfolioInvestmentResult {
            InvestmentResultView(result: result, depositAmount: viewModel.cashBalance) {
                showInvestmentResult = false
                Task { await viewModel.refreshData() }
            }
        }
    }
    
    private var portfolioSelectionSheet: some View {
        PortfolioSelectionSheet(
            currentPortfolio: coordinator.selectedPortfolio,
            onSelect: { newPortfolio in
                coordinator.updateSelectedPortfolio(newPortfolio)
                showingPortfolioSelection = false
            }
        )
    }
    
    @ViewBuilder
    private var portfolioDetailSheet: some View {
        if let portfolio = coordinator.selectedPortfolio {
            PortfolioDetailView(risk: portfolio)
        }
    }
    
    // MARK: - Overlay
    
    private var investingOverlay: some View {
        InvestingOverlay(
            isVisible: isInvesting || coordinator.isInvestingPortfolio,
            portfolioTitle: coordinator.selectedPortfolio?.title
        )
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        Task {
            await viewModel.checkAccountStatus()
            await autoInvestIfNeeded()
        }
    }
    
    private func handleRefresh() async {
        await viewModel.refreshData()
        await autoInvestIfNeeded()
    }
    
    private func autoInvestIfNeeded() async {
        guard viewModel.buyingPower >= DashboardConstants.minimumInvestmentAmount,
              !viewModel.hasPendingOrders else { return }
        
        let didInvest = await coordinator.checkAndAutoInvestAvailableCash()
        if didInvest {
            await viewModel.refreshData()
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
        
        await viewModel.refreshData()
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AppCoordinator())
}
