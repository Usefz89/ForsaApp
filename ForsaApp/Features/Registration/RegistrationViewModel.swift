//
//  RegistrationViewModel.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//
//  Main registration ViewModel for multi-step KYC flow

import Foundation
import SwiftUI
import Combine
import Darwin  // For getifaddrs (local IP detection)

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
    
    /// Verification attempt tracking (BE-3: Expose Twilio attempt count to UI)
    @Published var verificationAttemptsMade: Int = 0
    @Published var verificationAttemptsRemaining: Int = TwilioVerifyService.maxVerificationAttempts
    @Published var maxVerificationAttemptsReached: Bool = false
    
    /// Session timeout state
    @Published var showSessionTimeoutWarning: Bool = false
    @Published var sessionTimeoutSeconds: Int = 0
    
    // MARK: - Retry State
    
    /// Whether the last submission can be retried
    @Published var canRetrySubmission: Bool = false
    
    /// The last error that occurred during submission (for retry logic)
    @Published var lastSubmissionError: Error?
    
    /// Number of retry attempts made
    @Published var retryAttempts: Int = 0
    
    // MARK: - Account Status Polling State
    
    /// Current account status from Alpaca
    @Published var accountStatusResult: AlpacaAccountCreationResult?
    
    /// Whether we are currently polling for status
    @Published var isPollingAccountStatus: Bool = false
    
    /// Number of poll attempts made
    @Published var pollAttempts: Int = 0
    
    /// Maximum poll attempts before giving up
    let maxPollAttempts: Int = 20
    
    /// Polling interval in seconds
    let pollIntervalSeconds: TimeInterval = 15
    
    /// Error during polling
    @Published var pollingError: String?
    
    /// Required actions from Alpaca (if any)
    @Published var requiredActions: [AlpacaAccountCreationResult.RequiredAction] = []
    
    /// Rejection reasons (if rejected)
    @Published var rejectionReasons: [String] = []
    
    /// Task handle for polling (for cancellation)
    private var pollingTask: Task<Void, Never>?
    
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
            // Reset phone verification state for fresh session
            twilioService.reset()
        } else if let savedData = KYCRegistrationData.load() {
            // Load persisted data
            self.registrationData = savedData
            self.currentStep = savedData.currentStep
            
            // Restore SSN from Keychain if available
            if let storedSSN = SecureKeychainStorage.shared.retrieveTaxId() {
                self.registrationData.taxId = storedSSN
            }
            
            // If resuming from before phone verification, reset Twilio state
            if savedData.currentStep.rawValue <= RegistrationStep.phoneVerification.rawValue {
                twilioService.reset()
            }
        } else {
            // Brand new registration - reset all phone verification state
            self.registrationData = KYCRegistrationData()
            twilioService.reset()
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
        
        // Auto-fill employer name for self-employed users (EC-4 fix)
        $registrationData
            .map { $0.employmentStatus }
            .removeDuplicates()
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .selfEmployed {
                    // Auto-fill employer name with user's full name if empty
                    if self.registrationData.employer?.isEmpty ?? true {
                        let fullName = self.registrationData.fullName
                        if !fullName.isEmpty {
                            self.registrationData.employer = fullName
                        }
                    }
                }
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
        
        // BE-3: Subscribe to Twilio verification attempt tracking
        twilioService.$verificationAttempts
            .receive(on: DispatchQueue.main)
            .assign(to: &$verificationAttemptsMade)
        
        twilioService.$remainingAttempts
            .receive(on: DispatchQueue.main)
            .assign(to: &$verificationAttemptsRemaining)
        
        twilioService.$maxAttemptsReached
            .receive(on: DispatchQueue.main)
            .assign(to: &$maxVerificationAttemptsReached)
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
        // Don't save if registration is already complete
        guard !registrationComplete else { return }
        
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
    
    /// Stop auto-save timer (called when registration completes)
    func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    /// Clear all saved progress and reset
    func clearProgress() {
        // Stop auto-save timer first
        stopAutoSave()
        
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
        registrationComplete = false
        createdAccountId = nil
        
        // Reset phone verification state (clears attempt counter)
        twilioService.reset()
        isPhoneVerified = false
        otpSent = false
        verificationError = nil
        verificationSid = nil
        
        // Reset session
        sessionManager.resetSession()
    }
    
    // MARK: - Navigation
    
    /// Move to the next step if validation passes
    func nextStep() {
        guard validateCurrentStep() else {
            // Provide error feedback when validation fails
            if let errors = stepValidationErrors[currentStep], !errors.isEmpty {
                errorMessage = errors.first ?? "Please complete all required fields"
                showError = true
            }
            return
        }
        
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
        case .phoneVerification:
            return validatePhoneVerification()
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
    
    private func validatePhoneVerification() -> Bool {
        // Phone must be verified to proceed
        if !isPhoneVerified {
            stepValidationErrors[.phoneVerification] = ["Please verify your phone number"]
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
        
        // Note: Phone validation is handled in validatePhoneVerification() (Step 2)
        // Personal details step only validates DOB, age, and citizenship
        
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
        
        // Check if user is in Kuwait
        let isKuwait = registrationData.country == "KWT"
        
        if isKuwait {
            // Kuwait-specific address validation
            if registrationData.block.isEmpty {
                errors.append("Block number is required")
            }
            
            if registrationData.streetAddress.isEmpty {
                errors.append("Street is required")
            }
            
            if registrationData.building.isEmpty {
                errors.append("Building number is required")
            }
            
            if registrationData.area.isEmpty {
                errors.append("Area is required")
            }
            
            if registrationData.governorate.isEmpty {
                errors.append("Governorate is required")
            }
        } else {
            // International address validation
            
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
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.address] = errors
            return false
        }
        
        return true
    }
    
    private func validateTaxFinancial() -> Bool {
        var errors: [String] = []
        
        // ID validation based on type
        if registrationData.taxId.isEmpty {
            errors.append(registrationData.taxIdType == .kuwaitCivilId ? "Civil ID is required" : "Tax ID is required")
        } else {
            switch registrationData.taxIdType {
            case .ssn:
                let ssnResult = RegistrationValidator.validateSSN(registrationData.taxId)
                if let ssnError = ssnResult.errorMessage {
                    errors.append(ssnError)
                }
            case .itin:
                let itinResult = RegistrationValidator.validateITIN(registrationData.taxId)
                if let itinError = itinResult.errorMessage {
                    errors.append(itinError)
                }
            case .kuwaitCivilId:
                // Kuwait Civil ID: 12 digits
                let civilIdResult = RegistrationValidator.validateKuwaitCivilId(registrationData.taxId)
                if let civilIdError = civilIdResult.errorMessage {
                    errors.append(civilIdError)
                }
            case .foreignPassport, .foreignId:
                // For foreign IDs, just check minimum length
                let cleanedId = registrationData.taxId.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanedId.count < 5 {
                    errors.append("Please enter a valid \(registrationData.taxIdType.displayName)")
                }
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
        // Validate all required steps including phone verification
        let basicValid = validateBasicInfo()
        let phoneValid = validatePhoneVerification()
        let personalValid = validatePersonalDetails()
        let addressValid = validateAddress()
        let taxValid = validateTaxFinancial()
        let disclosuresValid = validateDisclosures()
        let agreementsValid = validateAgreements()
        
        return basicValid && phoneValid && personalValid && addressValid && taxValid && disclosuresValid && agreementsValid
    }
    
    private func clearErrorForCurrentStep() {
        stepValidationErrors[currentStep] = nil
    }
    
    /// Builds a user-friendly error message from stepValidationErrors
    /// Shows which steps have issues and what the first error is
    private func buildValidationErrorMessage() -> String {
        var failedSteps: [String] = []
        var firstError: String?
        
        // Check each step in order
        let stepsToCheck: [RegistrationStep] = [
            .basicInfo, .phoneVerification, .personalDetails, 
            .address, .taxFinancial, .disclosures, .agreements
        ]
        
        for step in stepsToCheck {
            if let errors = stepValidationErrors[step], !errors.isEmpty {
                failedSteps.append(step.title)
                if firstError == nil {
                    firstError = errors.first
                }
            }
        }
        
        if failedSteps.isEmpty {
            return "Please complete all required fields"
        }
        
        if failedSteps.count == 1 {
            return firstError ?? "Please complete \(failedSteps[0])"
        }
        
        // Multiple steps have errors
        let stepsString = failedSteps.joined(separator: ", ")
        return "Issues found in: \(stepsString). \(firstError ?? "Please review and complete.")"
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
    /// Uses retry wrapper for network resilience (BE-2)
    /// Logs failed attempts for security auditing (BE-1)
    /// - Parameter code: 6-digit verification code
    /// - Returns: True if verification successful
    @discardableResult
    func verifyOTP(code: String) async -> Bool {
        // Validate code format
        let cleanCode = code.filter { $0.isNumber }
        guard cleanCode.count == 6 else {
            verificationError = "Please enter a 6-digit verification code"
            logVerificationAttempt(success: false, reason: "Invalid code format")
            return false
        }
        
        // Update UI state
        isVerifyingOTP = true
        verificationError = nil
        
        // Ensure loading state is reset when function exits
        defer { isVerifyingOTP = false }
        
        do {
            // BE-2: Use verifyOTPWithRetry for network resilience
            let success = try await twilioService.verifyOTPWithRetry(
                phoneNumber: registrationData.phoneNumber,
                code: cleanCode,
                maxAttempts: 2  // Network retries, not code retries
            )
            
            if success {
                isPhoneVerified = true
                verificationError = nil
                logVerificationAttempt(success: true, reason: nil)
                print("✅ Phone verified successfully!")
                return true
            } else {
                verificationError = "Verification failed. Please try again."
                logVerificationAttempt(success: false, reason: "Verification returned false")
                return false
            }
            
        } catch let error as TwilioVerifyError {
            verificationError = error.localizedDescription
            
            // BE-1: Log failed verification attempt for security auditing
            logVerificationAttempt(
                success: false,
                reason: error.localizedDescription
            )
            
            // If should request new code, reset OTP state
            if error.shouldRequestNewCode {
                otpSent = false
                verificationSid = nil
            }
            
            print("❌ OTP verification failed: \(error.localizedDescription)")
            return false
            
        } catch {
            verificationError = "Verification failed. Please try again."
            logVerificationAttempt(success: false, reason: error.localizedDescription)
            print("❌ Unexpected error verifying OTP: \(error)")
            return false
        }
    }
    
    // MARK: - Security Audit Logging (BE-1)
    
    /// Logs verification attempts for security auditing
    /// Important for detecting fraud and compliance reporting
    /// - Parameters:
    ///   - success: Whether the verification was successful
    ///   - reason: Reason for failure (if applicable)
    private func logVerificationAttempt(success: Bool, reason: String?) {
        let maskedPhone = maskPhone(registrationData.phoneNumber)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let attemptNumber = verificationAttemptsMade
        let remaining = verificationAttemptsRemaining
        
        var logEntry = """
        🔐 SECURITY AUDIT - Phone Verification Attempt
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Timestamp: \(timestamp)
        Phone: \(maskedPhone)
        Attempt #: \(attemptNumber)
        Remaining: \(remaining)
        Result: \(success ? "✅ SUCCESS" : "❌ FAILED")
        """
        
        if let reason = reason {
            logEntry += "\nReason: \(reason)"
        }
        
        logEntry += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        print(logEntry)
        
        // In production, this would also:
        // 1. Send to analytics/logging service (e.g., Firebase Analytics, Amplitude)
        // 2. Store locally for compliance auditing
        // 3. Trigger alerts for suspicious patterns (e.g., via backend webhook)
        
        // Detect suspicious patterns - multiple failed attempts
        if !success && attemptNumber >= 3 {
            print("⚠️ SECURITY ALERT: Multiple failed verification attempts for \(maskedPhone)")
            // In production: trigger security alert to backend
        }
        
        // Detect lockout condition
        if remaining == 0 {
            print("🚨 SECURITY ALERT: Max verification attempts reached for \(maskedPhone)")
            // In production: log to fraud detection system
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
        // Security check: Abort if session has timed out
        guard !sessionManager.hasTimedOut else {
            handleSessionTimeout()
            return
        }
        
        guard validateAll() else {
            showError = true
            errorMessage = buildValidationErrorMessage()
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
            
            // Security check: If session timed out during API call, abort and clear data
            guard !sessionManager.hasTimedOut else {
                // Clear any data that was retrieved/created
                keychainStorage.clearAllSensitiveData()
                handleSessionTimeout()
                isLoading = false
                return
            }
            
            // Save user info BEFORE clearing sensitive data (needed for auth flow)
            UserDefaults.standard.set(registrationData.firstName, forKey: "user_first_name")
            UserDefaults.standard.set(registrationData.lastName, forKey: "user_last_name")
            UserDefaults.standard.set(registrationData.email, forKey: "forsa_user_email")
            
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
            
            // Stop auto-save timer (registration is complete)
            stopAutoSave()
            
            createdAccountId = accountId
            registrationComplete = true
            
            // Advance to account status view (Step 10)
            currentStep = .review
            
        } catch let alpacaError as AlpacaAPIError {
            // Handle Alpaca-specific errors with user-friendly messages
            errorMessage = alpacaError.localizedDescription
            showError = true
            
            // Store the error type for potential retry
            lastSubmissionError = alpacaError
            canRetrySubmission = alpacaError.isRetryable
            
        } catch let alpacaError {
            errorMessage = alpacaError.localizedDescription
            showError = true
            
            // Check if this might be a network error that's retryable
            canRetrySubmission = isRetryableError(alpacaError)
            lastSubmissionError = alpacaError
        }
        
        isLoading = false
    }
    
    /// Submit registration with automatic retry for transient failures
    /// Uses exponential backoff for retries
    /// - Parameter maxAttempts: Maximum number of attempts (default: 3)
    func submitRegistrationWithRetry(maxAttempts: Int = 3) async {
        var lastError: Error?
        var attemptCount = 0
        
        isLoading = true
        showError = false
        
        for attempt in 1...maxAttempts {
            attemptCount = attempt
            
            do {
                try await performRegistrationSubmission()
                // Success - exit the retry loop
                isLoading = false
                return
                
            } catch let error as AlpacaAPIError {
                lastError = error
                print("⚠️ Registration attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Don't retry non-retryable errors
                guard error.isRetryable else {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    canRetrySubmission = false
                    return
                }
                
                // Wait before retrying with exponential backoff
                if attempt < maxAttempts {
                    let delaySeconds = pow(2.0, Double(attempt))
                    print("   Retrying in \(Int(delaySeconds)) seconds...")
                    try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
                
            } catch {
                lastError = error
                print("⚠️ Registration attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Check if retryable
                guard isRetryableError(error) else {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    canRetrySubmission = false
                    return
                }
                
                // Wait before retrying
                if attempt < maxAttempts {
                    let delaySeconds = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
            }
        }
        
        // All attempts failed
        isLoading = false
        showError = true
        canRetrySubmission = true
        
        if let alpacaError = lastError as? AlpacaAPIError {
            errorMessage = "\(alpacaError.localizedDescription)\n\nFailed after \(attemptCount) attempts. Tap to retry."
        } else {
            errorMessage = (lastError?.localizedDescription ?? "Registration failed") + "\n\nFailed after \(attemptCount) attempts. Tap to retry."
        }
    }
    
    /// Internal submission logic that throws errors for retry handling
    private func performRegistrationSubmission() async throws {
        // Security check: Abort if session has timed out
        guard !sessionManager.hasTimedOut else {
            handleSessionTimeout()
            throw AlpacaAPIError.networkError("Session timed out")
        }
        
        guard validateAll() else {
            throw AlpacaAPIError.validationFailed(buildValidationErrorMessage())
        }
        
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
        
        // Retrieve SSN from secure Keychain storage
        if let storedSSN = keychainStorage.retrieveTaxId() {
            registrationData.taxId = storedSSN
        }
        
        // Create account via Alpaca (throws on failure)
        let accountId = try await createAlpacaAccount()
        
        // Security check: If session timed out during API call, abort
        guard !sessionManager.hasTimedOut else {
            keychainStorage.clearAllSensitiveData()
            handleSessionTimeout()
            throw AlpacaAPIError.networkError("Session timed out during registration")
        }
        
        // Save user info BEFORE clearing (needed for auth flow)
        UserDefaults.standard.set(registrationData.firstName, forKey: "user_first_name")
        UserDefaults.standard.set(registrationData.lastName, forKey: "user_last_name")
        UserDefaults.standard.set(registrationData.email, forKey: "forsa_user_email")
        
        // ========== SECURITY: Clear Sensitive Data After Submission ==========
        keychainStorage.deleteTaxId()
        keychainStorage.deleteSSN()
        SensitiveFieldCleaner.clearRegistrationData(&registrationData)
        
        var tempPassword = registrationData.password
        SensitiveFieldCleaner.clearString(&tempPassword)
        registrationData.password = ""
        
        var tempConfirm = confirmPassword
        SensitiveFieldCleaner.clearString(&tempConfirm)
        confirmPassword = ""
        
        KYCRegistrationData.clear()
        // =======================================================================
        
        // Store account ID
        UserDefaults.standard.set(accountId, forKey: "alpaca_account_id")
        
        // Stop session timeout monitoring
        sessionManager.stopTimer()
        
        // Stop auto-save timer (registration is complete)
        stopAutoSave()
        
        createdAccountId = accountId
        registrationComplete = true
        canRetrySubmission = false
        
        // Advance to account status view (Step 10)
        currentStep = .review
    }
    
    /// Determines if an error is potentially recoverable by retrying
    private func isRetryableError(_ error: Error) -> Bool {
        // Check for URL errors that indicate network issues
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost,
                 .notConnectedToInternet, .dnsLookupFailed, .cannotFindHost:
                return true
            default:
                return false
            }
        }
        
        // Check for Alpaca API errors
        if let alpacaError = error as? AlpacaAPIError {
            return alpacaError.isRetryable
        }
        
        return false
    }
    
    private func createAlpacaAccount() async throws -> String {
        // Build Alpaca request from registration data
        // Handle Kuwait-specific address mapping
        let isKuwait = registrationData.country == "KWT"
        
        // For Kuwait: map area → city, governorate → state
        let cityValue = isKuwait ? registrationData.area : registrationData.city
        let stateValue = isKuwait ? registrationData.governorate : registrationData.state
        // Kuwait doesn't use postal codes, use "00000" as placeholder
        let postalCodeValue = isKuwait ? "00000" : registrationData.postalCode
        
        // Build full street address for Kuwait (Block X, Building Y, Street Z)
        let streetAddress: [String]
        if isKuwait {
            var addressParts: [String] = []
            if !registrationData.block.isEmpty {
                addressParts.append("Block \(registrationData.block)")
            }
            if !registrationData.building.isEmpty {
                addressParts.append("Building \(registrationData.building)")
            }
            if !registrationData.streetAddress.isEmpty {
                addressParts.append(registrationData.streetAddress)
            }
            if let floor = registrationData.floor, !floor.isEmpty {
                addressParts.append("Floor \(floor)")
            }
            if let apt = registrationData.apartmentUnit, !apt.isEmpty {
                addressParts.append("Apt \(apt)")
            }
            streetAddress = [addressParts.joined(separator: ", ")]
        } else {
            streetAddress = registrationData.fullStreetAddress
        }
        
        let contact = AlpacaContact(
            email_address: registrationData.email,
            phone_number: registrationData.phoneNumber.filter { $0.isNumber },
            street_address: streetAddress,
            city: cityValue,
            state: stateValue,
            postal_code: postalCodeValue,
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
    
    /// Fetches the client's public IP address
    /// Required by Alpaca for compliance and agreement signing
    private func getIPAddress() async -> String {
        // Try multiple IP detection services for redundancy
        let ipServices = [
            "https://api.ipify.org",
            "https://ipinfo.io/ip",
            "https://checkip.amazonaws.com"
        ]
        
        for serviceURL in ipServices {
            do {
                guard let url = URL(string: serviceURL) else { continue }
                
                var request = URLRequest(url: url)
                request.timeoutInterval = 5  // 5 second timeout
                request.httpMethod = "GET"
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let ipString = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) else {
                    continue
                }
                
                // Validate IP format (basic check for IPv4 or IPv6)
                if isValidIPAddress(ipString) {
                    print("✅ IP Address detected: \(ipString) (via \(serviceURL))")
                    return ipString
                }
            } catch {
                print("⚠️ IP detection failed for \(serviceURL): \(error.localizedDescription)")
                continue
            }
        }
        
        // Fallback to local device IP if external services fail
        if let localIP = getLocalIPAddress() {
            print("⚠️ Using local IP as fallback: \(localIP)")
            return localIP
        }
        
        // Last resort fallback
        print("⚠️ IP detection failed, using fallback")
        return "0.0.0.0"
    }
    
    /// Validates IP address format (IPv4 or IPv6)
    private func isValidIPAddress(_ ip: String) -> Bool {
        // IPv4 pattern
        let ipv4Pattern = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        // IPv6 pattern (simplified)
        let ipv6Pattern = "^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::$|^([0-9a-fA-F]{1,4}:)*:[0-9a-fA-F]{1,4}$"
        
        let ipv4Regex = try? NSRegularExpression(pattern: ipv4Pattern)
        let ipv6Regex = try? NSRegularExpression(pattern: ipv6Pattern)
        
        let range = NSRange(ip.startIndex..., in: ip)
        
        return ipv4Regex?.firstMatch(in: ip, range: range) != nil ||
               ipv6Regex?.firstMatch(in: ip, range: range) != nil
    }
    
    /// Gets local device IP address as fallback
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {  // IPv4
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "pdp_ip0" {  // WiFi or cellular
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }
        
        return address
    }
    
    // MARK: - Account Status Polling
    
    /// Starts polling for account status updates after registration
    /// Call this from Step10_AccountStatusView when it appears
    func startAccountStatusPolling() {
        guard let accountId = createdAccountId else {
            pollingError = "No account ID available"
            return
        }
        
        // Cancel any existing polling task
        stopAccountStatusPolling()
        
        isPollingAccountStatus = true
        pollAttempts = 0
        pollingError = nil
        
        print("🔄 Starting account status polling for: \(accountId)")
        
        pollingTask = Task {
            await pollAccountStatusLoop(accountId: accountId)
        }
    }
    
    /// Stops the polling loop
    func stopAccountStatusPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPollingAccountStatus = false
        print("⏹️ Stopped account status polling")
    }
    
    /// The main polling loop
    private func pollAccountStatusLoop(accountId: String) async {
        // Initial delay to allow Alpaca to register the account
        // Newly created accounts may not be immediately queryable
        print("⏳ Waiting 3 seconds for account to be registered...")
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        while !Task.isCancelled && pollAttempts < maxPollAttempts {
            pollAttempts += 1
            print("📊 Poll attempt \(pollAttempts)/\(maxPollAttempts) for account: \(accountId)")
            
            do {
                // Check account status via Alpaca
                let result = try await alpacaService.checkAccountStatus(accountId: accountId)
                
                // Update state on main actor
                await MainActor.run {
                    self.accountStatusResult = result
                    self.requiredActions = result.requiredActions
                    self.rejectionReasons = result.rejectionReasons ?? []
                }
                
                print("📊 Account status: \(result.status.displayTitle)")
                
                // Check if we should stop polling
                switch result.status {
                case .approved:
                    print("✅ Account approved!")
                    await MainActor.run {
                        self.isPollingAccountStatus = false
                    }
                    return
                    
                case .rejected:
                    print("❌ Account rejected")
                    await MainActor.run {
                        self.isPollingAccountStatus = false
                        self.pollingError = "Account application was rejected"
                    }
                    return
                    
                case .actionRequired:
                    print("⚠️ Action required - stopping poll")
                    await MainActor.run {
                        self.isPollingAccountStatus = false
                    }
                    return
                    
                case .submitted, .pendingReview:
                    // Continue polling
                    print("⏳ Status still pending, will poll again...")
                }
                
            } catch let error as AlpacaAPIError {
                // Handle specific API errors
                switch error {
                case .notFound:
                    // 404 "account not found" - common for newly created accounts
                    // Alpaca needs time to register the account, don't show error
                    print("⏳ Account not yet available (404), will retry...")
                    
                case .networkError(let message) where message.contains("not found") || message.contains("404"):
                    // Also handle network error variant of 404
                    print("⏳ Account not yet available, will retry...")
                    
                default:
                    print("❌ Poll error: \(error.localizedDescription)")
                    // Only show error after multiple failures to avoid flashing errors
                    if pollAttempts >= 3 {
                        await MainActor.run {
                            self.pollingError = error.localizedDescription
                        }
                    }
                }
            } catch {
                // Check if it's a 404 by looking at the error message
                let errorMessage = error.localizedDescription
                if errorMessage.contains("not found") || errorMessage.contains("404") || errorMessage.contains("40410000") {
                    print("⏳ Account not yet available, will retry...")
                } else {
                    print("❌ Poll error: \(errorMessage)")
                    // Only show error after multiple failures
                    if pollAttempts >= 3 {
                        await MainActor.run {
                            self.pollingError = errorMessage
                        }
                    }
                }
            }
            
            // Wait before next poll (unless cancelled)
            if !Task.isCancelled && pollAttempts < maxPollAttempts {
                do {
                    try await Task.sleep(nanoseconds: UInt64(pollIntervalSeconds * 1_000_000_000))
                } catch {
                    // Task was cancelled during sleep
                    break
                }
            }
        }
        
        // Polling ended
        await MainActor.run {
            self.isPollingAccountStatus = false
            if self.pollAttempts >= self.maxPollAttempts && self.accountStatusResult?.status != .approved {
                print("⏰ Max poll attempts reached")
            }
        }
    }
    
    /// Manually check account status once (without polling loop)
    func checkAccountStatusOnce() async {
        guard let accountId = createdAccountId else {
            pollingError = "No account ID available"
            return
        }
        
        isPollingAccountStatus = true
        pollingError = nil
        
        do {
            let result = try await alpacaService.checkAccountStatus(accountId: accountId)
            accountStatusResult = result
            requiredActions = result.requiredActions
            rejectionReasons = result.rejectionReasons ?? []
            
        } catch {
            pollingError = error.localizedDescription
        }
        
        isPollingAccountStatus = false
    }
    
    /// Get the computed UI status from the Alpaca result
    var computedAccountStatus: AccountStatusUIState {
        guard let result = accountStatusResult else {
            if registrationComplete && createdAccountId != nil {
                return .pending
            }
            return .unknown
        }
        
        switch result.status {
        case .approved:
            return .approved
        case .rejected:
            return .rejected
        case .actionRequired:
            return .actionRequired
        case .submitted, .pendingReview:
            return .pending
        }
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
    
    // MARK: - Demo Account Creation
    
    /// Whether demo account creation is in progress
    @Published var isDemoAccountCreating: Bool = false
    
    /// Current step being processed during demo account creation
    @Published var demoAccountCurrentStep: String = ""
    
    /// Progress of demo account creation (0.0 to 1.0)
    @Published var demoAccountProgress: Double = 0.0
    
    /// Fills all registration data with random demo values and submits to sandbox
    /// This creates a complete sandboxed Alpaca account for testing
    func createDemoAccount() async {
        await MainActor.run {
            isDemoAccountCreating = true
            demoAccountProgress = 0.0
            demoAccountCurrentStep = "Generating profile..."
        }
        
        // Generate random demo data
        let demoData = DemoAccountGenerator.generate()
        
        await MainActor.run {
            demoAccountProgress = 0.1
            demoAccountCurrentStep = "Setting up account..."
            
            // Step 1: Basic Info
            registrationData.firstName = demoData.firstName
            registrationData.lastName = demoData.lastName
            registrationData.email = demoData.email
            registrationData.password = demoData.password
            confirmPassword = demoData.password
        }
        
        // Small delay for visual feedback
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.2
            demoAccountCurrentStep = "Verifying phone..."
            
            // Step 2: Phone (mark as verified for demo)
            registrationData.phoneNumber = demoData.phoneNumber
            isPhoneVerified = true // Skip actual verification for demo
            otpSent = true
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.3
            demoAccountCurrentStep = "Adding personal details..."
            
            // Step 3: Personal Details
            registrationData.dateOfBirth = demoData.dateOfBirth
            registrationData.citizenship = demoData.citizenship
            registrationData.countryOfBirth = demoData.countryOfBirth
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.4
            demoAccountCurrentStep = "Setting address..."
            
            // Step 4: Address (Kuwait format)
            registrationData.country = demoData.country
            registrationData.area = demoData.area
            registrationData.governorate = demoData.governorate
            registrationData.block = demoData.block
            registrationData.streetAddress = demoData.streetAddress
            registrationData.building = demoData.building
            registrationData.floor = demoData.floor
            registrationData.apartmentUnit = demoData.apartmentUnit
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.5
            demoAccountCurrentStep = "Adding financial info..."
            
            // Step 5/6: Financial Profile
            registrationData.taxId = demoData.taxId
            registrationData.taxIdType = demoData.taxIdType
            registrationData.countryOfTaxResidence = demoData.countryOfTaxResidence
            registrationData.fundingSources = demoData.fundingSources
            registrationData.employmentStatus = demoData.employmentStatus
            registrationData.employer = demoData.employer
            registrationData.occupation = demoData.occupation
            registrationData.annualIncome = demoData.annualIncome
            registrationData.netWorth = demoData.netWorth
            registrationData.liquidNetWorth = demoData.liquidNetWorth
            registrationData.investmentExperience = demoData.investmentExperience
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.6
            demoAccountCurrentStep = "Setting disclosures..."
            
            // Step 7: Disclosures (all false for demo - typical case)
            registrationData.isControlPerson = false
            registrationData.isAffiliatedWithExchange = false
            registrationData.isPoliticallyExposed = false
            registrationData.immediateFamilyExposed = false
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.7
            demoAccountCurrentStep = "Adding trusted contact..."
            
            // Step 8: Trusted Contact (optional, but add one for demo)
            registrationData.trustedContactName = demoData.trustedContactName
            registrationData.trustedContactEmail = demoData.trustedContactEmail
            registrationData.trustedContactPhone = demoData.trustedContactPhone
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.8
            demoAccountCurrentStep = "Accepting agreements..."
            
            // Step 9: Agreements
            registrationData.agreedToTerms = true
            registrationData.agreedToPrivacy = true
            registrationData.agreedToAccountAgreement = true
            registrationData.agreedToCustomerAgreement = true
            registrationData.agreedToMarginAgreement = true
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            demoAccountProgress = 0.9
            demoAccountCurrentStep = "Creating sandbox account..."
            currentStep = .review // Move to final step
        }
        
        // Submit to Alpaca sandbox
        await submitRegistration()
        
        await MainActor.run {
            demoAccountProgress = 1.0
            demoAccountCurrentStep = registrationComplete ? "Account created!" : "Completing setup..."
            isDemoAccountCreating = false
        }
    }
    
    /// Resets demo account creation state
    func resetDemoAccountState() {
        isDemoAccountCreating = false
        demoAccountProgress = 0.0
        demoAccountCurrentStep = ""
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
        let isValid: Bool
        
        switch step {
        case .basicInfo:
            isValid = registrationData.isBasicInfoComplete
        case .phoneVerification:
            isValid = isPhoneVerified
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
    
    // MARK: - Public Validation Methods for Views
    
    /// Validates personal details step and returns error messages
    /// Used by Step3_PersonalInfoView for inline validation
    func validatePersonalDetailsStep() -> [String] {
        var errors: [String] = []
        
        // Date of birth validation
        if registrationData.dateOfBirth == nil {
            errors.append("Please select your date of birth")
        } else if let dob = registrationData.dateOfBirth {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
            let age = ageComponents.year ?? 0
            
            if age < 18 {
                errors.append("You must be at least 18 years old to open an account")
            }
        }
        
        // Citizenship validation
        if registrationData.citizenship.isEmpty {
            errors.append("Please select your country of citizenship")
        }
        
        // Store errors for other components to access
        if !errors.isEmpty {
            stepValidationErrors[.personalDetails] = errors
        } else {
            stepValidationErrors[.personalDetails] = nil
        }
        
        return errors
    }
    
    /// Validates address step and returns error messages
    /// Used by Step4_AddressView for inline validation
    func validateAddressStep() -> [String] {
        var errors: [String] = []
        
        // Check if user is in Kuwait
        let isKuwait = registrationData.country == "KWT"
        
        if isKuwait {
            // Kuwait-specific validation
            if registrationData.block.isEmpty {
                errors.append("Please enter your block number")
            }
            
            if registrationData.streetAddress.isEmpty {
                errors.append("Please enter your street")
            }
            
            if registrationData.building.isEmpty {
                errors.append("Please enter your building number")
            }
            
            if registrationData.area.isEmpty {
                errors.append("Please enter your area")
            }
            
            if registrationData.governorate.isEmpty {
                errors.append("Please select your governorate")
            }
        } else {
            // International address validation
            if registrationData.streetAddress.isEmpty {
                errors.append("Please enter your street address")
            }
            
            if registrationData.city.isEmpty {
                errors.append("Please enter your city")
            }
            
            // State is required for US users
            if registrationData.country == "USA" && registrationData.state.isEmpty {
                errors.append("Please select your state")
            }
            
            if registrationData.postalCode.isEmpty {
                errors.append("Please enter your postal code")
            }
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.address] = errors
        } else {
            stepValidationErrors[.address] = nil
        }
        
        return errors
    }
    
    /// Validates tax/financial info step and returns error messages
    func validateTaxFinancialStep() -> [String] {
        var errors: [String] = []
        
        if registrationData.taxId.isEmpty {
            let taxIdLabel = registrationData.taxIdType == .kuwaitCivilId ? "Civil ID" : "SSN/Tax ID"
            errors.append("Please enter your \(taxIdLabel)")
        }
        
        if registrationData.fundingSources.isEmpty {
            errors.append("Please select at least one source of funds")
        }
        
        if registrationData.employmentStatus == .none {
            errors.append("Please select your employment status")
        }
        
        if !errors.isEmpty {
            stepValidationErrors[.taxFinancial] = errors
        } else {
            stepValidationErrors[.taxFinancial] = nil
        }
        
        return errors
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

// MARK: - Account Status UI State

/// UI state for account status display in Step10
enum AccountStatusUIState {
    case unknown
    case pending
    case approved
    case rejected
    case actionRequired
    
    var title: String {
        switch self {
        case .unknown: return "Checking Status..."
        case .pending: return "Account Under Review"
        case .approved: return "Welcome to Fursa!"
        case .rejected: return "Application Not Approved"
        case .actionRequired: return "Almost There"
        }
    }
    
    var subtitle: String {
        switch self {
        case .unknown: return "Please wait while we check your account status."
        case .pending: return "We're verifying your information. This usually takes just a few minutes."
        case .approved: return "Your account has been approved and is ready for investing."
        case .rejected: return "Unfortunately, we couldn't approve your application at this time."
        case .actionRequired: return "We need a bit more information to complete your account setup."
        }
    }
    
    var badge: String {
        switch self {
        case .unknown: return "CHECKING"
        case .pending: return "PENDING REVIEW"
        case .approved: return "APPROVED"
        case .rejected: return "NOT APPROVED"
        case .actionRequired: return "ACTION REQUIRED"
        }
    }
    
    var icon: String {
        switch self {
        case .unknown: return "hourglass"
        case .pending: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .actionRequired: return "exclamationmark.circle.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .unknown: return .textTertiary
        case .pending: return .primaryPurple
        case .approved: return .successGreen
        case .rejected: return .errorRed
        case .actionRequired: return .warningYellow
        }
    }
}

// MARK: - Demo Account Generator

/// Generates realistic random data for demo/sandbox account creation
struct DemoAccountGenerator {
    
    /// Generated demo account data
    struct DemoData {
        // Basic Info
        let firstName: String
        let lastName: String
        let email: String
        let password: String
        
        // Phone
        let phoneNumber: String
        
        // Personal
        let dateOfBirth: Date
        let citizenship: String
        let countryOfBirth: String
        
        // Address (Kuwait)
        let country: String
        let area: String
        let governorate: String
        let block: String
        let streetAddress: String
        let building: String
        let floor: String?
        let apartmentUnit: String?
        
        // Financial
        let taxId: String
        let taxIdType: TaxIdType
        let countryOfTaxResidence: String
        let fundingSources: [FundingSource]
        let employmentStatus: EmploymentStatus
        let employer: String?
        let occupation: String?
        let annualIncome: IncomeRange
        let netWorth: NetWorthRange
        let liquidNetWorth: LiquidNetWorthRange
        let investmentExperience: InvestmentExperience
        
        // Trusted Contact
        let trustedContactName: String
        let trustedContactEmail: String
        let trustedContactPhone: String
    }
    
    // MARK: - Name Data
    
    private static let kuwaitiFirstNames = [
        "Ahmed", "Mohammed", "Abdullah", "Yousef", "Omar",
        "Khalid", "Fahad", "Nasser", "Salem", "Faisal",
        "Fatima", "Nora", "Sara", "Maryam", "Aisha",
        "Layla", "Hessa", "Dalal", "Reem", "Dana"
    ]
    
    private static let kuwaitiLastNames = [
        "Al-Sabah", "Al-Khalid", "Al-Rashid", "Al-Mutairi", "Al-Shammari",
        "Al-Dosari", "Al-Ajmi", "Al-Enezi", "Al-Harbi", "Al-Otaibi",
        "Al-Subaie", "Al-Fahad", "Al-Salem", "Al-Hamad", "Al-Nasser"
    ]
    
    private static let kuwaitAreas = [
        "Salmiya", "Hawalli", "Jabriya", "Sharq", "Mishref",
        "Salwa", "Bayan", "Rumaithiya", "Mangaf", "Fintas",
        "Jahra", "Fahaheel", "Mahboula", "Sabah Al-Salem"
    ]
    
    private static let kuwaitGovernorates = [
        "Al Asimah", "Hawalli", "Al Farwaniyah", "Mubarak Al-Kabeer", "Al Ahmadi", "Al Jahra"
    ]
    
    private static let occupations = [
        "Software Engineer", "Business Analyst", "Marketing Manager",
        "Financial Analyst", "Project Manager", "Doctor",
        "Civil Engineer", "Architect", "Accountant",
        "Consultant", "Sales Manager", "Teacher"
    ]
    
    private static let companies = [
        "Kuwait Petroleum Corporation", "National Bank of Kuwait", "Zain Kuwait",
        "VIVA Telecom", "Kuwait Airways", "Al Ahli Bank",
        "Gulf Bank", "Boubyan Bank", "Kuwait Finance House",
        "Agility Logistics", "EQUATE Petrochemical"
    ]
    
    // MARK: - Generation
    
    /// Generates a complete set of demo data with random values
    static func generate() -> DemoData {
        let firstName = kuwaitiFirstNames.randomElement()!
        let lastName = kuwaitiLastNames.randomElement()!
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomSuffix = Int.random(in: 1000...9999)
        
        // Generate unique email with timestamp to avoid duplicates
        let email = "\(firstName.lowercased()).\(lastName.lowercased().replacingOccurrences(of: "-", with: "")).\(randomSuffix)@demo.forsa.app"
        
        // Generate a valid password
        let password = "Demo\(randomSuffix)Pass!"
        
        // Generate Kuwait mobile number (8 digits starting with 5, 6, or 9)
        let mobilePrefix = ["5", "6", "9"].randomElement()!
        let mobileNumber = mobilePrefix + String(format: "%07d", Int.random(in: 0...9999999))
        
        // Generate date of birth (25-55 years old)
        let yearsOld = Int.random(in: 25...55)
        let calendar = Calendar.current
        let dob = calendar.date(byAdding: .year, value: -yearsOld, to: Date())!
        
        // Generate Kuwait Civil ID (12 digits)
        // Format: CYYMMDDSSSSG
        // C = Century (2 for 1900s, 3 for 2000s)
        // YYMMDD = Date of birth
        // SSSS = Serial number
        // G = Gender (odd for male, even for female)
        let centuryDigit = yearsOld > 25 ? "2" : "3"
        let dobFormatter = DateFormatter()
        dobFormatter.dateFormat = "yyMMdd"
        let dobString = dobFormatter.string(from: dob)
        let serial = String(format: "%04d", Int.random(in: 0...9999))
        let genderDigit = Int.random(in: 0...9)
        let civilId = centuryDigit + dobString + serial + String(genderDigit)
        
        // Random area and matching governorate
        let area = kuwaitAreas.randomElement()!
        let governorate = kuwaitGovernorates.randomElement()!
        
        // Address details
        let block = String(Int.random(in: 1...12))
        let street = "Street \(Int.random(in: 1...50))"
        let building = String(Int.random(in: 1...200))
        let floor: String? = Bool.random() ? String(Int.random(in: 1...20)) : nil
        let apt: String? = Bool.random() ? String(Int.random(in: 1...50)) : nil
        
        // Financial info
        let employmentStatus: EmploymentStatus = [.employed, .selfEmployed].randomElement()!
        let employer = employmentStatus == .employed ? companies.randomElement()! : "\(firstName) \(lastName)"
        let occupation = occupations.randomElement()!
        
        // Random financial ranges
        let incomes: [IncomeRange] = [.from50kTo100k, .from100kTo200k, .from200kTo500k]
        let netWorths: [NetWorthRange] = [.from100kTo250k, .from250kTo500k, .from500kTo1m]
        let liquidNetWorths: [LiquidNetWorthRange] = [.from50kTo100k, .from100kTo250k, .from250kTo500k]
        let experiences: [InvestmentExperience] = [.limited, .good, .extensive]
        
        // Funding sources (1-3 random sources)
        let allSources: [FundingSource] = [.employmentIncome, .savings, .investments, .businessIncome]
        let sourceCount = Int.random(in: 1...3)
        let fundingSources = Array(allSources.shuffled().prefix(sourceCount))
        
        // Trusted contact (generate different person)
        let trustedFirstName = kuwaitiFirstNames.filter { $0 != firstName }.randomElement()!
        let trustedLastName = kuwaitiLastNames.randomElement()!
        let trustedMobilePrefix = ["5", "6", "9"].randomElement()!
        let trustedMobile = trustedMobilePrefix + String(format: "%07d", Int.random(in: 0...9999999))
        
        return DemoData(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phoneNumber: mobileNumber,
            dateOfBirth: dob,
            citizenship: "KWT",
            countryOfBirth: "KWT",
            country: "KWT",
            area: area,
            governorate: governorate,
            block: block,
            streetAddress: street,
            building: building,
            floor: floor,
            apartmentUnit: apt,
            taxId: civilId,
            taxIdType: .kuwaitCivilId,
            countryOfTaxResidence: "KWT",
            fundingSources: fundingSources,
            employmentStatus: employmentStatus,
            employer: employer,
            occupation: occupation,
            annualIncome: incomes.randomElement()!,
            netWorth: netWorths.randomElement()!,
            liquidNetWorth: liquidNetWorths.randomElement()!,
            investmentExperience: experiences.randomElement()!,
            trustedContactName: "\(trustedFirstName) \(trustedLastName)",
            trustedContactEmail: "\(trustedFirstName.lowercased())@family.com",
            trustedContactPhone: trustedMobile
        )
    }
}
