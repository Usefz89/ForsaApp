//
//  Step10_AccountStatusView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 10: Account Status - Success/pending screen after account creation
/// Polls Alpaca for real-time account status updates
struct Step10_AccountStatusView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var showConfetti = false
    @State private var animationProgress: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    /// Computed status from view model
    private var status: AccountStatusUIState {
        viewModel.computedAccountStatus
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: 32) {
                Spacer()
                
                // Status illustration
                statusIllustration
                
                // Status content
                statusContent
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            
            // Confetti overlay (for approved status)
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startStatusCheck()
        }
        .onDisappear {
            viewModel.stopAccountStatusPolling()
        }
        .onChange(of: viewModel.computedAccountStatus) { _, newStatus in
            handleStatusChange(newStatus)
        }
    }
    
    // MARK: - Setup
    
    private func startStatusCheck() {
        // Animate entry
        withAnimation(.easeOut(duration: 1.2)) {
            animationProgress = 1
        }
        
        // Start rotation animation for pending state
        startPendingAnimation()
        
        // Start polling for account status
        if viewModel.registrationComplete && viewModel.createdAccountId != nil {
            viewModel.startAccountStatusPolling()
        }
    }
    
    private func startPendingAnimation() {
        // Continuous rotation for pending spinner
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func handleStatusChange(_ newStatus: AccountStatusUIState) {
        switch newStatus {
        case .approved:
            // Show celebration!
            withAnimation(.spring(response: 0.5)) {
                showConfetti = true
            }
            
            // Hide confetti after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showConfetti = false
                }
            }
            
        case .rejected, .actionRequired:
            // Stop rotation animation
            rotationAngle = 0
            
        default:
            break
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            // Animated gradient orbs based on status
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [status.accentColor.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width * animationProgress)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.25)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Status Illustration
    
    private var statusIllustration: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(status.accentColor.opacity(0.2), lineWidth: 4)
                .frame(width: 160, height: 160)
            
            // Progress ring - animates for pending states
            if status == .pending || status == .unknown {
                // Spinning progress ring
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        status.accentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(rotationAngle - 90))
            } else {
                // Complete ring for final states
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(
                        status.accentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
            }
            
            // Inner circles
            Circle()
                .fill(status.accentColor.opacity(0.1))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(status.accentColor.opacity(0.15))
                .frame(width: 90, height: 90)
            
            // Status icon or loading indicator
            if viewModel.isPollingAccountStatus && status == .unknown {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(status.accentColor)
            } else {
                Image(systemName: status.icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(status.accentColor)
                    .scaleEffect(animationProgress)
            }
        }
    }
    
    // MARK: - Status Content
    
    private var statusContent: some View {
        VStack(spacing: 16) {
            Text(status.title)
                .font(.title1)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(status.subtitle)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Status badge
            HStack(spacing: 8) {
                if viewModel.isPollingAccountStatus {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(status.accentColor)
                } else {
                    Circle()
                        .fill(status.accentColor)
                        .frame(width: 8, height: 8)
                }
                
                Text(status.badge)
                    .font(.caption1Medium)
                    .foregroundColor(status.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(status.accentColor.opacity(0.1))
            .cornerRadius(20)
            
            // Polling info
            if viewModel.isPollingAccountStatus {
                Text("Checking status... (attempt \(viewModel.pollAttempts)/\(viewModel.maxPollAttempts))")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
            
            // Error message if any
            if let error = viewModel.pollingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption1)
                    Text(error)
                        .font(.caption1)
                }
                .foregroundColor(.errorRed)
                .padding(.top, 4)
            }
            
            // Additional info based on status
            statusInfo
        }
    }
    
    // MARK: - Status Info
    
    @ViewBuilder
    private var statusInfo: some View {
        switch status {
        case .unknown:
            // Loading state
            VStack(spacing: 12) {
                Text("Please wait...")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                Text("We're checking your account status with our verification systems.")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color.backgroundSecondary)
            .cornerRadius(16)
            
        case .pending:
            VStack(spacing: 12) {
                Text("What happens next?")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    StatusInfoRow(number: 1, text: "We verify your information", isComplete: true)
                    StatusInfoRow(number: 2, text: "You'll receive an email update", isComplete: false)
                    StatusInfoRow(number: 3, text: "Start investing once approved", isComplete: false)
                }
            }
            .padding(20)
            .background(Color.backgroundSecondary)
            .cornerRadius(16)
            
        case .approved:
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.successGreen)
                    
                    Text("Your account is ready!")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                }
                
                Text("Complete your risk assessment to get personalized investment recommendations.")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color.successGreen.opacity(0.1))
            .cornerRadius(16)
            
        case .rejected:
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.errorRed)
                    
                    Text("Application not approved")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                }
                
                if !viewModel.rejectionReasons.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.rejectionReasons, id: \.self) { reason in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.textSecondary)
                                Text(reason)
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                } else {
                    Text("Please contact support for more information about your application.")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
            .background(Color.errorRed.opacity(0.1))
            .cornerRadius(16)
            
        case .actionRequired:
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.warningYellow)
                    
                    Text("Additional information needed")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                }
                
                if !viewModel.requiredActions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.requiredActions, id: \.type) { action in
                            RequiredActionRow(action: action)
                        }
                    }
                } else {
                    Text("Please check your email for instructions on how to complete your application.")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
            .background(Color.warningYellow.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            switch status {
            case .unknown:
                // Just waiting
                EmptyView()
                
            case .pending:
                ForsaButton(
                    "Check Status",
                    style: .outline,
                    size: .large,
                    isLoading: viewModel.isPollingAccountStatus
                ) {
                    Task {
                        await viewModel.checkAccountStatusOnce()
                    }
                }
                
                Button(action: {
                    // Go to dashboard or home
                    // coordinator.finishRegistration()
                }) {
                    Text("Return to Home")
                        .font(.calloutMedium)
                        .foregroundColor(.textSecondary)
                }
                
            case .approved:
                ForsaButton("Continue to Risk Assessment", style: .primary, size: .large) {
                    // Navigate to risk assessment / onboarding
                    // coordinator.startOnboarding()
                }
                
                Button(action: {
                    // Skip to dashboard
                    // coordinator.skipToMain()
                }) {
                    Text("Skip for now")
                        .font(.calloutMedium)
                        .foregroundColor(.textSecondary)
                }
                
            case .rejected:
                ForsaButton("Contact Support", style: .primary, size: .large) {
                    // Open support
                    openSupport()
                }
                
                Button(action: {
                    // Go back to start
                    viewModel.clearProgress()
                }) {
                    Text("Start Over")
                        .font(.calloutMedium)
                        .foregroundColor(.textSecondary)
                }
                
            case .actionRequired:
                ForsaButton("View Required Actions", style: .primary, size: .large) {
                    // Navigate to action items or open email
                }
                
                ForsaButton("Contact Support", style: .outline, size: .large) {
                    openSupport()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func openSupport() {
        // Open email or support page
        if let url = URL(string: "mailto:support@forsa.app") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Status Info Row

struct StatusInfoRow: View {
    let number: Int
    let text: String
    var isComplete: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.successGreen : Color.primaryPurple.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.caption1Medium)
                        .foregroundColor(.primaryPurple)
                }
            }
            
            Text(text)
                .font(.callout)
                .foregroundColor(isComplete ? .textPrimary : .textSecondary)
                .strikethrough(isComplete, color: .textTertiary)
            
            Spacer()
        }
    }
}

