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
    @State private var showingAddGoal = false

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

                    // Goals Section
                    goalsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Account for tab bar
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData(goals: coordinator.currentUser?.goals ?? [])
            }
            .sheet(isPresented: $showingAddGoal) {
                if let riskScore = coordinator.currentUser?.psychologicalRiskScore {
                    GoalCreationView(riskScore: riskScore) { newGoal in
                        coordinator.completeOnboarding(riskScore: riskScore, goal: newGoal) // Re-using this to append goal
                        showingAddGoal = false
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadData(goals: coordinator.currentUser?.goals ?? [])
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
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var performanceChartView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Portfolio Growth")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()
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

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Goals")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: { showingAddGoal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primaryPurple)
                }
            }
            
            if let goals = coordinator.currentUser?.goals, !goals.isEmpty {
                ForEach(goals) { goal in
                    NavigationLink(destination: GoalDetailView(goal: goal)) {
                        GoalCard(goal: goal)
                    }
                }
            } else {
                Button(action: { showingAddGoal = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.largeTitle)
                            .foregroundColor(.textSecondary)
                        Text("Create your first goal")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.backgroundCard)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // Removing old Auto-Invest and Composition cards
    private var autoInvestCard: some View { EmptyView() }
    private var compositionCard: some View { EmptyView() }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AppCoordinator())
}