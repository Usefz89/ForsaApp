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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with user greeting
                    headerView

                    // Portfolio Progress Chart
                    portfolioProgressSection

                    // Cash Balance & Actions
                    cashBalanceSection
                    
                    // Additional Info (Optional, placeholder for now)
                    // We can add "Top Holdings" or "Market News" later if needed
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Account for tab bar
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData(user: coordinator.currentUser)
            }
        }
        .onAppear {
            viewModel.loadData(user: coordinator.currentUser)
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
                        
                        Text("$\(String(format: "%.2f", viewModel.totalPortfolioValue))")
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
                            Text("Dividends")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                            Text("$\(String(format: "%.2f", viewModel.totalDividends))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 8)
                    
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
                    
                    // Timeframe Selector
                    HStack {
                        ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                            Button(action: {
                                withAnimation {
                                    viewModel.selectedTimeframe = timeframe
                                    // In a real app, this would trigger a data reload for the timeframe
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
                    NavigationLink(destination: CashReserveView()) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Available Cash")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)
                                Text("$\(String(format: "%.2f", viewModel.cashBalance))")
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

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AppCoordinator())
}