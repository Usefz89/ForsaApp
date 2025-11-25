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
    @Published var isInvestingPortfolio = false
    @Published var portfolioInvestmentResult: PortfolioInvestmentResult?
    @Published var showInvestmentResult = false
    
    // MARK: - UserDefaults Keys
    private enum StorageKeys {
        static let isLoggedIn = "forsa_is_logged_in"
        static let savedUser = "forsa_saved_user"
        static let alpacaAccountId = "alpaca_account_id"
        static let userEmail = "forsa_user_email"
        static let userPassword = "forsa_user_password" // In production, use Keychain!
        static let selectedPortfolio = "forsa_selected_portfolio"
    }

    init() {
        checkAuthenticationStatus()
    }

    private func checkAuthenticationStatus() {
        print("🔍 Checking authentication status...")
        
        // Check if user was previously logged in
        let isLoggedIn = UserDefaults.standard.bool(forKey: StorageKeys.isLoggedIn)
        
        if isLoggedIn, let savedUserData = UserDefaults.standard.data(forKey: StorageKeys.savedUser) {
            do {
                let savedUser = try JSONDecoder().decode(User.self, from: savedUserData)
                print("✅ Found saved user: \(savedUser.email)")
                
                // Restore session
                Task {
                    // Initialize Alpaca session in background
                    _ = await AlpacaTradingService.shared.initializeSession()
                    
                    await MainActor.run {
                        self.currentUser = savedUser
                        self.isAuthenticated = true
                        self.hasCompletedKYC = savedUser.hasCompletedKYC
                        self.isLoading = false
                    }
                }
            } catch {
                print("❌ Failed to decode saved user: \(error)")
                clearSavedSession()
                isLoading = false
            }
        } else {
            print("📝 No saved session found")
            isLoading = false
        }
    }
    
    private func checkKYCStatus() {
        hasCompletedKYC = currentUser?.hasCompletedKYC ?? false
    }
    
    // MARK: - Session Persistence
    
    private func saveSession(user: User, email: String, password: String) {
        print("💾 Saving user session...")
        
        // Save user data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: StorageKeys.savedUser)
        }
        
        // Save login state
        UserDefaults.standard.set(true, forKey: StorageKeys.isLoggedIn)
        
        // Save credentials for re-authentication (In production, use Keychain!)
        UserDefaults.standard.set(email, forKey: StorageKeys.userEmail)
        UserDefaults.standard.set(password, forKey: StorageKeys.userPassword)
        
        UserDefaults.standard.synchronize()
        print("✅ Session saved successfully")
    }
    
    private func updateSavedUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: StorageKeys.savedUser)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func clearSavedSession() {
        print("🗑️ Clearing saved session...")
        UserDefaults.standard.removeObject(forKey: StorageKeys.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: StorageKeys.savedUser)
        UserDefaults.standard.removeObject(forKey: StorageKeys.alpacaAccountId)
        UserDefaults.standard.removeObject(forKey: StorageKeys.userEmail)
        UserDefaults.standard.removeObject(forKey: StorageKeys.userPassword)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        print("🔐 Signing in user: \(email)")
        
        // 1. Check if we have a saved account for this email
        let savedEmail = UserDefaults.standard.string(forKey: StorageKeys.userEmail)
        let savedPassword = UserDefaults.standard.string(forKey: StorageKeys.userPassword)
        let savedFirstName = UserDefaults.standard.string(forKey: "user_first_name")
        let savedLastName = UserDefaults.standard.string(forKey: "user_last_name")
        
        print("📝 Saved email: \(savedEmail ?? "none"), Saved name: \(savedFirstName ?? "none") \(savedLastName ?? "none")")
        
        // 2. Initialize Alpaca session
        let sessionVerified = await AlpacaTradingService.shared.initializeSession()
        print("🔐 Alpaca Session Verified: \(sessionVerified)")
        
        // 3. Check if this email matches a saved account with correct password
        if savedEmail == email && savedPassword == password {
            // Returning user - restore their session
            if let savedUserData = UserDefaults.standard.data(forKey: StorageKeys.savedUser),
               let savedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
                print("✅ Credentials match saved user: \(savedUser.firstName) \(savedUser.lastName)")
                
                await MainActor.run {
                    self.currentUser = savedUser
                    self.isAuthenticated = true
                    self.hasCompletedKYC = savedUser.hasCompletedKYC
                }
                return
            }
        }
        
        // 4. For sign-in with saved email but different password, still check if account exists
        guard let accountId = UserDefaults.standard.string(forKey: StorageKeys.alpacaAccountId) else {
            throw NSError(domain: "AuthError", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "No account found. Please sign up first."])
        }
        
        // 5. Verify the account exists in Alpaca
        do {
            let account = try await AlpacaTradingService.shared.fetchAccountDetails(accountId: accountId)
            print("✅ Alpaca account verified: \(account.id)")
            
            // Use saved name if email matches, otherwise extract from email
            let firstName = savedFirstName ?? email.components(separatedBy: "@").first?.capitalized ?? "User"
            let lastName = savedLastName ?? ""
            
            print("📝 Using name: \(firstName) \(lastName)")
            
            // Create user with proper name
            let user = User(
                email: email,
                firstName: firstName,
                lastName: lastName,
                isVerified: true,
                totalPortfolioValue: account.equityValue,
                totalGainLoss: 0,
                totalGainLossPercentage: 0,
                followersCount: 0,
                followingCount: 0,
                isPublicProfile: false,
                cashBalance: account.cashValue,
                hasCompletedKYC: true
            )
            
            // Save the session
            saveSession(user: user, email: email, password: password)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.checkKYCStatus()
            }
            
        } catch {
            print("❌ Failed to verify Alpaca account: \(error)")
            throw NSError(domain: "AuthError", code: 401,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid credentials or account not found."])
        }
    }

    // MARK: - Sign Up
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        print("📝 Signing up new user: \(email)")
        
        // 1. Initialize Alpaca Broker API Session
        let sessionVerified = await AlpacaTradingService.shared.initializeSession()
        print("🔐 Broker API Session Verified: \(sessionVerified)")
        
        var alpacaAccountId: String?
        
        // 2. Create Alpaca Sub-Account via Broker API
        do {
            print("📌 Creating new Alpaca sub-account...")
            alpacaAccountId = try await AlpacaTradingService.shared.createAccount(
                email: email,
                firstName: firstName,
                lastName: lastName
            )
            
            // Save the Alpaca account ID
            if let id = alpacaAccountId {
                UserDefaults.standard.set(id, forKey: StorageKeys.alpacaAccountId)
                print("✅ Alpaca Account ID saved: \(id)")
            }
            
        } catch {
            print("❌ Alpaca Account Creation Failed: \(error)")
            throw error
        }
        
        // 3. Create local user
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
            cashBalance: 0,
            hasCompletedKYC: false
        )
        
        // 4. Save user details for sign-in
        UserDefaults.standard.set(firstName, forKey: "user_first_name")
        UserDefaults.standard.set(lastName, forKey: "user_last_name")
        
        // 5. Save the session
        saveSession(user: user, email: email, password: password)

        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.checkKYCStatus()
        }
        
        print("✅ Sign up completed successfully!")
    }

    // MARK: - Sign Out
    
    func signOut() {
        print("👋 Signing out...")
        clearSavedSession()
        currentUser = nil
        isAuthenticated = false
        hasCompletedKYC = false
    }

    // MARK: - Demo Account
    
    func createDemoAccount() async {
        let demoUser = User.demo

        // Save demo session
        saveSession(user: demoUser, email: "demo@forsa.app", password: "demo123")

        await MainActor.run {
            self.currentUser = demoUser
            self.isAuthenticated = true
            self.checkKYCStatus()
        }
    }
    
    // MARK: - Onboarding Completion
    
    func completeOnboarding(riskScore: Int, goal: Goal) {
        guard let user = currentUser else { return }
        
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
            cashBalance: user.cashBalance,
            hasCompletedKYC: true,
            psychologicalRiskScore: riskScore,
            goals: updatedGoals
        )
        
        // Save selected portfolio preference
        UserDefaults.standard.set(goal.assignedPortfolio.rawValue, forKey: StorageKeys.selectedPortfolio)
        
        // Update saved user
        updateSavedUser(updatedUser)
        
        self.currentUser = updatedUser
        self.hasCompletedKYC = true
    }
    
    // MARK: - Portfolio Investment
    
    /// Get the user's selected portfolio
    var selectedPortfolio: RiskLevel? {
        if let portfolioRaw = UserDefaults.standard.string(forKey: StorageKeys.selectedPortfolio),
           let portfolio = RiskLevel(rawValue: portfolioRaw) {
            return portfolio
        }
        // Fallback to first goal's portfolio
        return currentUser?.goals.first?.assignedPortfolio
    }
    
    /// Get the Alpaca account ID
    var alpacaAccountId: String? {
        UserDefaults.standard.string(forKey: StorageKeys.alpacaAccountId)
    }
    
    /// Invests available cash into the selected portfolio
    func investInPortfolio(amount: Double? = nil) async throws -> PortfolioInvestmentResult? {
        guard let accountId = alpacaAccountId else {
            print("❌ No Alpaca account ID found")
            throw NSError(domain: "InvestmentError", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "No trading account found. Please sign up first."])
        }
        
        guard let portfolio = selectedPortfolio else {
            print("❌ No portfolio selected")
            throw NSError(domain: "InvestmentError", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "No portfolio selected. Please complete onboarding."])
        }
        
        await MainActor.run {
            self.isInvestingPortfolio = true
        }
        
        defer {
            Task {
                await MainActor.run {
                    self.isInvestingPortfolio = false
                }
            }
        }
        
        print("🚀 Investing in \(portfolio.title) portfolio")
        
        let result = try await AlpacaTradingService.shared.investInPortfolio(
            accountId: accountId, 
            portfolio: portfolio,
            amount: amount
        )
        
        await MainActor.run {
            self.portfolioInvestmentResult = result
            self.showInvestmentResult = true
        }
        
        // Refresh account data
        _ = try? await AlpacaTradingService.shared.fetchAccountDetails(accountId: accountId)
        _ = try? await AlpacaTradingService.shared.fetchPositions(accountId: accountId)
        
        return result
    }
    
    /// Auto-invest when cash is added to account
    func autoInvestOnDeposit(amount: Double) async {
        guard let _ = alpacaAccountId,
              let _ = selectedPortfolio else {
            print("⚠️ Auto-invest skipped: No account or portfolio configured")
            return
        }
        
        // Wait a moment for the transfer to settle
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        do {
            let result = try await investInPortfolio(amount: amount)
            if let result = result, result.isFullySuccessful {
                print("✅ Auto-investment successful!")
            }
        } catch {
            print("❌ Auto-investment failed: \(error)")
        }
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