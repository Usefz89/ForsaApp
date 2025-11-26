//
//  RegistrationViewModel.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//
//  NOTE: This file is a duplicate. The primary implementation is in
//  Features/Registration/RegistrationViewModel.swift
//  This file re-exports that implementation for backward compatibility.

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing the multi-step KYC registration flow
/// Handles state management, validation, progress tracking, and data persistence
/// Integrates security features: Keychain storage, session timeout, rate limiting
@MainActor
class RegistrationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Main KYC registration data
    @Published var registrationData: KYCRegistrationData
    
    /// Current step in the registration flow
    @Published var currentStep: RegistrationStep = .basicInfo
    
    /// Password confirmation for validation
    @Published var confirmPassword: String = ""
    
    /// Loading state for async operations
    @Published var isLoading: Bool = false
    
    /// Error state
    @Published var error: KYCValidationError?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    /// Success state
    @Published var registrationComplete: Bool = false
    @Published var createdAccountId: String?
    
    /// Document upload
    @Published var selectedDocumentType: KYCDocumentType = .driversLicense
    @Published var document: KYCDocument?
    
    /// Step validation state (per step)
    @Published var stepValidationErrors: [RegistrationStep: [String]] = [:]
    
    /// Rate limiting state
    @Published var isOTPRateLimited: Bool = false
    @Published var otpRemainingAttempts: Int = 3
    @Published var otpCooldownSeconds: Int = 0
    
    /// Phone Verification State
    @Published var isPhoneVerified: Bool = false
    @Published var otpSent: Bool = false
    @Published var isSendingOTP: Bool = false
    @Published var isVerifyingOTP: Bool = false
    @Published var verificationError: String?
    @Published var verificationSid: String?
    
    /// Session timeout state
    @Published var showSessionTimeoutWarning: Bool = false
    @Published var sessionTimeoutSeconds: Int = 0
    
    // MARK: - Dependencies
    
    private let alpacaService = AlpacaTradingService.shared
    private let keychainStorage = SecureKeychainStorage.shared
    private let rateLimiter = RateLimiter.shared
    private let sessionManager = SessionTimeoutManager.shared
    private let encryption = SensitiveDataEncryption.shared
    private let twilioService = TwilioVerifyService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTimer: Timer?
    private var sessionCheckTimer: Timer?
    
    // MARK: - Computed Properties
    
    /// Progress through the registration (0.0 to 1.0)
    var progress: Double {
        Double(currentStep.rawValue) / Double(RegistrationStep.allCases.count - 1)
    }
    
    /// Overall completion percentage based on filled data
    var dataCompletionPercentage: Double {
        registrationData.completionPercentage
    }
    
    /// Can navigate to next step
    var canProceed: Bool {
        validateCurrentStep()
    }
    
    /// Can navigate to previous step
    var canGoBack: Bool {
        currentStep.previous != nil
    }
    
    /// Is on the final step
    var isOnFinalStep: Bool {
        currentStep == .review
    }
    
    /// Is on first step
    var isOnFirstStep: Bool {
        currentStep == .basicInfo
    }
    
    /// Completed steps
    var completedSteps: [RegistrationStep] {
        RegistrationStep.allCases.filter { $0.rawValue < currentStep.rawValue }
    }
    
    // MARK: - Initialization
    
    init() {
        // Check for session timeout before loading data
        if SessionTimeoutManager.shared.checkTimeout() {
            // Session timed out, start fresh
            self.registrationData = KYCRegistrationData()
            KYCRegistrationData.clear()
            SecureKeychainStorage.shared.clearAllSensitiveData()
        } else if let savedData = KYCRegistrationData.load() {
            // Load persisted data
            self.registrationData = savedData
            self.currentStep = savedData.currentStep
            
            // Restore SSN from Keychain if available
            if let storedSSN = SecureKeychainStorage.shared.retrieveTaxId() {
                self.registrationData.taxId = storedSSN
            }
        } else {
            self.registrationData = KYCRegistrationData()
        }
        
        setupAutoSave()
        setupValidation()
        setupSessionTimeout()
        setupRateLimiting()
    }
    
    // MARK: - Auto-Save
    
    private func setupAutoSave() {
        // Auto-save every 5 seconds when data changes
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveProgress()
            }
        }
    }
    
    private func setupValidation() {
        // Real-time validation as user types
        $registrationData
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.clearErrorForCurrentStep()
                // Record activity for session timeout
                self?.sessionManager.recordActivity()
            }
            .store(in: &cancellables)
    }
    
    private func setupSessionTimeout() {
        // Setup session timeout callback
        sessionManager.onSessionTimeout = { [weak self] in
            Task { @MainActor in
                self?.handleSessionTimeout()
            }
        }
        
        // Check session status every 30 seconds
        sessionCheckTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSessionTimeoutStatus()
            }
        }
    }
    
    private func setupRateLimiting() {
        // Subscribe to rate limiter state
        rateLimiter.$isOTPRateLimited
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOTPRateLimited)
    }
    
    private func updateSessionTimeoutStatus() {
        let remaining = sessionManager.remainingTime()
        sessionTimeoutSeconds = Int(remaining)
        
        // Show warning when less than 5 minutes remaining
        if remaining < 5 * 60 && remaining > 0 {
            showSessionTimeoutWarning = true
        } else {
            showSessionTimeoutWarning = false
        }
    }
    
    private func handleSessionTimeout() {
        // Clear all sensitive data
        clearProgress()
        showError = true
        errorMessage = "Your session has expired for security. Please start again."
    }
    
    /// Record user activity to prevent session timeout
    func recordUserActivity() {
        sessionManager.recordActivity()
        showSessionTimeoutWarning = false
    }
    
    /// Save current progress to persistence
    /// Note: SSN is stored in Keychain, not UserDefaults
    func saveProgress() {
        // Store SSN securely in Keychain (never in UserDefaults)
        if !registrationData.taxId.isEmpty {
            keychainStorage.storeTaxId(registrationData.taxId)
            
            // Create a copy without SSN for UserDefaults persistence
            var safeData = registrationData
            safeData.taxId = "" // Don't store in UserDefaults
            safeData.currentStep = currentStep
            try? safeData.save()
        } else {
            registrationData.currentStep = currentStep
            try? registrationData.save()
        }
    }
    
    /// Clear all saved progress and reset
    func clearProgress() {
        // Clear from UserDefaults
        KYCRegistrationData.clear()
        
        // Clear sensitive data from Keychain
        keychainStorage.clearAllSensitiveData()
        
        // Clear in-memory data securely
        SensitiveFieldCleaner.clearRegistrationData(&registrationData)
        
        // Reset state
        registrationData = KYCRegistrationData()
        currentStep = .basicInfo
        confirmPassword = ""
        error = nil
        stepValidationErrors = [:]
        
        // Reset session
        sessionManager.resetSession()
    }
    
    // MARK: - Navigation
    
    /// Move to the next step if validation passes
    func nextStep() {
        guard validateCurrentStep() else { return }
        
        if let next = currentStep.next {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
            }
            saveProgress()
        }
    }
    
    /// Move to the previous step
    func previousStep() {
        if let prev = currentStep.previous {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = prev
            }
            saveProgress()
        }
    }
    
    /// Jump to a specific step (only if it's accessible)
    func goToStep(_ step: RegistrationStep) {
        // Can only jump to completed steps or the current step
        if step.rawValue <= currentStep.rawValue {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = step
            }
        }
    }
    
    // MARK: - Validation
    
    /// Validate the current step
    @discardableResult
    func validateCurrentStep() -> Bool {
        clearErrorForCurrentStep()
        
        switch currentStep {
        case .basicInfo:
            return validateBasicInfo()
        case .personalDetails:
            return validatePersonalDetails()
        case .address:
            return validateAddress()
        case .taxFinancial:
            return validateTaxFinancial()
        case .disclosures:
            return validateDisclosures()
        case .trustedContact:
            return true // Optional step
        case .agreements:
            return validateAgreements()
        case .review:
            return validateAll()
        }
    }
    
    private func validateBasicInfo() -> Bool {
        var errors: [String] = []
        
        // Email validation using RegistrationValidator
        let emailResult = RegistrationValidator.validateEmail(registrationData.email)
        if let emailError = emailResult.errorMessage {
            errors.append(emailError)
        }
        
        // Password validation using RegistrationValidator
        let passwordResult = RegistrationValidator.validatePassword(registrationData.password)
        if let passwordError = passwordResult.errorMessage {
            errors.append(passwordError)
        }
        
        // Confirm password
        if confirmPassword != registrationData.password {
            errors.append("Passwords do not match")
        }
        
        // Name validation using RegistrationValidator
        let firstNameResult = RegistrationValidator.validateName(registrationData.firstName, fieldName: "First name")
        if let firstNameError = firstNameResult.errorMessage {
            errors.append(firstNameError)
        }
        
        let lastNameResult = RegistrationValidator.validateName(registrationData.lastName, fieldName: "Last name")
        if let lastNameError = lastNameResult.errorMessage {
            errors.append(lastNameError)
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.basicInfo] = errors
            return false
        }
        
        return true
    }
    
    private func validatePersonalDetails() -> Bool {
        var errors: [String] = []
        
        // Date of birth validation
        guard let dob = registrationData.dateOfBirth else {
            errors.append("Date of birth is required")
            stepValidationErrors[.personalDetails] = errors
            return false
        }
        
        // Age check using RegistrationValidator (FINRA 18+ requirement)
        let ageResult = RegistrationValidator.validateAge(dob)
        if let ageError = ageResult.errorMessage {
            errors.append(ageError)
        }
        
        // Phone number validation using RegistrationValidator
        let phoneResult = RegistrationValidator.validatePhone(registrationData.phoneNumber)
        if let phoneError = phoneResult.errorMessage {
            errors.append(phoneError)
        }
        
        // Citizenship
        if registrationData.citizenship.isEmpty {
            errors.append("Citizenship is required")
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.personalDetails] = errors
            return false
        }
        
        return true
    }
    
    private func validateAddress() -> Bool {
        var errors: [String] = []
        
        // Street address validation using RegistrationValidator
        let streetResult = RegistrationValidator.validateStreetAddress(registrationData.streetAddress)
        if let streetError = streetResult.errorMessage {
            errors.append(streetError)
        }
        
        // City validation using RegistrationValidator
        let cityResult = RegistrationValidator.validateCity(registrationData.city)
        if let cityError = cityResult.errorMessage {
            errors.append(cityError)
        }
        
        // State validation using RegistrationValidator
        let stateResult = RegistrationValidator.validateState(registrationData.state)
        if let stateError = stateResult.errorMessage {
            errors.append(stateError)
        }
        
        // ZIP code validation using RegistrationValidator
        let zipResult = RegistrationValidator.validateZipCode(registrationData.postalCode, country: registrationData.country)
        if let zipError = zipResult.errorMessage {
            errors.append(zipError)
        } else if registrationData.postalCode.isEmpty {
            errors.append("Postal code is required")
        }
        
        if registrationData.country.isEmpty {
            errors.append("Country is required")
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.address] = errors
            return false
        }
        
        return true
    }
    
    private func validateTaxFinancial() -> Bool {
        var errors: [String] = []
        
        // SSN/Tax ID validation using RegistrationValidator
        if registrationData.taxId.isEmpty {
            errors.append("Tax ID is required")
        } else if registrationData.taxIdType == .ssn || registrationData.taxIdType == .itin {
            let ssnResult = RegistrationValidator.validateSSN(registrationData.taxId)
            if let ssnError = ssnResult.errorMessage {
                errors.append(ssnError)
            }
        } else {
            // For foreign IDs, just check length
            let digits = registrationData.taxId.filter { $0.isNumber }
            if digits.count < 5 {
                errors.append("Please enter a valid \(registrationData.taxIdType.displayName)")
            }
        }
        
        // Funding sources
        if registrationData.fundingSources.isEmpty {
            errors.append("Please select at least one funding source")
        }
        
        // Employment info
        if registrationData.employmentStatus == .none {
            errors.append("Employment status is required")
        }
        
        if registrationData.employmentStatus.requiresEmployerInfo {
            if registrationData.employer?.isEmpty ?? true {
                errors.append("Employer name is required")
            }
            if registrationData.occupation?.isEmpty ?? true {
                errors.append("Occupation is required")
            }
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.taxFinancial] = errors
            return false
        }
        
        return true
    }
    
    private func validateDisclosures() -> Bool {
        var errors: [String] = []
        
        // If control person, need context
        if registrationData.isControlPerson &&
           (registrationData.controlPersonContext?.isEmpty ?? true) {
            errors.append("Please provide details about your control person status")
        }
        
        // If affiliated with exchange, need context
        if registrationData.isAffiliatedWithExchange &&
           (registrationData.affiliationContext?.isEmpty ?? true) {
            errors.append("Please provide details about your exchange affiliation")
        }
        
        // If politically exposed, need context
        if registrationData.isPoliticallyExposed &&
           (registrationData.politicalExposureContext?.isEmpty ?? true) {
            errors.append("Please provide details about your political exposure")
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.disclosures] = errors
            return false
        }
        
        return true
    }
    
    private func validateAgreements() -> Bool {
        var errors: [String] = []
        
        if !registrationData.agreedToTerms {
            errors.append("You must accept the Terms of Service")
        }
        if !registrationData.agreedToPrivacy {
            errors.append("You must accept the Privacy Policy")
        }
        if !registrationData.agreedToAccountAgreement {
            errors.append("You must accept the Account Agreement")
        }
        if !registrationData.agreedToCustomerAgreement {
            errors.append("You must accept the Customer Agreement")
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.agreements] = errors
            return false
        }
        
        return true
    }
    
    private func validateAll() -> Bool {
        // Validate all required steps
        let basicValid = validateBasicInfo()
        let personalValid = validatePersonalDetails()
        let addressValid = validateAddress()
        let taxValid = validateTaxFinancial()
        let disclosuresValid = validateDisclosures()
        let agreementsValid = validateAgreements()
        
        return basicValid && personalValid && addressValid && taxValid && disclosuresValid && agreementsValid
    }
    
    private func clearErrorForCurrentStep() {
        stepValidationErrors[currentStep] = nil
    }
    
    // MARK: - Validation Helpers
    
    // Note: Validation is now handled by RegistrationValidator in RegistrationSecurity.swift
    // This provides centralized, reusable, FINRA-compliant validation rules
    
    // MARK: - Formatting Helpers
    
    /// Format SSN as user types (XXX-XX-XXXX)
    func formatTaxId(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var result = ""
        
        for (index, digit) in digits.prefix(9).enumerated() {
            if index == 3 || index == 5 {
                result += "-"
            }
            result += String(digit)
        }
        
        return result
    }
    
    /// Format phone number as user types
    func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var result = ""
        
        for (index, digit) in digits.prefix(10).enumerated() {
            if index == 0 {
                result += "("
            }
            if index == 3 {
                result += ") "
            }
            if index == 6 {
                result += "-"
            }
            result += String(digit)
        }
        
        return result
    }
    
    // MARK: - Funding Source Toggle
    
    func toggleFundingSource(_ source: FundingSource) {
        if registrationData.fundingSources.contains(source) {
            registrationData.fundingSources.removeAll { $0 == source }
        } else {
            registrationData.fundingSources.append(source)
        }
    }
    
    func isFundingSourceSelected(_ source: FundingSource) -> Bool {
        registrationData.fundingSources.contains(source)
    }
    
    // MARK: - OTP Phone Verification with Twilio
    
    /// Send OTP verification code to user's phone number
    /// Uses Twilio Verify API with rate limiting protection
    /// - Parameter channel: Delivery channel (sms or call), defaults to sms
    func sendOTP(channel: VerificationChannel = .sms) async {
        let identifier = registrationData.phoneNumber.filter { $0.isNumber }
        
        // Check rate limit
        guard rateLimiter.canRequestOTP(identifier: identifier) else {
            let remainingSeconds = Int(rateLimiter.timeUntilOTPReset(identifier: identifier) ?? 0)
            verificationError = RateLimitError.otpLimitExceeded(remainingSeconds: remainingSeconds).localizedDescription
            isOTPRateLimited = true
            otpCooldownSeconds = remainingSeconds
            return
        }
        
        // Update UI state
        isSendingOTP = true
        verificationError = nil
        
        do {
            // Send OTP via Twilio Verify
            let sid = try await twilioService.sendOTP(to: registrationData.phoneNumber, channel: channel)
            
            // Record the attempt for rate limiting
            rateLimiter.recordOTPRequest(identifier: identifier)
            
            // Update state on success
            verificationSid = sid
            otpSent = true
            otpRemainingAttempts = rateLimiter.remainingOTPAttempts(identifier: identifier)
            isOTPRateLimited = !rateLimiter.canRequestOTP(identifier: identifier)
            
            if let cooldown = rateLimiter.timeUntilOTPReset(identifier: identifier) {
                otpCooldownSeconds = Int(cooldown)
            }
            
            print("✅ OTP sent successfully to \(maskPhone(registrationData.phoneNumber))")
            
        } catch let error as TwilioVerifyError {
            verificationError = error.localizedDescription
            
            // If max attempts reached, mark as rate limited
            if case .maxSendAttemptsReached = error {
                isOTPRateLimited = true
            }
            
            print("❌ Failed to send OTP: \(error.localizedDescription)")
            
        } catch {
            verificationError = "Failed to send verification code. Please try again."
            print("❌ Unexpected error sending OTP: \(error)")
        }
        
        isSendingOTP = false
    }
    
    /// Verify the OTP code entered by user
    /// - Parameter code: 6-digit verification code
    /// - Returns: True if verification successful
    @discardableResult
    func verifyOTP(code: String) async -> Bool {
        // Validate code format
        let cleanCode = code.filter { $0.isNumber }
        guard cleanCode.count == 6 else {
            verificationError = "Please enter a 6-digit verification code"
            return false
        }
        
        // Update UI state
        isVerifyingOTP = true
        verificationError = nil
        
        do {
            // Verify OTP via Twilio
            let success = try await twilioService.verifyOTP(
                phoneNumber: registrationData.phoneNumber,
                code: cleanCode
            )
            
            if success {
                isPhoneVerified = true
                verificationError = nil
                print("✅ Phone verified successfully!")
                return true
            } else {
                verificationError = "Verification failed. Please try again."
                return false
            }
            
        } catch let error as TwilioVerifyError {
            verificationError = error.localizedDescription
            
            // If should request new code, reset OTP state
            if error.shouldRequestNewCode {
                otpSent = false
                verificationSid = nil
            }
            
            print("❌ OTP verification failed: \(error.localizedDescription)")
            return false
            
        } catch {
            verificationError = "Verification failed. Please try again."
            print("❌ Unexpected error verifying OTP: \(error)")
            return false
        }
    }
    
    /// Resend OTP to user's phone
    /// - Parameter channel: Delivery channel (sms or call)
    func resendOTP(channel: VerificationChannel = .sms) async {
        // Reset state
        verificationSid = nil
        
        // Send new OTP
        await sendOTP(channel: channel)
    }
    
    /// Reset phone verification state (e.g., when changing phone number)
    func resetPhoneVerification() {
        otpSent = false
        isPhoneVerified = false
        verificationError = nil
        verificationSid = nil
        twilioService.reset()
    }
    
    /// Get formatted cooldown time for OTP
    var formattedOTPCooldown: String {
        let minutes = otpCooldownSeconds / 60
        let seconds = otpCooldownSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Mask phone number for logging (privacy)
    private func maskPhone(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        guard digits.count > 4 else { return "***" }
        let lastFour = digits.suffix(4)
        return "***\(lastFour)"
    }
    
    // MARK: - Submission
    
    /// Submit the registration to Alpaca
    /// Implements secure data handling and rate limiting
    func submitRegistration() async {
        guard validateAll() else {
            showError = true
            errorMessage = "Please complete all required fields"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Get IP address for agreements
            let ipAddress = await getIPAddress()
            registrationData.ipAddress = ipAddress
            
            // Check account creation rate limit
            guard rateLimiter.canCreateAccount(ipAddress: ipAddress) else {
                let remainingSeconds = Int(rateLimiter.timeUntilOTPReset(identifier: "account_\(ipAddress)") ?? 3600)
                throw RateLimitError.accountCreationLimitExceeded(remainingSeconds: remainingSeconds)
            }
            
            // Record account creation attempt
            rateLimiter.recordAccountCreation(ipAddress: ipAddress)
            
            // Retrieve SSN from secure Keychain storage for transmission
            // (it was stored there during the tax info step)
            if let storedSSN = keychainStorage.retrieveTaxId() {
                registrationData.taxId = storedSSN
            }
            
            // Create account via Alpaca
            let accountId = try await createAlpacaAccount()
            
            // ========== SECURITY: Clear Sensitive Data After Submission ==========
            
            // 1. Clear SSN from Keychain (no longer needed after account creation)
            keychainStorage.deleteTaxId()
            keychainStorage.deleteSSN()
            
            // 2. Clear sensitive fields from memory
            SensitiveFieldCleaner.clearRegistrationData(&registrationData)
            
            // 3. Clear password from memory (overwrite then clear)
            var tempPassword = registrationData.password
            SensitiveFieldCleaner.clearString(&tempPassword)
            registrationData.password = ""
            
            // 4. Clear confirm password
            var tempConfirm = confirmPassword
            SensitiveFieldCleaner.clearString(&tempConfirm)
            confirmPassword = ""
            
            // 5. Clear saved registration data from UserDefaults
            KYCRegistrationData.clear()
            
            // =======================================================================
            
            // Store account ID (this is not sensitive)
            UserDefaults.standard.set(accountId, forKey: "alpaca_account_id")
            
            // Stop session timeout monitoring
            sessionManager.stopTimer()
            
            createdAccountId = accountId
            registrationComplete = true
            
        } catch let alpacaError {
            errorMessage = alpacaError.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    private func createAlpacaAccount() async throws -> String {
        // Build Alpaca request from registration data
        let contact = AlpacaContact(
            email_address: registrationData.email,
            phone_number: registrationData.phoneNumber.filter { $0.isNumber },
            street_address: registrationData.fullStreetAddress,
            city: registrationData.city,
            state: registrationData.state,
            postal_code: registrationData.postalCode,
            country: registrationData.country
        )
        
        // Note: SSN is transmitted over HTTPS (encrypted in transit)
        // For additional security, the Alpaca Broker API handles PII securely
        let cleanedTaxId = registrationData.taxId.filter { $0.isNumber }
        
        let identity = AlpacaIdentity(
            given_name: registrationData.firstName,
            family_name: registrationData.lastName,
            date_of_birth: registrationData.formattedDateOfBirth ?? "",
            tax_id: cleanedTaxId,
            tax_id_type: registrationData.taxIdType.alpacaValue,
            country_of_citizenship: registrationData.citizenship,
            country_of_birth: registrationData.countryOfBirth,
            country_of_tax_residence: registrationData.countryOfTaxResidence,
            funding_source: registrationData.fundingSources.map { $0.rawValue }
        )
        
        let disclosures = AlpacaDisclosures(
            is_control_person: registrationData.isControlPerson,
            is_affiliated_exchange_or_finra: registrationData.isAffiliatedWithExchange,
            is_politically_exposed: registrationData.isPoliticallyExposed,
            immediate_family_exposed: registrationData.immediateFamilyExposed
        )
        
        // Generate agreement timestamps
        let now = ISO8601DateFormatter().string(from: Date())
        let ip = registrationData.ipAddress ?? "0.0.0.0"
        
        let agreements = [
            AlpacaAgreement(agreement: "customer_agreement", signed_at: now, ip_address: ip),
            AlpacaAgreement(agreement: "account_agreement", signed_at: now, ip_address: ip),
            AlpacaAgreement(agreement: "margin_agreement", signed_at: now, ip_address: ip)
        ]
        
        // Create account with full KYC data
        return try await alpacaService.createAccountWithKYC(
            contact: contact,
            identity: identity,
            disclosures: disclosures,
            agreements: agreements,
            trustedContact: buildTrustedContact()
        )
    }
    
    private func buildTrustedContact() -> AlpacaTrustedContact? {
        guard let name = registrationData.trustedContactName, !name.isEmpty else {
            return nil
        }
        
        return AlpacaTrustedContact(
            given_name: name.components(separatedBy: " ").first ?? name,
            family_name: name.components(separatedBy: " ").dropFirst().joined(separator: " "),
            email_address: registrationData.trustedContactEmail,
            phone_number: registrationData.trustedContactPhone
        )
    }
    
    private func getIPAddress() async -> String {
        // In production, this would fetch the real IP
        // For now, return placeholder
        return "127.0.0.1"
    }
    
    // MARK: - Secure SSN Storage
    
    /// Store SSN securely when user enters it
    /// Call this when the SSN field changes
    func storeSSNSecurely(_ ssn: String) {
        // Validate first
        let result = RegistrationValidator.validateSSN(ssn)
        if result.isValid {
            keychainStorage.storeTaxId(ssn)
        }
        // Store in memory for display (masked in UI)
        registrationData.taxId = ssn
    }
    
    /// Get masked SSN for display (XXX-XX-1234)
    func getMaskedSSN() -> String {
        let ssn = registrationData.taxId.filter { $0.isNumber }
        guard ssn.count >= 4 else { return "XXX-XX-XXXX" }
        let lastFour = ssn.suffix(4)
        return "XXX-XX-\(lastFour)"
    }
    
    // MARK: - Cleanup
    
    deinit {
        autoSaveTimer?.invalidate()
        sessionCheckTimer?.invalidate()
    }
}

// MARK: - Step Progress Helpers

extension RegistrationViewModel {
    
    /// Get validation status for a specific step
    func validationStatus(for step: RegistrationStep) -> StepValidationStatus {
        // If step is after current step, it's pending
        if step.rawValue > currentStep.rawValue {
            return .pending
        }
        
        // If step is current step, check if it has errors
        if step == currentStep {
            if stepValidationErrors[step]?.isEmpty ?? true {
                return .inProgress
            } else {
                return .hasErrors
            }
        }
        
        // For completed steps, validate them
        let originalStep = currentStep
        let isValid: Bool
        
        switch step {
        case .basicInfo:
            isValid = registrationData.isBasicInfoComplete
        case .personalDetails:
            isValid = registrationData.isPersonalDetailsComplete
        case .address:
            isValid = registrationData.isAddressComplete
        case .taxFinancial:
            isValid = registrationData.isTaxFinancialComplete
        case .disclosures:
            isValid = registrationData.isDisclosuresComplete
        case .trustedContact:
            isValid = true // Optional
        case .agreements:
            isValid = registrationData.hasAllRequiredAgreements
        case .review:
            isValid = true
        }
        
        return isValid ? .completed : .hasErrors
    }
    
    /// Get errors for a specific step
    func errors(for step: RegistrationStep) -> [String] {
        stepValidationErrors[step] ?? []
    }
}

enum StepValidationStatus {
    case pending
    case inProgress
    case completed
    case hasErrors
    
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .hasErrors: return "exclamationmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "textTertiary"
        case .inProgress: return "primaryPurple"
        case .completed: return "successGreen"
        case .hasErrors: return "errorRed"
        }
    }
}

