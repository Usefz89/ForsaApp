//
//  RegistrationFlowView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Main container view for the multi-step KYC registration flow
/// Manages navigation between steps with beautiful transitions
/// Follows MVVM pattern with RegistrationViewModel for state management
struct RegistrationFlowView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var showCancelAlert = false
    
    // MARK: - Animation Constants
    private let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    private let transitionDuration: Double = 0.3
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            VStack(spacing: 0) {
                // Header with progress
                headerView
                
                // Step content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(viewModel.currentStep)
            }
            
            // Loading overlay
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationBarHidden(true)
        .alert("Cancel Registration?", isPresented: $showCancelAlert) {
            Button("Continue Registration", role: .cancel) { }
            Button("Cancel", role: .destructive) {
                viewModel.clearProgress()
                dismiss()
            }
        } message: {
            Text("Your progress will be saved. You can continue later.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.registrationComplete) { _, completed in
            if completed {
                // Navigate to risk assessment or dashboard
                // coordinator.finishRegistration()
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            // Decorative gradient orbs
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primaryPurple.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .offset(x: -geometry.size.width * 0.3, y: -50)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primaryGreen.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.4
                        )
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: geometry.size.width * 0.5, y: geometry.size.height * 0.3)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Top bar with back/close
            HStack {
                if !viewModel.isOnFirstStep {
                    Button(action: {
                        withAnimation(springAnimation) {
                            viewModel.previousStep()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.calloutMedium)
                        }
                        .foregroundColor(.primaryPurple)
                    }
                    .accessibilityLabel("Go back to previous step")
                    .accessibilityHint("Returns to \(viewModel.currentStep.previous?.title ?? "previous step")")
                } else {
                    Button(action: { showCancelAlert = true }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Cancel registration")
                    .accessibilityHint("Your progress will be saved")
                }
                
                Spacer()
                
                // Step counter
                Text("Step \(viewModel.currentStep.rawValue + 1) of \(RegistrationStep.allCases.count)")
                    .font(.caption1Medium)
                    .foregroundColor(.textTertiary)
                    .accessibilityLabel("Step \(viewModel.currentStep.rawValue + 1) of \(RegistrationStep.allCases.count)")
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Progress indicator
            RegistrationProgressBar(
                progress: viewModel.progress,
                currentStep: viewModel.currentStep
            )
            .padding(.horizontal, 24)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.currentStep.title): \(viewModel.currentStep.subtitle). Progress \(Int(viewModel.progress * 100)) percent complete")
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .basicInfo:
            Step1_CreateAccountView(viewModel: viewModel)
        case .phoneVerification:
            Step2_PhoneVerificationView(viewModel: viewModel)
        case .personalDetails:
            Step3_PersonalInfoView(viewModel: viewModel)
        case .address:
            Step4_AddressView(viewModel: viewModel)
        case .taxFinancial:
            Step6_FinancialProfileView(viewModel: viewModel)
        case .disclosures:
            Step7_DisclosuresView(viewModel: viewModel)
        case .trustedContact:
            Step8_TrustedContactView(viewModel: viewModel)
        case .agreements:
            Step9_ReviewAgreementsView(viewModel: viewModel)
        case .review:
            Step10_AccountStatusView(viewModel: viewModel)
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Creating your account...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.textPrimary.opacity(0.9))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Creating your account. Please wait.")
            .accessibilityAddTraits(.updatesFrequently)
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.25)))
    }
}

// MARK: - Registration Progress Bar

