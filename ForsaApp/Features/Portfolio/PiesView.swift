//
//  PiesView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct PiesView: View {
    @StateObject private var viewModel = PiesViewModel()
    @State private var showingCreatePie = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with stats
                    headerStatsView

                    // My Pies section
                    myPiesSection

                    // Community Pies section
                    communityPiesSection

                    // Featured/Trending Pies
                    featuredPiesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Investment Pies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePie = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primaryPurple)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePie) {
                PieCreationView()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerStatsView: some View {
        ForsaCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portfolio Overview")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("Diversified through \(viewModel.myPies.count) investment pies")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Button(action: { showingCreatePie = true }) {
                        ForsaIconButton(icon: "plus", style: .primary, size: .medium) { }
                    }
                }

                HStack(spacing: 20) {
                    StatView(
                        title: "Total Value",
                        value: "$\(String(format: "%.0f", viewModel.totalPieValue))",
                        icon: "chart.pie.fill",
                        color: .primaryPurple
                    )

                    StatView(
                        title: "Monthly Auto-Invest",
                        value: "$\(String(format: "%.0f", viewModel.totalAutoInvest))",
                        icon: "arrow.clockwise.circle.fill",
                        color: .primaryGreen
                    )

                    StatView(
                        title: "Performance",
                        value: viewModel.averagePerformance,
                        icon: viewModel.isAveragePositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                        color: viewModel.isAveragePositive ? .gainGreen : .lossRed
                    )
                }
            }
        }
    }

    private var myPiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Investment Pies")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                if !viewModel.myPies.isEmpty {
                    NavigationLink(destination: AllPiesView(userPies: viewModel.myPies)) {
                        Text("View All")
                            .font(.callout)
                            .foregroundColor(.primaryPurple)
                    }
                }
            }

            if viewModel.myPies.isEmpty {
                EmptyPiesView {
                    showingCreatePie = true
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.myPies) { pie in
                        NavigationLink(destination: PieDetailView(pie: pie)) {
                            MyPieCard(pie: pie, performance: viewModel.getPerformance(for: pie))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private var communityPiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Community Pies")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink(destination: CommunityPiesView()) {
                    Text("Explore")
                        .font(.callout)
                        .foregroundColor(.primaryPurple)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.communityPies.prefix(5)) { pie in
                        CommunityPieCard(
                            pie: pie,
                            creator: viewModel.getCreator(for: pie),
                            performance: viewModel.getPerformance(for: pie)
                        ) {
                            viewModel.copyPie(pie)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private var featuredPiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured This Week")
                .font(.headline)
                .foregroundColor(.textPrimary)

            if let featuredPie = viewModel.communityPies.first {
                FeaturedPieCard(
                    pie: featuredPie,
                    creator: viewModel.getCreator(for: featuredPie),
                    performance: viewModel.getPerformance(for: featuredPie)
                ) {
                    viewModel.copyPie(featuredPie)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct EmptyPiesView: View {
    let onCreatePie: () -> Void

    var body: some View {
        ForsaCard {
            VStack(spacing: 20) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.textMuted)

                VStack(spacing: 8) {
                    Text("No Investment Pies Yet")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Create your first investment pie to start building a diversified portfolio with automatic rebalancing.")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                ForsaButton("Create Your First Pie", style: .primary, action: onCreatePie)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
    }
}

struct MyPieCard: View {
    let pie: InvestmentPie
    let performance: PiePerformance

    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pie.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)

                        if let description = pie.description {
                            Text(description)
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(String(format: "%.0f", pie.totalInvested))")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text(performance.formattedReturn)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(performance.isPositive ? .gainGreen : .lossRed)
                    }
                }

                // Allocation overview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Allocation")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(pie.allocations.prefix(3)) { allocation in
                                AllocationChip(allocation: allocation)
                            }

                            if pie.allocations.count > 3 {
                                Text("+\(pie.allocations.count - 3) more")
                                    .font(.caption2)
                                    .foregroundColor(.textMuted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.backgroundSecondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                // Auto-invest status
                if pie.autoInvestEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.caption1)
                            .foregroundColor(.primaryGreen)

                        Text("Auto-investing $\(String(format: "%.0f", pie.autoInvestAmount ?? 0))/month")
                            .font(.caption1)
                            .foregroundColor(.primaryGreen)

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryGreen.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
    }
}

struct CommunityPieCard: View {
    let pie: Portfolio
    let creator: User?
    let performance: PiePerformance
    let onCopy: () -> Void

    var body: some View {
        ForsaCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
            VStack(spacing: 12) {
                // Creator info
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gradientPrimary)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(creator?.initials ?? "??")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )

                    Text(creator?.firstName ?? "Unknown")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Text(performance.formattedReturn)
                        .font(.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(performance.isPositive ? .gainGreen : .lossRed)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(pie.name)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)

                    Text("$\(String(format: "%.0f", pie.totalValue))")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)

                    ForsaButton("Copy", style: .outline, size: .small) {
                        onCopy()
                    }
                }
            }
        }
        .frame(width: 160)
    }
}

struct FeaturedPieCard: View {
    let pie: Portfolio
    let creator: User?
    let performance: PiePerformance
    let onCopy: () -> Void

    var body: some View {
        ForsaCard {
            VStack(spacing: 16) {
                // Featured badge
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption1)
                            .foregroundColor(.primaryPurple)

                        Text("Featured This Week")
                            .font(.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryPurple)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryPurple.opacity(0.1))
                    .cornerRadius(4)

                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pie.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.gradientPrimary)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(creator?.initials ?? "??")
                                        .font(.caption1)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("by \(creator?.firstName ?? "Unknown")")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)

                                Text("\(creator?.followersCount ?? 0) followers")
                                    .font(.caption1)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(performance.formattedReturn)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(performance.isPositive ? .gainGreen : .lossRed)

                        Text("30 days")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)
                    }
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Value")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)

                        Text("$\(String(format: "%.0f", pie.totalValue))")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Copies")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)

                        Text("\(pie.copyCount)")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    ForsaButton("Copy This Pie", style: .primary, size: .medium) {
                        onCopy()
                    }
                }
            }
        }
    }
}

struct AllocationChip: View {
    let allocation: PieAllocation

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.primaryPurple.opacity(0.1))
                .frame(width: 16, height: 16)
                .overlay(
                    Text(String(allocation.symbol.prefix(1)))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryPurple)
                )

            Text(allocation.symbol)
                .font(.caption1)
                .foregroundColor(.textSecondary)

            Text("\(String(format: "%.1f", allocation.percentage))%")
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.backgroundSecondary)
        .cornerRadius(4)
    }
}

struct PiePerformance {
    let totalReturn: Double
    let percentage: Double
    let isPositive: Bool

    var formattedReturn: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percentage))%"
    }
}

// MARK: - Placeholder Views
struct AllPiesView: View {
    let userPies: [InvestmentPie]

    var body: some View {
        Text("All Pies View")
            .navigationTitle("My Pies")
    }
}

struct CommunityPiesView: View {
    var body: some View {
        Text("Community Pies View")
            .navigationTitle("Community Pies")
    }
}

struct PieDetailView: View {
    let pie: InvestmentPie

    var body: some View {
        Text("Pie Detail: \(pie.name)")
            .navigationTitle(pie.name)
    }
}

// MARK: - Preview
#Preview {
    PiesView()
}