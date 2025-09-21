//
//  CommunityView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedTab = 0

    private let tabs = ["Trending", "Top Performers", "Following", "All"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Tab selector
                tabSelectorView

                // Content based on selected tab
                contentView
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover")
                    .font(.title1)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Learn from successful investors")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            NavigationLink(destination: CreatePortfolioView()) {
                ForsaIconButton(
                    icon: "plus",
                    style: .primary,
                    size: .medium
                ) { }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var tabSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        selectedTab = index
                        viewModel.selectedFilter = CommunityFilter.allCases[index]
                    }) {
                        VStack(spacing: 8) {
                            Text(tab)
                                .font(.calloutMedium)
                                .foregroundColor(selectedTab == index ? .primaryPurple : .textSecondary)

                            Rectangle()
                                .fill(selectedTab == index ? Color.primaryPurple : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if selectedTab == 0 || selectedTab == 3 {
                    // Featured portfolios section
                    featuredSection

                    // Top creators section
                    topCreatorsSection
                }

                // Portfolio cards
                portfoliosSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured This Week")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForsaCard {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🏆 Portfolio of the Week")
                                .font(.calloutMedium)
                                .foregroundColor(.primaryPurple)

                            Text("Halal Tech Giants")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("By Sara Khalil")
                                .font(.callout)
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("+28.4%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.gainGreen)

                            Text("90 days")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)
                        }
                    }

                    HStack(spacing: 20) {
                        StatView(
                            title: "Followers",
                            value: "1.2K",
                            icon: "person.3.fill",
                            color: .primaryBlue
                        )

                        StatView(
                            title: "Copies",
                            value: "89",
                            icon: "doc.on.doc.fill",
                            color: .primaryGreen
                        )

                        StatView(
                            title: "Likes",
                            value: "456",
                            icon: "heart.fill",
                            color: .errorRed
                        )
                    }
                }
            }
        }
    }

    private var topCreatorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Creators")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink(destination: CreatorsListView()) {
                    Text("View All")
                        .font(.callout)
                        .foregroundColor(.primaryPurple)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.topCreators) { creator in
                        CreatorCardView(creator: creator) {
                            viewModel.toggleFollow(creator)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private var portfoliosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tabs[selectedTab] + " Portfolios")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredPortfolios) { portfolio in
                    CommunityPortfolioCard(portfolio: portfolio) {
                        viewModel.toggleLike(portfolio)
                    } onCopy: {
                        viewModel.copyPortfolio(portfolio)
                    } onViewProfile: {
                        // Navigate to creator profile
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CreatorCardView: View {
    let creator: User
    let onFollow: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Profile image
            Circle()
                .fill(Color.gradientPrimary)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(creator.initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )

            VStack(spacing: 4) {
                Text(creator.firstName)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text("\(creator.followersCount) followers")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Text(creator.totalGainLossPercentageFormatted)
                    .font(.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(creator.totalGainLoss >= 0 ? .gainGreen : .lossRed)
            }

            ForsaButton(
                "Follow",
                style: .outline,
                size: .small
            ) {
                onFollow()
            }
        }
        .padding(16)
        .frame(width: 120)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .shadow(color: .shadowLight, radius: 2, x: 0, y: 1)
    }
}

struct CommunityPortfolioCard: View {
    let portfolio: Portfolio
    let onLike: () -> Void
    let onCopy: () -> Void
    let onViewProfile: () -> Void

    var body: some View {
        ForsaCard {
            VStack(spacing: 16) {
                // Header with creator info
                HStack {
                    Button(action: onViewProfile) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gradientPrimary)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("SK") // Creator initials
                                        .font(.caption1)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sara Khalil")
                                    .font(.calloutMedium)
                                    .foregroundColor(.textPrimary)

                                Text("256 followers")
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    Text("2 days ago")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }

                // Portfolio info
                VStack(alignment: .leading, spacing: 12) {
                    Text(portfolio.name)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    if let description = portfolio.description {
                        Text(description)
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }

                    // Performance metrics
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Value")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)

                            Text("$\(String(format: "%.0f", portfolio.totalValue))")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Performance")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)

                            Text(portfolio.totalGainLossPercentageFormatted)
                                .font(.calloutMedium)
                                .foregroundColor(portfolio.isPositive ? .gainGreen : .lossRed)
                        }

                        Spacer()
                    }

                    // Holdings preview
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(portfolio.holdings.prefix(4)) { holding in
                                HoldingPreviewView(holding: holding)
                            }

                            if portfolio.holdings.count > 4 {
                                Text("+\(portfolio.holdings.count - 4) more")
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

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .foregroundColor(.textSecondary)

                            Text("\(portfolio.likesCount)")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .foregroundColor(.textSecondary)

                            Text("Comment")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.textSecondary)

                            Text("Share")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    ForsaButton(
                        "Copy Portfolio",
                        style: .primary,
                        size: .small
                    ) {
                        onCopy()
                    }
                }
            }
        }
    }
}

struct HoldingPreviewView: View {
    let holding: Holding

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.primaryPurple.opacity(0.1))
                .frame(width: 20, height: 20)
                .overlay(
                    Text(String(holding.symbol.prefix(1)))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryPurple)
                )

            Text(holding.symbol)
                .font(.caption1)
                .foregroundColor(.textSecondary)

            Text(holding.allocationFormatted)
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.backgroundSecondary)
        .cornerRadius(4)
    }
}

// MARK: - Placeholder Views
struct CreatePortfolioView: View {
    var body: some View {
        Text("Create Portfolio View")
            .navigationTitle("Create Portfolio")
    }
}

struct CreatorsListView: View {
    var body: some View {
        Text("Creators List View")
            .navigationTitle("Top Creators")
    }
}

// MARK: - Preview
#Preview {
    CommunityView()
}