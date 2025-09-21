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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with user greeting
                    headerView

                    // Portfolio Summary
                    portfolioSummaryView

                    // Performance Chart
                    performanceChartView

                    // Quick Actions
                    quickActionsView

                    // Holdings Section
                    holdingsView

                    // Recent Activity
                    recentActivityView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Account for tab bar
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning,")
                    .font(.callout)
                    .foregroundColor(.textSecondary)

                Text(coordinator.currentUser?.firstName ?? "Ahmed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            HStack(spacing: 12) {
                // Notifications
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Color.backgroundSecondary)
                            .frame(width: 40, height: 40)

                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textSecondary)

                        // Notification badge
                        Circle()
                            .fill(Color.errorRed)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }

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

    private var portfolioSummaryView: some View {
        ForsaCard {
            VStack(spacing: 16) {
                // Total Value
                VStack(spacing: 8) {
                    Text("Total Portfolio Value")
                        .font(.callout)
                        .foregroundColor(.textSecondary)

                    Text("$\(String(format: "%.2f", viewModel.totalPortfolioValue))")
                        .font(.priceXLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isPortfolioPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption1)
                            .foregroundColor(viewModel.isPortfolioPositive ? .gainGreen : .lossRed)

                        Text(viewModel.portfolioChangeText)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.isPortfolioPositive ? .gainGreen : .lossRed)

                        Text("today")
                            .font(.callout)
                            .foregroundColor(.textTertiary)
                    }
                }

                // Stats Row
                HStack(spacing: 20) {
                    StatView(
                        title: "Invested",
                        value: "$\(String(format: "%.0f", viewModel.totalInvested))",
                        icon: "arrow.down.circle.fill",
                        color: .primaryBlue
                    )

                    StatView(
                        title: "Gain/Loss",
                        value: viewModel.totalGainLossText,
                        icon: viewModel.isPortfolioPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                        color: viewModel.isPortfolioPositive ? .gainGreen : .lossRed
                    )

                    StatView(
                        title: "Dividends",
                        value: "$\(String(format: "%.0f", viewModel.totalDividends))",
                        icon: "dollarsign.circle.fill",
                        color: .primaryGreen
                    )
                }
            }
        }
    }

    private var performanceChartView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Portfolio Performance")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Menu {
                        Button("1D") { viewModel.selectedTimeframe = .oneDay }
                        Button("1W") { viewModel.selectedTimeframe = .oneWeek }
                        Button("1M") { viewModel.selectedTimeframe = .oneMonth }
                        Button("3M") { viewModel.selectedTimeframe = .threeMonths }
                        Button("1Y") { viewModel.selectedTimeframe = .oneYear }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedTimeframe.displayName)
                                .font(.callout)
                                .foregroundColor(.primaryPurple)

                            Image(systemName: "chevron.down")
                                .font(.caption1)
                                .foregroundColor(.primaryPurple)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primaryPurple.opacity(0.1))
                        .cornerRadius(6)
                    }
                }

                // Chart
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
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Value", data.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primaryPurple.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 150)
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
            }
        }
    }

    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Buy Stocks",
                    subtitle: "Invest in halal companies",
                    icon: "plus.circle.fill",
                    color: .primaryGreen
                ) {
                    // Navigate to markets
                }

                QuickActionCard(
                    title: "Create Pie",
                    subtitle: "Build a portfolio",
                    icon: "chart.pie.fill",
                    color: .primaryPurple
                ) {
                    // Navigate to pie creation
                }

                QuickActionCard(
                    title: "Deposit Funds",
                    subtitle: "Add money to invest",
                    icon: "arrow.down.circle.fill",
                    color: .primaryBlue
                ) {
                    // Navigate to deposit
                }

                QuickActionCard(
                    title: "View Reports",
                    subtitle: "Portfolio analytics",
                    icon: "chart.bar.fill",
                    color: Color(red: 1.0, green: 0.733, blue: 0.2)
                ) {
                    // Navigate to reports
                }
            }
        }
    }

    private var holdingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Holdings")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink(destination: PortfolioDetailView()) {
                    Text("View All")
                        .font(.callout)
                        .foregroundColor(.primaryPurple)
                }
            }

            LazyVStack(spacing: 12) {
                ForEach(viewModel.topHoldings) { holding in
                    HoldingRowView(holding: holding)
                }
            }
        }
    }

    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink(destination: ActivityView()) {
                    Text("View All")
                        .font(.callout)
                        .foregroundColor(.primaryPurple)
                }
            }

            LazyVStack(spacing: 12) {
                ForEach(viewModel.recentTransactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            VStack(spacing: 2) {
                Text(value)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)

                Text(title)
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ForsaCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)

                        Text(subtitle)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HoldingRowView: View {
    let holding: Holding

    var body: some View {
        ForsaCard(padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)) {
            HStack(spacing: 12) {
                // Stock icon
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(holding.symbol.prefix(2)))
                            .font(.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryPurple)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.symbol)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)

                    Text(holding.name)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.2f", holding.totalValue))")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)

                    Text(holding.gainLossPercentageFormatted)
                        .font(.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(holding.isPositive ? .gainGreen : .lossRed)
                }
            }
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        ForsaCard(padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)) {
            HStack(spacing: 12) {
                // Transaction icon
                Circle()
                    .fill(transaction.type.isPositive ? Color.gainGreen.opacity(0.1) : Color.lossRed.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: transaction.type.isPositive ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(transaction.type.isPositive ? .gainGreen : .lossRed)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.type.displayName)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)

                    if let symbol = transaction.symbol {
                        Text(symbol)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(transaction.formattedAmount)
                        .font(.calloutMedium)
                        .foregroundColor(transaction.type.isPositive ? .gainGreen : .lossRed)

                    Text("Today")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
        }
    }
}

// MARK: - Placeholder Views
struct PortfolioDetailView: View {
    var body: some View {
        Text("Portfolio Detail View")
            .navigationTitle("Portfolio")
    }
}

struct ActivityView: View {
    var body: some View {
        Text("Activity View")
            .navigationTitle("Activity")
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AppCoordinator())
}