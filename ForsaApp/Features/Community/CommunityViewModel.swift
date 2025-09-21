//
//  CommunityViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation
import Combine

enum CommunityFilter: CaseIterable {
    case trending
    case topPerformers
    case following
    case all

    var displayName: String {
        switch self {
        case .trending: return "Trending"
        case .topPerformers: return "Top Performers"
        case .following: return "Following"
        case .all: return "All"
        }
    }
}

class CommunityViewModel: ObservableObject {
    @Published var portfolios: [Portfolio] = []
    @Published var filteredPortfolios: [Portfolio] = []
    @Published var topCreators: [User] = []
    @Published var selectedFilter: CommunityFilter = .trending
    @Published var isLoading = false

    private let mockDataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        $selectedFilter
            .sink { [weak self] filter in
                self?.applyFilter(filter)
            }
            .store(in: &cancellables)
    }

    func loadData() {
        portfolios = mockDataService.communityPortfolios
        topCreators = Array(mockDataService.demoUsers.prefix(3))
        applyFilter(selectedFilter)
    }

    @MainActor
    func refreshData() async {
        isLoading = true

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        loadData()
        isLoading = false
    }

    func toggleLike(_ portfolio: Portfolio) {
        // In a real app, this would update the backend
        if let index = portfolios.firstIndex(where: { $0.id == portfolio.id }) {
            let updatedPortfolio = Portfolio(
                id: portfolio.id,
                name: portfolio.name,
                description: portfolio.description,
                createdAt: portfolio.createdAt,
                updatedAt: portfolio.updatedAt,
                totalValue: portfolio.totalValue,
                totalInvested: portfolio.totalInvested,
                holdings: portfolio.holdings,
                isPublic: portfolio.isPublic,
                creatorId: portfolio.creatorId,
                likesCount: portfolio.likesCount + 1,
                copyCount: portfolio.copyCount,
                autoInvestEnabled: portfolio.autoInvestEnabled,
                autoInvestAmount: portfolio.autoInvestAmount
            )
            portfolios[index] = updatedPortfolio
            applyFilter(selectedFilter)
        }
    }

    func copyPortfolio(_ portfolio: Portfolio) {
        // In a real app, this would create a copy of the portfolio for the current user
        print("Copying portfolio: \(portfolio.name)")

        // Show success feedback
        // You could add a @Published var to show a success message
    }

    func toggleFollow(_ user: User) {
        // In a real app, this would update the follow status
        if let index = topCreators.firstIndex(where: { $0.id == user.id }) {
            let updatedUser = User(
                id: user.id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                profileImageURL: user.profileImageURL,
                isVerified: user.isVerified,
                createdAt: user.createdAt,
                totalPortfolioValue: user.totalPortfolioValue,
                totalGainLoss: user.totalGainLoss,
                totalGainLossPercentage: user.totalGainLossPercentage,
                followersCount: user.followersCount + 1,
                followingCount: user.followingCount,
                isPublicProfile: user.isPublicProfile
            )
            topCreators[index] = updatedUser
        }
    }

    private func applyFilter(_ filter: CommunityFilter) {
        switch filter {
        case .trending:
            // Sort by recent activity and engagement
            filteredPortfolios = portfolios.sorted { lhs, rhs in
                let lhsScore = Double(lhs.likesCount + lhs.copyCount * 3)
                let rhsScore = Double(rhs.likesCount + rhs.copyCount * 3)
                return lhsScore > rhsScore
            }

        case .topPerformers:
            // Sort by performance
            filteredPortfolios = portfolios.sorted { $0.totalGainLossPercentage > $1.totalGainLossPercentage }

        case .following:
            // In a real app, this would filter by followed users
            // For now, we'll show a subset
            filteredPortfolios = Array(portfolios.prefix(2))

        case .all:
            // Show all portfolios, sorted by creation date (newest first)
            filteredPortfolios = portfolios.sorted { $0.createdAt > $1.createdAt }
        }
    }
}

// MARK: - Extensions for formatting
extension User {
    var totalGainLossPercentageFormatted: String {
        let sign = totalGainLossPercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", totalGainLossPercentage))%"
    }
}