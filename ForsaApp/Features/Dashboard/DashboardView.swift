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
    @State private var showDepositSheet = false

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
            .sheet(isPresented: $showDepositSheet) {
                depositSheet
            }
        }
        .onAppear(perform: handleOnAppear)
        .overlay(investingOverlay)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
    }

    // MARK: - Main Content (Trading 212 Style)

    private var mainContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Fixed content (no scroll)
                VStack(spacing: 0) {
                    // Error Banner
                    if let error = viewModel.errorMessage {
                        DashboardErrorBanner(message: error) {
                            viewModel.clearError()
                        }
                        .padding(.horizontal, DashboardConstants.horizontalPadding)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Account Creation Card
                    if viewModel.needsAccountCreation {
                        CreateAccountCard {
                            if let user = coordinator.currentUser {
                                Task { await viewModel.createAccountForUser(user: user) }
                            }
                        }
                        .padding(.horizontal, DashboardConstants.horizontalPadding)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Invest Now Card (when user has cash but no positions)
                    if viewModel.canInvestNow, let portfolio = coordinator.selectedPortfolio {
                        InvestNowCard(
                            availableBalance: viewModel.availableBalanceText,
                            portfolio: portfolio,
                            onInvestTapped: { Task { await investNow() } }
                        )
                        .padding(.horizontal, DashboardConstants.horizontalPadding)
                        .padding(.top, 16)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Account Value Header
                    AccountValueHeader(
                        accountValue: viewModel.portfolioValueText,
                        lastYearGain: viewModel.totalGainLossText,
                        rateOfReturn: String(format: "%.1f%%", abs(viewModel.totalGainLossPercentage)),
                        isPositive: viewModel.isPortfolioPositive
                    )
                    .padding(.top, 24)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)

                    // Full-width Chart
                    chartSection
                        .padding(.top, 16)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: DashboardConstants.springResponse,
                                           dampingFraction: DashboardConstants.springDamping)
                                   .delay(DashboardConstants.cardAppearanceDelay),
                                   value: contentAppeared)

                    // Timeframe Selector
                    TimeframeSelector(
                        selectedTimeframe: viewModel.selectedTimeframe,
                        isPositive: viewModel.isPortfolioPositive,
                        onSelect: { timeframe in
                            viewModel.selectedTimeframe = timeframe
                            Task { await viewModel.refreshChartData() }
                        }
                    )
                    .padding(.horizontal, DashboardConstants.horizontalPadding)
                    .padding(.top, 16)
                    .opacity(contentAppeared ? 1 : 0)
                    .animation(.spring(response: DashboardConstants.springResponse,
                                       dampingFraction: DashboardConstants.springDamping)
                               .delay(DashboardConstants.cardAppearanceDelay * 2),
                                   value: contentAppeared)

                    // Cash Row
                    CashRow(
                        cashAmount: viewModel.cashBalanceText,
                        onDepositTapped: { showDepositSheet = true }
                    )
                    .padding(.top, 20)
                    .opacity(contentAppeared ? 1 : 0)
                    .animation(.spring(response: DashboardConstants.springResponse,
                                       dampingFraction: DashboardConstants.springDamping)
                               .delay(DashboardConstants.cardAppearanceDelay * 3),
                                   value: contentAppeared)

                    Spacer()
                }

                // Bottom Sheet - slideable
                PortfolioBottomSheet(
                    positions: viewModel.positions,
                    pendingOrders: viewModel.pendingOrders,
                    pendingOrdersSummary: viewModel.pendingOrdersSummary,
                    portfolioType: coordinator.selectedPortfolio ?? .moderate,
                    onCancelAllOrders: viewModel.hasPendingOrders ? {
                        Task { await viewModel.cancelAllPendingOrders() }
                    } : nil,
                    onPortfolioTap: {
                        showingPortfolioSelection = true
                    },
                    collapsedHeight: geometry.size.height * 0.32,
                    expandedHeight: geometry.size.height * 0.75
                )
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8)
                           .delay(DashboardConstants.cardAppearanceDelay * 4),
                           value: contentAppeared)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentAppeared = true
            }
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        if !viewModel.chartData.isEmpty {
            TradingViewChart(
                chartData: viewModel.chartData,
                selectedTimeframe: viewModel.selectedTimeframe,
                isPositive: viewModel.isPortfolioPositive,
                isFullWidth: true
            )
            .id(viewModel.selectedTimeframe)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.22), value: viewModel.selectedTimeframe)
            .accessibilityLabel("Portfolio performance chart for \(viewModel.selectedTimeframe.displayName)")
        } else {
            emptyChartPlaceholder
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.textTertiary)
            Text("No chart data available")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("No chart data available")
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

    @ViewBuilder
    private var depositSheet: some View {
        // Placeholder for deposit functionality
        NavigationStack {
            VStack(spacing: 20) {
                Text("Deposit Funds")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Deposit functionality coming soon")
                    .foregroundColor(.textSecondary)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showDepositSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
