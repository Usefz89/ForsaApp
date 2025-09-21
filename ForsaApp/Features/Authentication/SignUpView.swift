//
//  SignUpView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    @State private var subscribeToUpdates = true
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        // Logo
                        ZStack {
                            Circle()
                                .fill(Color.gradientPrimary)
                                .frame(width: 80, height: 80)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 35, weight: .light))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.title1)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("Start your halal investment journey today")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)

                    // Sign Up Form
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.inputLabel)
                                    .foregroundColor(.textPrimary)

                                TextField("First name", text: $firstName)
                                    .textFieldStyle(ForsaTextFieldStyle())
                                    .textInputAutocapitalization(.words)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.inputLabel)
                                    .foregroundColor(.textPrimary)

                                TextField("Last name", text: $lastName)
                                    .textFieldStyle(ForsaTextFieldStyle())
                                    .textInputAutocapitalization(.words)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.inputLabel)
                                .foregroundColor(.textPrimary)

                            TextField("Enter your email", text: $email)
                                .textFieldStyle(ForsaTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.inputLabel)
                                .foregroundColor(.textPrimary)

                            SecureField("Create a password", text: $password)
                                .textFieldStyle(ForsaTextFieldStyle())

                            // Password requirements
                            VStack(alignment: .leading, spacing: 4) {
                                PasswordRequirement(
                                    text: "At least 8 characters",
                                    isMet: password.count >= 8
                                )
                                PasswordRequirement(
                                    text: "Contains uppercase letter",
                                    isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil
                                )
                                PasswordRequirement(
                                    text: "Contains number",
                                    isMet: password.range(of: "[0-9]", options: .regularExpression) != nil
                                )
                            }
                            .padding(.top, 4)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.inputLabel)
                                .foregroundColor(.textPrimary)

                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(ForsaTextFieldStyle())

                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption1)
                                    .foregroundColor(.errorRed)
                                    .padding(.top, 4)
                            }
                        }

                        // Terms and Updates
                        VStack(spacing: 12) {
                            Button(action: { agreeToTerms.toggle() }) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(agreeToTerms ? .primaryPurple : .textTertiary)
                                        .font(.system(size: 20))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("I agree to the Terms of Service and Privacy Policy")
                                            .font(.callout)
                                            .foregroundColor(.textSecondary)
                                            .multilineTextAlignment(.leading)

                                        HStack(spacing: 4) {
                                            Button("Terms of Service") {
                                                // Show terms
                                            }
                                            .font(.caption1)
                                            .foregroundColor(.primaryPurple)

                                            Text("and")
                                                .font(.caption1)
                                                .foregroundColor(.textTertiary)

                                            Button("Privacy Policy") {
                                                // Show privacy policy
                                            }
                                            .font(.caption1)
                                            .foregroundColor(.primaryPurple)
                                        }
                                    }

                                    Spacer()
                                }
                            }

                            Button(action: { subscribeToUpdates.toggle() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: subscribeToUpdates ? "checkmark.square.fill" : "square")
                                        .foregroundColor(subscribeToUpdates ? .primaryPurple : .textTertiary)

                                    Text("Subscribe to investment tips and market updates")
                                        .font(.callout)
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.leading)

                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign Up Button
                    VStack(spacing: 16) {
                        ForsaButton(
                            "Create Account",
                            style: .primary,
                            size: .large,
                            isDisabled: !isFormValid,
                            isLoading: isLoading
                        ) {
                            Task {
                                await signUp()
                            }
                        }
                        .padding(.horizontal, 24)

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.borderPrimary)
                                .frame(height: 1)

                            Text("or")
                                .font(.callout)
                                .foregroundColor(.textTertiary)
                                .padding(.horizontal, 16)

                            Rectangle()
                                .fill(Color.borderPrimary)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)

                        // Demo Account
                        ForsaButton(
                            "Try Demo Account",
                            style: .outline,
                            size: .large
                        ) {
                            Task {
                                await coordinator.createDemoAccount()
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)

                    // Sign In Link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.callout)
                            .foregroundColor(.textSecondary)

                        NavigationLink(destination: SignInView()) {
                            Text("Sign in")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryPurple)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Sign Up Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword &&
        agreeToTerms
    }

    private func signUp() async {
        isLoading = true

        do {
            try await coordinator.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption1)
                .foregroundColor(isMet ? .successGreen : .textMuted)

            Text(text)
                .font(.caption1)
                .foregroundColor(isMet ? .successGreen : .textTertiary)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SignUpView()
            .environmentObject(AppCoordinator())
    }
}