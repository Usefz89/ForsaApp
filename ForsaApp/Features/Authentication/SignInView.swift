//
//  SignInView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var rememberMe = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        // Logo
                        ForsaLogo(size: .large, style: .iconOnly)

                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.title1)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("Sign in to continue your halal investment journey")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)

                    // Sign In Form
                    VStack(spacing: 20) {
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

                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(ForsaTextFieldStyle())
                        }

                        // Remember Me & Forgot Password
                        HStack {
                            Button(action: { rememberMe.toggle() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(rememberMe ? .primaryPurple : .textTertiary)

                                    Text("Remember me")
                                        .font(.callout)
                                        .foregroundColor(.textSecondary)
                                }
                            }

                            Spacer()

                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .font(.callout)
                            .foregroundColor(.primaryPurple)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign In Button
                    VStack(spacing: 16) {
                        ForsaButton(
                            "Sign In",
                            style: .primary,
                            size: .large,
                            isDisabled: !isFormValid,
                            isLoading: isLoading
                        ) {
                            Task {
                                await signIn()
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

                        // Biometric Sign In (if available)
                        ForsaButton(
                            "Sign in with Face ID",
                            style: .tertiary,
                            size: .medium
                        ) {
                            // Handle biometric sign in
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)

                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.callout)
                            .foregroundColor(.textSecondary)

                        NavigationLink(destination: RegistrationFlowView()) {
                            Text("Sign up")
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
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private func signIn() async {
        isLoading = true

        do {
            try await coordinator.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SignInView()
            .environmentObject(AppCoordinator())
    }
}