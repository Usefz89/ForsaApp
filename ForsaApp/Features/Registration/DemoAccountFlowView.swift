//
//  DemoAccountFlowView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/30/25.
//

import SwiftUI

/// View that handles demo/sandbox account creation with animated progress
/// Auto-fills all registration data and submits to Alpaca sandbox
struct DemoAccountFlowView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    
    @State private var hasStarted = false
    @State private var showAccountStatus = false
    @State private var animationPhase = 0
    
    // Animation constants
    private let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                if showAccountStatus {
                    // Show account status after completion
                    Step10_AccountStatusView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    // Progress content
                    progressContent
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Bottom button
                if !hasStarted {
                    startButton
                } else if viewModel.registrationComplete && !showAccountStatus {
                    continueButton
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.registrationComplete) { _, completed in
            if completed {
                // Small delay before showing status
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(springAnimation) {
                        showAccountStatus = true
                    }
                }
            }
        }
        .onAppear {
            startAnimationTimer()
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            // Animated gradient orbs
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primaryPurple.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .offset(
                        x: -geometry.size.width * 0.3 + CGFloat(animationPhase) * 10,
                        y: -50 + CGFloat(animationPhase) * 5
                    )
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animationPhase)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primaryGreen.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.4
                        )
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(
                        x: geometry.size.width * 0.5 - CGFloat(animationPhase) * 8,
                        y: geometry.size.height * 0.4 + CGFloat(animationPhase) * 10
                    )
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animationPhase)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {
                if viewModel.isDemoAccountCreating {
                    // Don't allow dismissal during creation
                    return
                }
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.backgroundSecondary)
                    .clipShape(Circle())
            }
            .disabled(viewModel.isDemoAccountCreating)
            .opacity(viewModel.isDemoAccountCreating ? 0.5 : 1)
            
            Spacer()
            
            Text("Demo Account")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    // MARK: - Progress Content
    
    private var progressContent: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                // Outer pulsing ring
                Circle()
                    .stroke(Color.primaryPurple.opacity(0.2), lineWidth: 3)
                    .frame(width: 140, height: 140)
                    .scaleEffect(hasStarted ? 1.1 : 1.0)
                    .opacity(hasStarted ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: hasStarted)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: viewModel.demoAccountProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primaryPurple, Color.primaryPurpleDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4), value: viewModel.demoAccountProgress)
                
                // Background circle
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                // Icon
                if viewModel.registrationComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.successGreen)
                        .transition(.scale.combined(with: .opacity))
                } else if hasStarted {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryPurple))
                            .scaleEffect(1.5)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.primaryPurple)
                            .symbolEffect(.variableColor.iterative.reversing, options: .repeating, isActive: hasStarted)
                    }
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.primaryPurple)
                }
            }
            .animation(.spring(response: 0.4), value: viewModel.registrationComplete)
            
            // Title and status
            VStack(spacing: 12) {
                Text(titleText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut, value: hasStarted)
                
                Text(subtitleText)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut, value: viewModel.demoAccountCurrentStep)
            }
            
            // Progress percentage
            if hasStarted && !viewModel.registrationComplete {
                VStack(spacing: 8) {
                    // Step indicator
                    Text(viewModel.demoAccountCurrentStep)
                        .font(.callout)
                        .foregroundColor(.primaryPurple)
                        .transition(.opacity)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.backgroundTertiary)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primaryPurple, Color.primaryPurpleDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.demoAccountProgress, height: 8)
                                .animation(.spring(response: 0.4), value: viewModel.demoAccountProgress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 48)
                    
                    // Percentage text
                    Text("\(Int(viewModel.demoAccountProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textTertiary)
                }
            }
            
            // Features list
            if !hasStarted {
                demoFeaturesList
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Demo Features List
    
    private var demoFeaturesList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What you'll get:")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            DemoFeatureRow(icon: "person.fill.checkmark", text: "Pre-filled profile with demo data")
            DemoFeatureRow(icon: "building.columns.fill", text: "Sandbox Alpaca trading account")
            DemoFeatureRow(icon: "creditcard.fill", text: "No real money or documents required")
            DemoFeatureRow(icon: "sparkles", text: "Full app experience to explore")
        }
        .padding(20)
        .background(Color.backgroundCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderPrimary, lineWidth: 1)
        )
        .padding(.top, 20)
    }
    
    // MARK: - Buttons
    
    private var startButton: some View {
        Button(action: startDemoAccountCreation) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                Text("Create Demo Account")
                    .font(.buttonLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.primaryPurple, Color.primaryPurpleDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.primaryPurple.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
    }
    
    private var continueButton: some View {
        Button(action: {
            withAnimation(springAnimation) {
                showAccountStatus = true
            }
        }) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.buttonLarge)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.successGreen)
            .cornerRadius(14)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Computed Properties
    
    private var titleText: String {
        if viewModel.registrationComplete {
            return "Demo Account Ready! 🎉"
        } else if hasStarted {
            return "Creating Your Demo Account"
        } else {
            return "Try Fursa Risk-Free"
        }
    }
    
    private var subtitleText: String {
        if viewModel.registrationComplete {
            return "Your sandbox account has been created. Start exploring Fursa's features!"
        } else if hasStarted {
            return "Setting up your personalized demo experience..."
        } else {
            return "Create a demo account instantly with randomly generated data. No real information required."
        }
    }
    
    // MARK: - Actions
    
    private func startDemoAccountCreation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(springAnimation) {
            hasStarted = true
        }
        
        Task {
            await viewModel.createDemoAccount()
        }
    }
    
    private func startAnimationTimer() {
        // Trigger subtle background animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationPhase = 1
        }
    }
}

// MARK: - Demo Feature Row

private struct DemoFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryPurple)
                .frame(width: 32, height: 32)
                .background(Color.primaryPurple.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Demo Account Flow - Initial") {
    NavigationView {
        DemoAccountFlowView()
            .environmentObject(AppCoordinator())
    }
}

#Preview("Demo Account Flow - In Progress") {
    NavigationView {
        DemoAccountFlowView()
            .environmentObject(AppCoordinator())
    }
}