struct RegistrationProgressBar: View {
    let progress: Double
    let currentStep: RegistrationStep
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step title
            VStack(alignment: .leading, spacing: 4) {
                Text(currentStep.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(currentStep.subtitle)
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 8)
                    
                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryPurple, Color.primaryPurpleDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Step Container

/// Reusable container for registration steps with consistent styling
/// Provides standardized layout, keyboard handling, and action buttons
struct RegistrationStepContainer<Content: View>: View {
    let content: Content
    let buttonTitle: String
    let isButtonDisabled: Bool
    let isLoading: Bool
    let showSecondaryButton: Bool
    let secondaryButtonTitle: String
    let onPrimaryTap: () -> Void
    let onSecondaryTap: () -> Void
    
    @State private var isKeyboardVisible = false
    
    // MARK: - Haptic Feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    init(
        buttonTitle: String = "Continue",
        isButtonDisabled: Bool = false,
        isLoading: Bool = false,
        showSecondaryButton: Bool = false,
        secondaryButtonTitle: String = "Skip",
        onPrimaryTap: @escaping () -> Void,
        onSecondaryTap: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.buttonTitle = buttonTitle
        self.isButtonDisabled = isButtonDisabled
        self.isLoading = isLoading
        self.showSecondaryButton = showSecondaryButton
        self.secondaryButtonTitle = secondaryButtonTitle
        self.onPrimaryTap = onPrimaryTap
        self.onSecondaryTap = onSecondaryTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, isKeyboardVisible ? 20 : 120)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                dismissKeyboard()
            }
            
            Spacer(minLength: 0)
            
            // Fixed bottom buttons - hidden when keyboard is visible
            if !isKeyboardVisible {
                bottomButtonsView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isKeyboardVisible)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtonsView: some View {
        VStack(spacing: 12) {
            ForsaButton(
                buttonTitle,
                style: .primary,
                size: .large,
                isDisabled: isButtonDisabled,
                isLoading: isLoading
            ) {
                impactFeedback.impactOccurred()
                onPrimaryTap()
            }
            .accessibilityLabel(buttonTitle)
            .accessibilityHint(isButtonDisabled ? "Complete all required fields to continue" : "Tap to proceed to next step")
            
            if showSecondaryButton {
                Button(action: {
                    impactFeedback.impactOccurred(intensity: 0.5)
                    onSecondaryTap()
                }) {
                    Text(secondaryButtonTitle)
                        .font(.buttonMedium)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 8)
                .accessibilityLabel(secondaryButtonTitle)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
        .padding(.top, 16)
        .background(
            Rectangle()
                .fill(Color.backgroundPrimary)
                .shadow(color: Color.shadowLight, radius: 20, x: 0, y: -10)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Helpers
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Form Field Components

/// Reusable text field component with consistent styling and accessibility support
struct RegistrationTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var errorMessage: String?
    var helpText: String?
    var isRequired: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label with optional required indicator
            HStack(spacing: 4) {
                Text(label)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(.inputLabel)
                        .foregroundColor(.errorRed)
                }
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.inputText)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .focused($isFocused)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(keyboardType == .emailAddress)
            .accessibilityLabel(label)
            .accessibilityHint(errorMessage ?? helpText ?? "")
            .accessibilityValue(text.isEmpty ? "Empty" : text)
            
            // Error or help text
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption1)
                    Text(error)
                        .font(.caption1)
                }
                .foregroundColor(.errorRed)
                .accessibilityLabel("Error: \(error)")
            } else if let help = helpText {
                Text(help)
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
                    .accessibilityLabel(help)
            }
        }
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return .errorRed
        }
        return isFocused ? .primaryPurple : .borderPrimary
    }
}

// MARK: - Registration Section Header

/// Reusable section header component with icon support
struct RegistrationSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryPurple)
                    .frame(width: 40, height: 40)
                    .background(Color.primaryPurple.opacity(0.1))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle ?? "")")
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Previews

#Preview("Registration Flow") {
    RegistrationFlowView()
        .environmentObject(AppCoordinator())
}

#Preview("Registration TextField") {
    VStack(spacing: 20) {
        RegistrationTextField(
            label: "Email Address",
            placeholder: "you@example.com",
            text: .constant(""),
            keyboardType: .emailAddress,
            isRequired: true
        )
        
        RegistrationTextField(
            label: "Email with Error",
            placeholder: "you@example.com",
            text: .constant("invalid"),
            errorMessage: "Please enter a valid email"
        )
        
        RegistrationTextField(
            label: "With Help Text",
            placeholder: "Enter value",
            text: .constant(""),
            helpText: "This field is optional"
        )
    }
    .padding()
}

#Preview("Section Header") {
    VStack(spacing: 20) {
        RegistrationSectionHeader("Personal Information", subtitle: "Tell us about yourself", icon: "person.fill")
        RegistrationSectionHeader("Address", icon: "location.fill")
        RegistrationSectionHeader("Simple Header")
    }
    .padding()
}

