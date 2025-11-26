//
//  Step2_PhoneVerificationView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 2: Phone Verification - Phone number with country picker and OTP verification
struct Step2_PhoneVerificationView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showCountryPicker = false
    @State private var selectedCountry = Country.usa
    @State private var otpCode = ""
    @State private var resendTimer = 60
    @State private var canResend = true
    @State private var showChannelPicker = false
    @State private var selectedChannel: VerificationChannel = .sms
    @FocusState private var otpFocused: Bool
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RegistrationStepContainer(
            buttonTitle: buttonTitle,
            isButtonDisabled: isButtonDisabled,
            isLoading: viewModel.isSendingOTP || viewModel.isVerifyingOTP,
            onPrimaryTap: {
                Task {
                    await handlePrimaryAction()
                }
            }
        ) {
            VStack(spacing: 32) {
                // Header
                phoneHeader
                
                if viewModel.otpSent {
                    // OTP Input
                    otpInputSection
                } else {
                    // Phone Input
                    phoneInputSection
                }
                
                // Error message
                if let error = viewModel.verificationError {
                    errorBanner(message: error)
                }
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selectedCountry: $selectedCountry)
        }
        .onReceive(timer) { _ in
            if resendTimer > 0 && viewModel.otpSent {
                resendTimer -= 1
                if resendTimer == 0 {
                    canResend = true
                }
            }
        }
        .onChange(of: viewModel.isPhoneVerified) { _, isVerified in
            if isVerified {
                // Auto-proceed when verification successful
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.nextStep()
                }
            }
        }
    }
    
    // MARK: - Button Configuration
    
    private var buttonTitle: String {
        if viewModel.isSendingOTP {
            return "Sending..."
        } else if viewModel.isVerifyingOTP {
            return "Verifying..."
        } else if viewModel.otpSent {
            return "Verify & Continue"
        } else {
            return "Send Verification Code"
        }
    }
    
    private var isButtonDisabled: Bool {
        if viewModel.isSendingOTP || viewModel.isVerifyingOTP {
            return true
        } else if viewModel.otpSent {
            return otpCode.filter { $0.isNumber }.count != 6
        } else {
            return !isPhoneValid
        }
    }
    
    // MARK: - Actions
    
    private func handlePrimaryAction() async {
        if viewModel.otpSent {
            // Verify OTP
            await viewModel.verifyOTP(code: otpCode)
        } else {
            // Send OTP
            await viewModel.sendOTP(channel: selectedChannel)
            if viewModel.otpSent {
                resendTimer = 60
                canResend = false
            }
        }
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.body)
                .foregroundColor(.white)
            
            Text(message)
                .font(.callout)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color.errorRed)
        .cornerRadius(12)
    }
    
    // MARK: - Header
    
    private var phoneHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if viewModel.isSendingOTP || viewModel.isVerifyingOTP {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.primaryPurple)
                } else {
                    Image(systemName: headerIcon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.primaryPurple)
                }
            }
            
            VStack(spacing: 8) {
                Text(headerTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(headerSubtitle)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var headerIcon: String {
        if viewModel.isPhoneVerified {
            return "checkmark.seal.fill"
        } else if viewModel.otpSent {
            return "checkmark.message.fill"
        } else {
            return "phone.fill"
        }
    }
    
    private var headerTitle: String {
        if viewModel.isPhoneVerified {
            return "Phone Verified!"
        } else if viewModel.otpSent {
            return "Enter Verification Code"
        } else {
            return "Verify Your Phone"
        }
    }
    
    private var headerSubtitle: String {
        if viewModel.isPhoneVerified {
            return "Your phone number has been verified successfully"
        } else if viewModel.otpSent {
            return "We sent a 6-digit code to\n\(formattedPhone)"
        } else {
            return "We'll send you a verification code\nto confirm your phone number"
        }
    }
    
    // MARK: - Phone Input Section
    
    private var phoneInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                // Country code picker
                Button(action: { showCountryPicker = true }) {
                    HStack(spacing: 6) {
                        Text(selectedCountry.flag)
                            .font(.title3)
                        
                        Text("+1")
                            .font(.bodyMedium)
                            .foregroundColor(.textPrimary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(12)
                }
                
                // Phone number input
                TextField("(555) 123-4567", text: Binding(
                    get: { viewModel.formatPhoneNumber(viewModel.registrationData.phoneNumber) },
                    set: { viewModel.registrationData.phoneNumber = $0 }
                ))
                .font(.inputText)
                .foregroundColor(.textPrimary)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderPrimary, lineWidth: 1)
                )
            }
            
            Text("We'll send a text message to verify this number")
                .font(.caption1)
                .foregroundColor(.textTertiary)
        }
    }
    
    // MARK: - OTP Input Section
    
    private var otpInputSection: some View {
        VStack(spacing: 24) {
            // OTP Input boxes
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitBox(
                        digit: getDigit(at: index),
                        isFocused: otpCode.count == index && otpFocused,
                        hasError: viewModel.verificationError != nil && otpCode.count == 6
                    )
                }
            }
            .onTapGesture {
                otpFocused = true
            }
            
            // Hidden text field for input
            TextField("", text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($otpFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
                .onChange(of: otpCode) { _, newValue in
                    // Clear error when user types
                    if viewModel.verificationError != nil {
                        viewModel.verificationError = nil
                    }
                    
                    // Filter non-numeric
                    let filtered = newValue.filter { $0.isNumber }
                    
                    // Limit to 6 digits
                    if filtered.count > 6 {
                        otpCode = String(filtered.prefix(6))
                    } else {
                        otpCode = filtered
                    }
                }
            
            // Resend code section
            resendCodeSection
            
            // Change number button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.resetPhoneVerification()
                    otpCode = ""
                    canResend = true
                    resendTimer = 60
                }
            }) {
                Text("Change Phone Number")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                    .underline()
            }
            .disabled(viewModel.isSendingOTP || viewModel.isVerifyingOTP)
        }
        .onAppear {
            otpFocused = true
        }
    }
    
    // MARK: - Resend Code Section
    
    private var resendCodeSection: some View {
        VStack(spacing: 8) {
            Text("Didn't receive the code?")
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            if viewModel.isOTPRateLimited {
                // Rate limited
                Text("Too many attempts. Try again later.")
                    .font(.calloutMedium)
                    .foregroundColor(.errorRed)
            } else if canResend {
                // Can resend
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            canResend = false
                            resendTimer = 60
                            await viewModel.resendOTP(channel: .sms)
                        }
                    }) {
                        Label("SMS", systemImage: "message.fill")
                            .font(.calloutMedium)
                            .foregroundColor(.primaryPurple)
                    }
                    .disabled(viewModel.isSendingOTP)
                    
                    Text("or")
                        .font(.callout)
                        .foregroundColor(.textTertiary)
                    
                    Button(action: {
                        Task {
                            canResend = false
                            resendTimer = 60
                            await viewModel.resendOTP(channel: .call)
                        }
                    }) {
                        Label("Call Me", systemImage: "phone.fill")
                            .font(.calloutMedium)
                            .foregroundColor(.primaryPurple)
                    }
                    .disabled(viewModel.isSendingOTP)
                }
            } else {
                // Countdown timer
                Text("Resend in \(resendTimer)s")
                    .font(.calloutMedium)
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isPhoneValid: Bool {
        let digits = viewModel.registrationData.phoneNumber.filter { $0.isNumber }
        return digits.count >= 10
    }
    
    private var formattedPhone: String {
        let formatted = viewModel.formatPhoneNumber(viewModel.registrationData.phoneNumber)
        return "+1 \(formatted)"
    }
    
    private func getDigit(at index: Int) -> String {
        let filtered = otpCode.filter { $0.isNumber }
        guard index < filtered.count else { return "" }
        return String(filtered[filtered.index(filtered.startIndex, offsetBy: index)])
    }
}

// MARK: - OTP Digit Box

struct OTPDigitBox: View {
    let digit: String
    let isFocused: Bool
    var hasError: Bool = false
    
    private var borderColor: Color {
        if hasError {
            return .errorRed
        } else if isFocused {
            return .primaryPurple
        } else if !digit.isEmpty {
            return .successGreen
        } else {
            return .borderPrimary
        }
    }
    
    private var borderWidth: CGFloat {
        isFocused || hasError ? 2 : 1
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
            
            Text(digit)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(hasError ? .errorRed : .textPrimary)
        }
        .frame(width: 48, height: 56)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .animation(.easeInOut(duration: 0.15), value: digit)
        .animation(.easeInOut(duration: 0.15), value: hasError)
        .scaleEffect(hasError ? 1.02 : 1.0)
    }
}

// MARK: - Country Picker Sheet

struct CountryPickerSheet: View {
    @Binding var selectedCountry: Country
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.common
        }
        return Country.common.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCountries) { country in
                    Button(action: {
                        selectedCountry = country
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Text(country.flag)
                                .font(.title2)
                            
                            Text(country.name)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if country.code == selectedCountry.code {
                                Image(systemName: "checkmark")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Step2_PhoneVerificationView(viewModel: RegistrationViewModel())
}

