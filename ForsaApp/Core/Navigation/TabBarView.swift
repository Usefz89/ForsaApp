//
//  TabBarView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct TabBarView: View {
    @State private var selectedTab: Tab = .portfolio

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == .portfolio ? "chart.pie.fill" : "chart.pie")
                    Text("Portfolio")
                }
                .tag(Tab.portfolio)

            WalletView()
                .tabItem {
                    Image(systemName: selectedTab == .wallet ? "wallet.pass.fill" : "wallet.pass")
                    Text("Wallet")
                }
                .tag(Tab.wallet)

            ZakatView()
                .tabItem {
                    Image(systemName: selectedTab == .zakat ? "heart.fill" : "heart")
                    Text("Zakat")
                }
                .tag(Tab.zakat)

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("Profile")
                }
                .tag(Tab.profile)
        }
        .accentColor(.primaryPurple)
        .onAppear {
            setupTabBarAppearance()
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(.backgroundCard)
        appearance.shadowColor = UIColor(.shadowLight)

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.primaryPurple)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(.primaryPurple),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(.textTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

enum Tab: String, CaseIterable {
    case portfolio = "portfolio"
    case wallet = "wallet"
    case zakat = "zakat"
    case profile = "profile"

    var title: String {
        switch self {
        case .portfolio: return "Portfolio"
        case .wallet: return "Wallet"
        case .zakat: return "Zakat"
        case .profile: return "Profile"
        }
    }

    var iconName: String {
        switch self {
        case .portfolio: return "chart.pie"
        case .wallet: return "wallet.pass"
        case .zakat: return "heart"
        case .profile: return "person.crop.circle"
        }
    }

    var selectedIconName: String {
        switch self {
        case .portfolio: return "chart.pie.fill"
        case .wallet: return "wallet.pass.fill"
        case .zakat: return "heart.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Placeholder Views (to be implemented, DashboardView is now implemented separately)

// MarketsView is now implemented separately

// CommunityView is now implemented separately

// ZakatView is now implemented separately

// ProfileView is now implemented separately

// MARK: - Preview
#Preview {
    TabBarView()
}