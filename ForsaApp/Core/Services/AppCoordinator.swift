//
//  AppCoordinator.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var hasCompletedKYC = false

    init() {
        checkAuthenticationStatus()
    }

    private func checkAuthenticationStatus() {
        // Simulate checking authentication status
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // For demo purposes, we'll start with authentication required
            self.isAuthenticated = false
            self.isLoading = false
        }
    }
    
    private func checkKYCStatus() {
        hasCompletedKYC = currentUser?.hasCompletedKYC ?? false
    }

    func signIn(email: String, password: String) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

        // Create demo user
        let user = User(
            email: email,
            firstName: "Ahmed",
            lastName: "Al-Mansouri",
            isVerified: true,
            totalPortfolioValue: 25420.50,
            totalGainLoss: 2840.30,
            totalGainLossPercentage: 12.6,
            followersCount: 128,
            followingCount: 45,
            isPublicProfile: true,
            hasCompletedKYC: true,
            psychologicalRiskScore: 65
        )

        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.checkKYCStatus()
        }
    }

    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        // 1. Initialize Alpaca Session (Determine Mode: Broker vs Trading)
        let sessionVerified = await AlpacaTradingService.shared.initializeSession()
        print("🔐 Session Verified: \(sessionVerified)")
        print("🔐 Is Trading Mode: \(AlpacaTradingService.shared.isTradingMode)")
        
        var alpacaAccountId: String?
        
        // 2. Create or Link Alpaca Account
        do {
            if AlpacaTradingService.shared.isTradingMode {
                // Paper Trading Mode: Just link the existing key's account
                print("📌 Using Trading Mode - linking existing account")
                if let account = AlpacaTradingService.shared.currentAccount {
                    alpacaAccountId = account.id
                } else {
                    // Should not happen if initializeSession returned true, but double check
                    // Force fetch to be sure
                     _ = await AlpacaTradingService.shared.initializeSession() // Re-check
                     alpacaAccountId = AlpacaTradingService.shared.currentAccount?.id
                }
            } else {
                // Broker Mode: Create a new sub-account
                print("📌 Using Broker Mode - creating new sub-account")
                alpacaAccountId = try await AlpacaTradingService.shared.createAccount(
                    email: email,
                    firstName: firstName,
                    lastName: lastName
                )
            }
            
            // Save the ID
            if let id = alpacaAccountId {
                UserDefaults.standard.set(id, forKey: "alpaca_account_id")
            }
            
        } catch {
            print("Alpaca Account Creation Failed: \(error)")
            // Re-throw the error to stop sign up if we want to enforce account creation
            // Or just log it. Given user requirement "users will have ability to create accounts",
            // failure here is critical. Let's rethrow or handle specifically.
            // For now, print is okay, but user should know.
            // Actually, let's let the UI handle it if we rethrow, but the UI catches and shows error.
            throw error
        }
        
        // Simulate API call for local user creation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

        let user = User(
            email: email,
            firstName: firstName,
            lastName: lastName,
            isVerified: false,
            totalPortfolioValue: 0,
            totalGainLoss: 0,
            totalGainLossPercentage: 0,
            followersCount: 0,
            followingCount: 0,
            isPublicProfile: false,
            hasCompletedKYC: false
        )

        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.checkKYCStatus()
        }
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        hasCompletedKYC = false
    }

    func createDemoAccount() async {
        let demoUser = User.demo

        await MainActor.run {
            self.currentUser = demoUser
            self.isAuthenticated = true
            self.checkKYCStatus()
        }
    }
    
    func completeOnboarding(riskScore: Int, goal: Goal) {
        guard var user = currentUser else { return }
        
        // Update user with KYC completion
        var updatedGoals = user.goals
        updatedGoals.append(goal)
        
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
            followersCount: user.followersCount,
            followingCount: user.followingCount,
            isPublicProfile: user.isPublicProfile,
            hasCompletedKYC: true,
            psychologicalRiskScore: riskScore,
            goals: updatedGoals
        )
        
        self.currentUser = updatedUser
        self.hasCompletedKYC = true
    }
}

struct AppCoordinatorView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        Group {
            if coordinator.isLoading {
                SplashView()
            } else if !coordinator.isAuthenticated {
                AuthenticationView()
                    .environmentObject(coordinator)
            } else if !coordinator.hasCompletedKYC {
                OnboardingFlowView()
                    .environmentObject(coordinator)
            } else {
                TabBarView()
                    .environmentObject(coordinator)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: coordinator.isLoading)
        .animation(.easeInOut(duration: 0.3), value: coordinator.hasCompletedKYC)
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5

    var body: some View {
        ZStack {
            Color.gradientPrimary
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Forsa Logo
                ZStack {
                    ForsaLogo(size: .xlarge, style: .iconOnly)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }

                VStack(spacing: 8) {
                    Text("Forsa")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Sharia-Compliant Investing")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        NavigationView {
            WelcomeView()
                .environmentObject(coordinator)
        }
    }
}

// MARK: - Preview
#Preview {
    AppCoordinatorView()
}