//
//  Step1_CreateAccountView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 1: Create Account - Email, password, and name
struct Step1_CreateAccountView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName, email, password, confirmPassword
    }
    
    var body: some View {
        RegistrationStepContainer(
            buttonTitle: "Continue",
            isButtonDisabled: !isFormValid,
            onPrimaryTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.nextStep()
                }
            }
        ) {
            VStack(spacing: 28) {
                // Welcome header with icon
                welcomeHeader
                
                // Name fields
                nameFields
                
                // Email field
                emailField
                
                // Password fields
                passwordFields
                
                // Validation errors
                if let errors = viewModel.stepValidationErrors[.basicInfo], !errors.isEmpty {
                    ValidationErrorCard(errors: errors)
                }
            }
        }
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        VStack(spacing: 16) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(Color.primaryPurple.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Let's get started")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Create your account to begin your\nhalal investment journey")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Name Fields
    
    private var nameFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("First Name")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("First name", text: $viewModel.registrationData.firstName)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .firstName))
                        .textInputAutocapitalization(.words)
                        .textContentType(.givenName)
                        .focused($focusedField, equals: .firstName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .lastName }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Name")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Last name", text: $viewModel.registrationData.lastName)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .lastName))
                        .textInputAutocapitalization(.words)
                        .textContentType(.familyName)
                        .focused($focusedField, equals: .lastName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                }
            }
        }
    }
    
    // MARK: - Email Field
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textTertiary)
                
                TextField("you@example.com", text: $viewModel.registrationData.email)
                    .font(.inputText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .email ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .email ? 2 : 1)
            )
            
            if !viewModel.registrationData.email.isEmpty && !isValidEmail {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption1)
                    Text("Please enter a valid email address")
                        .font(.caption1)
                }
                .foregroundColor(.errorRed)
            }
        }
    }
    
    // MARK: - Password Fields
    
    private var passwordFields: some View {
        VStack(spacing: 16) {
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                    
                    SecureField("Create a password", text: $viewModel.registrationData.password)
                        .font(.inputText)
                        .foregroundColor(.textPrimary)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .password ? 2 : 1)
                )
                
                // Password strength indicator
                PasswordStrengthIndicator(password: viewModel.registrationData.password)
            }
            
            // Confirm Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                    
                    SecureField("Confirm your password", text: $viewModel.confirmPassword)
                        .font(.inputText)
                        .foregroundColor(.textPrimary)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.done)
                    
                    if !viewModel.confirmPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(passwordsMatch ? .successGreen : .errorRed)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(confirmPasswordBorderColor, lineWidth: focusedField == .confirmPassword ? 2 : 1)
                )
                
                if !viewModel.confirmPassword.isEmpty && !passwordsMatch {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption1)
                        Text("Passwords do not match")
                            .font(.caption1)
                    }
                    .foregroundColor(.errorRed)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: viewModel.registrationData.email)
    }
    
    private var passwordsMatch: Bool {
        !viewModel.registrationData.password.isEmpty && viewModel.registrationData.password == viewModel.confirmPassword
    }
    
    private var isFormValid: Bool {
        !viewModel.registrationData.firstName.isEmpty &&
        !viewModel.registrationData.lastName.isEmpty &&
        isValidEmail &&
        viewModel.registrationData.password.count >= 8 &&
        passwordsMatch
    }
    
    private var confirmPasswordBorderColor: Color {
        if !viewModel.confirmPassword.isEmpty && !passwordsMatch {
            return .errorRed
        }
        return focusedField == .confirmPassword ? .primaryPurple : .borderPrimary
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        PasswordStrength.calculate(for: password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Strength bar
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < strength.level ? strength.color : Color.backgroundTertiary)
                        .frame(height: 4)
                }
            }
            
            // Requirements checklist
            VStack(alignment: .leading, spacing: 6) {
                PasswordRequirementRow(
                    text: "At least 8 characters",
                    isMet: password.count >= 8
                )
                PasswordRequirementRow(
                    text: "Contains uppercase letter",
                    isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil
                )
                PasswordRequirementRow(
                    text: "Contains lowercase letter",
                    isMet: password.range(of: "[a-z]", options: .regularExpression) != nil
                )
                PasswordRequirementRow(
                    text: "Contains a number",
                    isMet: password.range(of: "[0-9]", options: .regularExpression) != nil
                )
            }
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isMet ? .successGreen : .textMuted)
            
            Text(text)
                .font(.caption1)
                .foregroundColor(isMet ? .textPrimary : .textTertiary)
        }
    }
}

enum PasswordStrength {
    case weak
    case fair
    case good
    case strong
    
    var level: Int {
        switch self {
        case .weak: return 1
        case .fair: return 2
        case .good: return 3
        case .strong: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .errorRed
        case .fair: return .warningYellow
        case .good: return .primaryBlue
        case .strong: return .successGreen
        }
    }
    
    var text: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
    
    static func calculate(for password: String) -> PasswordStrength {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        
        switch score {
        case 0...1: return .weak
        case 2: return .fair
        case 3: return .good
        default: return .strong
        }
    }
}

// MARK: - Validation Error Card

struct ValidationErrorCard: View {
    let errors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.errorRed)
                
                Text("Please fix the following:")
                    .font(.calloutMedium)
                    .foregroundColor(.errorRed)
            }
            
            ForEach(errors, id: \.self) { error in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.errorRed)
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(16)
        .background(Color.errorRed.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.errorRed.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    Step1_CreateAccountView(viewModel: RegistrationViewModel())
}

