//
//  ProfileView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeaderView

                    // Quick stats
                    quickStatsView

                    // Settings sections
                    settingsSectionsView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
    }

    private var profileHeaderView: some View {
        ForsaCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile")
                            .font(.title1)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        if let user = coordinator.currentUser {
                            Text(user.fullName)
                                .font(.headline)
                                .foregroundColor(.textSecondary)

                            Text(user.email)
                                .font(.callout)
                                .foregroundColor(.textTertiary)
                        }
                    }

                    Spacer()

                    // Profile image
                    Circle()
                        .fill(Color.gradientPrimary)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(coordinator.currentUser?.initials ?? "AA")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }

                // Verification status
                if let user = coordinator.currentUser, user.isVerified {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.gainGreen)

                        Text("Verified Account")
                            .font(.callout)
                            .foregroundColor(.gainGreen)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.halalBackground)
                    .cornerRadius(8)
                }
            }
        }
    }

    private var quickStatsView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Portfolio Summary")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                if let user = coordinator.currentUser {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Value")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)

                            Text("$\(String(format: "%.2f", user.totalPortfolioValue))")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gain/Loss")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)

                            Text(user.totalGainLoss >= 0 ? "+$\(String(format: "%.2f", user.totalGainLoss))" : "-$\(String(format: "%.2f", abs(user.totalGainLoss)))")
                                .font(.calloutMedium)
                                .foregroundColor(user.totalGainLoss >= 0 ? .gainGreen : .lossRed)
                        }

                        Spacer()
                    }

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Followers")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)

                            Text("\(user.followersCount)")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Following")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)

                            Text("\(user.followingCount)")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private var settingsSectionsView: some View {
        VStack(spacing: 16) {
            // Account section
            SettingsSection(title: "Account") {
                SettingsRow(icon: "person.circle", title: "Edit Profile", action: {})
                SettingsRow(icon: "lock", title: "Privacy Settings", action: {})
                SettingsRow(icon: "bell", title: "Notifications", action: {})
                SettingsRow(icon: "creditcard", title: "Payment Methods", action: {})
            }

            // Investment section
            SettingsSection(title: "Investment") {
                SettingsRow(icon: "chart.pie", title: "My Portfolios", action: {})
                SettingsRow(icon: "bookmark", title: "Watchlist", action: {})
                SettingsRow(icon: "arrow.down.circle", title: "Transaction History", action: {})
                SettingsRow(icon: "doc.text", title: "Tax Documents", action: {})
            }

            // Support section
            SettingsSection(title: "Support") {
                SettingsRow(icon: "questionmark.circle", title: "Help Center", action: {})
                SettingsRow(icon: "envelope", title: "Contact Support", action: {})
                SettingsRow(icon: "star", title: "Rate App", action: {})
                SettingsRow(icon: "square.and.arrow.up", title: "Share App", action: {})
            }

            // App section
            SettingsSection(title: "App") {
                SettingsRow(icon: "gear", title: "Settings", action: {})
                SettingsRow(icon: "info.circle", title: "About", action: {})
                SettingsRow(icon: "doc.text", title: "Terms of Service", action: {})
                SettingsRow(icon: "hand.raised", title: "Privacy Policy", action: {})
            }

            // Sign out
            ForsaCard {
                Button(action: {
                    coordinator.signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.errorRed)

                        Text("Sign Out")
                            .font(.calloutMedium)
                            .foregroundColor(.errorRed)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForsaCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryPurple)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.callout)
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.backgroundCard)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AppCoordinator())
}