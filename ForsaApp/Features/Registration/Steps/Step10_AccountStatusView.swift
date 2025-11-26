//
//  Step10_AccountStatusView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 10: Account Status - Success/pending screen after account creation
struct Step10_AccountStatusView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var status: AccountCreationStatus = .pending
    @State private var showConfetti = false
    @State private var animationProgress: CGFloat = 0
    
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
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = 1
            }
            
            // Simulate status check
            if viewModel.registrationComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.5)) {
                        status = .approved
                        showConfetti = true
                    }
                    
                    // Hide confetti after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showConfetti = false
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            // Animated gradient orbs
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
            
            // Progress ring
            Circle()
                .trim(from: 0, to: status == .pending ? 0.75 : 1)
                .stroke(
                    status.accentColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(
                    status == .pending ?
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false) :
                    .spring(response: 0.6),
                    value: status
                )
            
            // Inner circle with icon
            Circle()
                .fill(status.accentColor.opacity(0.1))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(status.accentColor.opacity(0.15))
                .frame(width: 90, height: 90)
            
            Image(systemName: status.icon)
                .font(.system(size: 44, weight: .medium))
                .foregroundColor(status.accentColor)
                .scaleEffect(animationProgress)
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
                Circle()
                    .fill(status.accentColor)
                    .frame(width: 8, height: 8)
                
                Text(status.badge)
                    .font(.caption1Medium)
                    .foregroundColor(status.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(status.accentColor.opacity(0.1))
            .cornerRadius(20)
            
            // Additional info based on status
            statusInfo
        }
    }
    
    // MARK: - Status Info
    
    @ViewBuilder
    private var statusInfo: some View {
        switch status {
        case .pending:
            VStack(spacing: 12) {
                Text("What happens next?")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    StatusInfoRow(number: 1, text: "We verify your information")
                    StatusInfoRow(number: 2, text: "You'll receive an email update")
                    StatusInfoRow(number: 3, text: "Start investing once approved")
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
                
                Text("Please check your email for instructions on how to complete your application.")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
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
            case .pending:
                ForsaButton("Check Status", style: .outline, size: .large) {
                    // Check status again
                }
                
                Button(action: {
                    // Go to dashboard
                }) {
                    Text("Return to Home")
                        .font(.calloutMedium)
                        .foregroundColor(.textSecondary)
                }
                
            case .approved:
                ForsaButton("Continue to Risk Assessment", style: .primary, size: .large) {
                    // Navigate to risk assessment
                    // coordinator.startOnboarding()
                }
                
                Button(action: {
                    // Skip to dashboard
                }) {
                    Text("Skip for now")
                        .font(.calloutMedium)
                        .foregroundColor(.textSecondary)
                }
                
            case .actionRequired:
                ForsaButton("View Required Actions", style: .primary, size: .large) {
                    // Show what's needed
                }
                
                ForsaButton("Contact Support", style: .outline, size: .large) {
                    // Open support
                }
            }
        }
    }
}

// MARK: - Account Creation Status

enum AccountCreationStatus {
    case pending
    case approved
    case actionRequired
    
    var title: String {
        switch self {
        case .pending: return "Account Under Review"
        case .approved: return "Welcome to Forsa!"
        case .actionRequired: return "Almost There"
        }
    }
    
    var subtitle: String {
        switch self {
        case .pending: return "We're verifying your information. This usually takes just a few minutes."
        case .approved: return "Your account has been approved and is ready for investing."
        case .actionRequired: return "We need a bit more information to complete your account setup."
        }
    }
    
    var badge: String {
        switch self {
        case .pending: return "PENDING REVIEW"
        case .approved: return "APPROVED"
        case .actionRequired: return "ACTION REQUIRED"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .actionRequired: return "exclamationmark.circle.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .pending: return .primaryPurple
        case .approved: return .successGreen
        case .actionRequired: return .warningYellow
        }
    }
}

// MARK: - Status Info Row

struct StatusInfoRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.caption1Medium)
                    .foregroundColor(.primaryPurple)
            }
            
            Text(text)
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.primaryPurple, .primaryGreen, .primaryBlue, .warningYellow, .primaryOrange]
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement() ?? .primaryPurple,
                size: CGFloat.random(in: 6...12),
                opacity: 1
            )
            particles.append(particle)
            
            // Animate falling
            let index = particles.count - 1
            withAnimation(.easeIn(duration: Double.random(in: 1.5...3))) {
                particles[index].position.y = size.height + 20
                particles[index].position.x += CGFloat.random(in: -100...100)
                particles[index].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

// MARK: - Preview

#Preview {
    Step10_AccountStatusView(viewModel: RegistrationViewModel())
        .environmentObject(AppCoordinator())
}