// MARK: - Required Action Row

struct RequiredActionRow: View {
    let action: AlpacaAccountCreationResult.RequiredAction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.type.icon)
                .font(.system(size: 16))
                .foregroundColor(.warningYellow)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(action.type.displayName)
                    .font(.caption1Medium)
                    .foregroundColor(.textPrimary)
                
                Text(action.description)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
        .padding(12)
        .background(Color.backgroundCard)
        .cornerRadius(8)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size.width, height: particle.size.height)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.primaryPurple, .primaryGreen, .primaryBlue, .warningYellow, .primaryOrange, .errorRed]
        
        for _ in 0..<60 {
            let particle = ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement() ?? .primaryPurple,
                size: CGSize(
                    width: CGFloat.random(in: 6...12),
                    height: CGFloat.random(in: 10...20)
                ),
                opacity: 1,
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
            
            // Animate falling with rotation
            let index = particles.count - 1
            let duration = Double.random(in: 2...4)
            
            withAnimation(.easeIn(duration: duration)) {
                particles[index].position.y = size.height + 40
                particles[index].position.x += CGFloat.random(in: -80...80)
                particles[index].opacity = 0
                particles[index].rotation += Double.random(in: 180...720)
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGSize
    var opacity: Double
    var rotation: Double
}

// MARK: - Preview

#Preview {
    Step10_AccountStatusView(viewModel: RegistrationViewModel())
        .environmentObject(AppCoordinator())
}
