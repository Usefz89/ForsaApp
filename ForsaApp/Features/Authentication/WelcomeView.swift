//
//  WelcomeView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentPage = 0
    let onboardingPages = OnboardingPage.allPages

    var body: some View {
        ZStack {
            Color.gradientPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    ForsaLogo(size: .medium, style: .textOnly)

                    Spacer()

                    NavigationLink(destination: SignInView()) {
                        Text("Skip")
                    }
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Onboarding Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 30)

                // Action Buttons
                VStack(spacing: 12) {
                    NavigationLink(destination: RegistrationFlowView()) {
                        Text("Get Started")
                            .font(.buttonLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryPurple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    // Demo Account Button
                    NavigationLink(destination: DemoAccountFlowView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Try Demo Account")
                                .font(.buttonMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    }

                    NavigationLink(destination: SignInView()) {
                        Text("I already have an account")
                            .font(.buttonMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .underline()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: page.iconName)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white)
            }

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 20)
            }

            Spacer()
        }
    }
}

struct OnboardingPage {
    let iconName: String
    let title: String
    let description: String

    static let allPages = [
        OnboardingPage(
            iconName: "checkmark.shield.fill",
            title: "100% Halal Investing",
            description: "Every stock and ETF is pre-screened for Sharia compliance. Invest with confidence knowing your portfolio aligns with Islamic principles."
        ),
        OnboardingPage(
            iconName: "chart.xyaxis.line",
            title: "Goal-Based Investing",
            description: "Set your financial goals and let our Robo-Advisor build a personalized portfolio tailored to your timeline and risk profile."
        ),
        OnboardingPage(
            iconName: "arrow.triangle.2.circlepath",
            title: "Smart Rebalancing",
            description: "We automatically rebalance your portfolio to maintain your target risk level, keeping your investments on track effortlessly."
        ),
        OnboardingPage(
            iconName: "heart.fill",
            title: "Integrated Zakat Calculator",
            description: "Calculate your Islamic obligations automatically. Track your assets and ensure you're fulfilling your religious duties."
        )
    ]
}

// MARK: - Preview
#Preview {
    NavigationView {
        WelcomeView()
    }
}