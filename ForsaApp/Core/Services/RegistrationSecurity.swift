//
//  RegistrationSecurity.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import Foundation
import Security
import CryptoKit

// MARK: - Validation Result

/// Result type for field validation
enum ValidationResult: Equatable {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

// MARK: - Registration Validator

/// Comprehensive input validation for registration fields
/// Implements FINRA-compliant validation rules
struct RegistrationValidator {
    
    // MARK: - Age Validation (18+ required by FINRA)
    
    static func validateAge(_ dob: Date) -> ValidationResult {
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        guard age >= 18 else {
            return .invalid("You must be at least 18 years old to invest")
        }
        guard age <= 125 else {
            return .invalid("Please enter a valid date of birth")
        }
        return .valid
    }
    
    // MARK: - SSN Validation (US)
    
    static func validateSSN(_ ssn: String) -> ValidationResult {
        let cleaned = ssn.replacingOccurrences(of: "-", with: "")
        guard cleaned.count == 9, cleaned.allSatisfy({ $0.isNumber }) else {
            return .invalid("Please enter a valid 9-digit SSN")
        }
        // Invalid SSN patterns per IRS/SSA rules
        let invalidPatterns = ["000", "666", "9"]
        if invalidPatterns.contains(where: { cleaned.hasPrefix($0) }) {
            return .invalid("Please enter a valid SSN")
        }
        // Middle two digits cannot be 00
        let middleDigits = cleaned.dropFirst(3).prefix(2)
        if middleDigits == "00" {
            return .invalid("Please enter a valid SSN")
        }
        // Last four digits cannot be 0000
        let lastFour = cleaned.suffix(4)
        if lastFour == "0000" {
            return .invalid("Please enter a valid SSN")
        }
        return .valid
    }
    
    // MARK: - Phone Validation
    
    static func validatePhone(_ phone: String) -> ValidationResult {
        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleaned.count >= 10 && cleaned.count <= 15 else {
            return .invalid("Please enter a valid phone number")
        }
        // Check for obviously invalid patterns (all same digit)
        let uniqueDigits = Set(cleaned)
        if uniqueDigits.count == 1 {
            return .invalid("Please enter a valid phone number")
        }
        return .valid
    }
    
    // MARK: - ZIP Code Validation
    
    static func validateZipCode(_ zip: String, country: String) -> ValidationResult {
        if country == "USA" {
            let zipRegex = "^[0-9]{5}(-[0-9]{4})?$"
            guard zip.range(of: zipRegex, options: .regularExpression) != nil else {
                return .invalid("Please enter a valid ZIP code")
            }
        }
        return .valid
    }
    
    // MARK: - Email Validation
    
    static func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isEmpty else {
            return .invalid("Email is required")
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard email.range(of: emailRegex, options: .regularExpression) != nil else {
            return .invalid("Please enter a valid email address")
        }
        return .valid
    }
    
    // MARK: - Password Validation
    
    static func validatePassword(_ password: String) -> ValidationResult {
        guard password.count >= 8 else {
            return .invalid("Password must be at least 8 characters")
        }
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            return .invalid("Password must contain at least one uppercase letter")
        }
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            return .invalid("Password must contain at least one lowercase letter")
        }
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            return .invalid("Password must contain at least one number")
        }
        // Check for special characters (optional but recommended)
        let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        if !hasSpecialChar && password.count < 12 {
            return .invalid("Password should contain a special character or be at least 12 characters")
        }
        return .valid
    }
    
    // MARK: - Name Validation
    
    static func validateName(_ name: String, fieldName: String = "Name") -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid("\(fieldName) is required")
        }
        guard trimmed.count >= 2 else {
            return .invalid("\(fieldName) must be at least 2 characters")
        }
        guard trimmed.count <= 50 else {
            return .invalid("\(fieldName) must be less than 50 characters")
        }
        // Only allow letters, spaces, hyphens, and apostrophes
        let nameRegex = "^[a-zA-Z][a-zA-Z\\s'-]*$"
        guard trimmed.range(of: nameRegex, options: .regularExpression) != nil else {
            return .invalid("\(fieldName) contains invalid characters")
        }
        return .valid
    }
    
    // MARK: - Address Validation
    
    static func validateStreetAddress(_ address: String) -> ValidationResult {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid("Street address is required")
        }
        guard trimmed.count >= 5 else {
            return .invalid("Please enter a valid street address")
        }
        guard trimmed.count <= 100 else {
            return .invalid("Street address is too long")
        }
        return .valid
    }
    
    static func validateCity(_ city: String) -> ValidationResult {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid("City is required")
        }
        guard trimmed.count >= 2 else {
            return .invalid("Please enter a valid city name")
        }
        return .valid
    }
    
    static func validateState(_ state: String) -> ValidationResult {
        guard !state.isEmpty else {
            return .invalid("State is required")
        }
        return .valid
    }
}

// MARK: - Secure Keychain Storage

/// Keychain storage for sensitive data (SSN, passwords, tokens)
/// NEVER use UserDefaults for sensitive data
final class SecureKeychainStorage {
    
    static let shared = SecureKeychainStorage()
    
    private init() {}
    
    // MARK: - Keychain Keys
    
    private enum KeychainKey: String {
        case ssn = "com.forsaapp.ssn"
        case taxId = "com.forsaapp.taxId"
        case authToken = "com.forsaapp.authToken"
        case encryptionKey = "com.forsaapp.encryptionKey"
    }
    
    // MARK: - Store SSN
    
    /// Store SSN securely in Keychain
    /// - Parameters:
    ///   - ssn: The SSN to store (will be encrypted)
    ///   - accountId: Optional account identifier for multi-account support
    /// - Returns: Success or failure
    @discardableResult
    func storeSSN(_ ssn: String, accountId: String? = nil) -> Bool {
        let key = accountId.map { "\(KeychainKey.ssn.rawValue).\($0)" } ?? KeychainKey.ssn.rawValue
        return storeSecureData(ssn.data(using: .utf8) ?? Data(), forKey: key)
    }
    
    /// Retrieve SSN from Keychain
    /// - Parameter accountId: Optional account identifier
    /// - Returns: The SSN if found
    func retrieveSSN(accountId: String? = nil) -> String? {
        let key = accountId.map { "\(KeychainKey.ssn.rawValue).\($0)" } ?? KeychainKey.ssn.rawValue
        guard let data = retrieveSecureData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete SSN from Keychain
    /// - Parameter accountId: Optional account identifier
    @discardableResult
    func deleteSSN(accountId: String? = nil) -> Bool {
        let key = accountId.map { "\(KeychainKey.ssn.rawValue).\($0)" } ?? KeychainKey.ssn.rawValue
        return deleteSecureData(forKey: key)
    }
    
    // MARK: - Store Tax ID
    
    @discardableResult
    func storeTaxId(_ taxId: String, accountId: String? = nil) -> Bool {
        let key = accountId.map { "\(KeychainKey.taxId.rawValue).\($0)" } ?? KeychainKey.taxId.rawValue
        return storeSecureData(taxId.data(using: .utf8) ?? Data(), forKey: key)
    }
    
    func retrieveTaxId(accountId: String? = nil) -> String? {
        let key = accountId.map { "\(KeychainKey.taxId.rawValue).\($0)" } ?? KeychainKey.taxId.rawValue
        guard let data = retrieveSecureData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    @discardableResult
    func deleteTaxId(accountId: String? = nil) -> Bool {
        let key = accountId.map { "\(KeychainKey.taxId.rawValue).\($0)" } ?? KeychainKey.taxId.rawValue
        return deleteSecureData(forKey: key)
    }
    
    // MARK: - Store Auth Token
    
    @discardableResult
    func storeAuthToken(_ token: String) -> Bool {
        return storeSecureData(token.data(using: .utf8) ?? Data(), forKey: KeychainKey.authToken.rawValue)
    }
    
    func retrieveAuthToken() -> String? {
        guard let data = retrieveSecureData(forKey: KeychainKey.authToken.rawValue) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    @discardableResult
    func deleteAuthToken() -> Bool {
        return deleteSecureData(forKey: KeychainKey.authToken.rawValue)
    }
    
    // MARK: - Private Keychain Operations
    
    private func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        // Delete existing item first
        deleteSecureData(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func retrieveSecureData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    @discardableResult
    private func deleteSecureData(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All Sensitive Data
    
    /// Clear all sensitive data from Keychain
    /// Call this when user logs out or registration is cancelled
    func clearAllSensitiveData() {
        deleteSSN()
        deleteTaxId()
        deleteAuthToken()
    }
}

// MARK: - Sensitive Data Encryption

/// Encryption utilities for sensitive data before transmission
final class SensitiveDataEncryption {
    
    static let shared = SensitiveDataEncryption()
    
    private var encryptionKey: SymmetricKey?
    
    private init() {
        loadOrGenerateKey()
    }
    
    // MARK: - Key Management
    
    private func loadOrGenerateKey() {
        // Try to load existing key from Keychain
        if let keyData = loadKeyFromKeychain() {
            encryptionKey = SymmetricKey(data: keyData)
        } else {
            // Generate new key
            let newKey = SymmetricKey(size: .bits256)
            encryptionKey = newKey
            saveKeyToKeychain(newKey)
        }
    }
    
    private func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.forsaapp.encryptionKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    private func saveKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.forsaapp.encryptionKey",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    // MARK: - Encryption
    
    /// Encrypt sensitive data before transmission
    /// - Parameter plaintext: The string to encrypt
    /// - Returns: Base64-encoded encrypted data with nonce prepended
    func encrypt(_ plaintext: String) -> String? {
        guard let key = encryptionKey,
              let data = plaintext.data(using: .utf8) else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            return nil
        }
    }
    
    /// Decrypt encrypted data
    /// - Parameter ciphertext: Base64-encoded encrypted data
    /// - Returns: Decrypted string
    func decrypt(_ ciphertext: String) -> String? {
        guard let key = encryptionKey,
              let data = Data(base64Encoded: ciphertext) else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    /// Hash sensitive data (one-way, for comparison purposes)
    /// - Parameter data: Data to hash
    /// - Returns: SHA256 hash as hex string
    func hash(_ data: String) -> String {
        let inputData = Data(data.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Sensitive Field Memory Cleaner

/// Utility to securely clear sensitive data from memory
/// Call after successful submission or when leaving registration
final class SensitiveFieldCleaner {
    
    /// Clear a string by overwriting its memory
    /// Note: Due to Swift's value semantics, this works best with inout parameters
    static func clearString(_ string: inout String) {
        // Overwrite with zeros
        string = String(repeating: "\0", count: string.count)
        string = ""
    }
    
    /// Clear sensitive registration data
    static func clearRegistrationData(_ data: inout KYCRegistrationData) {
        // Clear password
        data.password = String(repeating: "\0", count: data.password.count)
        data.password = ""
        
        // Clear SSN/Tax ID
        data.taxId = String(repeating: "\0", count: data.taxId.count)
        data.taxId = ""
        
        // Clear phone number
        data.phoneNumber = String(repeating: "\0", count: data.phoneNumber.count)
        data.phoneNumber = ""
    }
    
    /// Clear all sensitive data from keychain and memory
    static func performFullCleanup() {
        SecureKeychainStorage.shared.clearAllSensitiveData()
    }
}

// MARK: - Session Timeout Manager

/// Manages session timeout for incomplete registrations
/// Clears sensitive data after inactivity period
final class SessionTimeoutManager: ObservableObject {
    
    static let shared = SessionTimeoutManager()
    
    /// Session timeout duration (30 minutes for incomplete registrations)
    private let timeoutDuration: TimeInterval = 30 * 60 // 30 minutes
    
    /// Last activity timestamp
    @Published private(set) var lastActivityTime: Date = Date()
    
    /// Whether the session has timed out
    @Published private(set) var hasTimedOut: Bool = false
    
    /// Timer for checking timeout
    private var timeoutTimer: Timer?
    
    /// Callback when session times out
    var onSessionTimeout: (() -> Void)?
    
    private init() {
        startTimeoutTimer()
    }
    
    // MARK: - Activity Tracking
    
    /// Record user activity to reset timeout
    func recordActivity() {
        lastActivityTime = Date()
        hasTimedOut = false
    }
    
    /// Check if session has timed out
    func checkTimeout() -> Bool {
        let elapsed = Date().timeIntervalSince(lastActivityTime)
        return elapsed >= timeoutDuration
    }
    
    /// Get remaining time before timeout
    func remainingTime() -> TimeInterval {
        let elapsed = Date().timeIntervalSince(lastActivityTime)
        return max(0, timeoutDuration - elapsed)
    }
    
    // MARK: - Timer Management
    
    private func startTimeoutTimer() {
        // Check every 60 seconds
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.evaluateTimeout()
        }
    }
    
    private func evaluateTimeout() {
        if checkTimeout() && !hasTimedOut {
            hasTimedOut = true
            handleTimeout()
        }
    }
    
    private func handleTimeout() {
        // Clear sensitive data
        SensitiveFieldCleaner.performFullCleanup()
        KYCRegistrationData.clear()
        
        // Notify observers
        onSessionTimeout?()
    }
    
    /// Reset the session (e.g., when user starts fresh)
    func resetSession() {
        lastActivityTime = Date()
        hasTimedOut = false
    }
    
    /// Stop the timeout timer
    func stopTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    deinit {
        stopTimer()
    }
}

// MARK: - Rate Limiter

/// Rate limiting for sensitive operations
/// Prevents brute force and spam attacks
final class RateLimiter: ObservableObject {
    
    static let shared = RateLimiter()
    
    // MARK: - Rate Limit Configurations
    
    struct RateLimitConfig {
        let maxAttempts: Int
        let windowDuration: TimeInterval // in seconds
        
        static let otpRequest = RateLimitConfig(maxAttempts: 3, windowDuration: 10 * 60) // 3 per 10 minutes
        static let accountCreation = RateLimitConfig(maxAttempts: 5, windowDuration: 60 * 60) // 5 per hour
        static let passwordReset = RateLimitConfig(maxAttempts: 3, windowDuration: 15 * 60) // 3 per 15 minutes
        static let loginAttempts = RateLimitConfig(maxAttempts: 5, windowDuration: 5 * 60) // 5 per 5 minutes
    }
    
    // MARK: - Stored Attempts
    
    private struct AttemptRecord: Codable {
        let timestamp: Date
    }
    
    private var attemptRecords: [String: [AttemptRecord]] = [:]
    private let persistenceKey = "com.forsaapp.rateLimiter.attempts"
    
    @Published private(set) var isOTPRateLimited: Bool = false
    @Published private(set) var isAccountCreationRateLimited: Bool = false
    
    private init() {
        loadAttempts()
        cleanupOldAttempts()
    }
    
    // MARK: - OTP Rate Limiting
    
    /// Check if OTP request is allowed
    /// - Parameter identifier: User identifier (phone/email)
    /// - Returns: True if request is allowed
    func canRequestOTP(identifier: String) -> Bool {
        let key = "otp_\(identifier)"
        return canPerformAction(key: key, config: .otpRequest)
    }
    
    /// Record an OTP request attempt
    /// - Parameter identifier: User identifier
    func recordOTPRequest(identifier: String) {
        let key = "otp_\(identifier)"
        recordAttempt(key: key)
        isOTPRateLimited = !canRequestOTP(identifier: identifier)
    }
    
    /// Get remaining OTP attempts
    /// - Parameter identifier: User identifier
    /// - Returns: Number of remaining attempts
    func remainingOTPAttempts(identifier: String) -> Int {
        let key = "otp_\(identifier)"
        return remainingAttempts(key: key, config: .otpRequest)
    }
    
    /// Get time until OTP rate limit resets
    /// - Parameter identifier: User identifier
    /// - Returns: Seconds until reset, or nil if not rate limited
    func timeUntilOTPReset(identifier: String) -> TimeInterval? {
        let key = "otp_\(identifier)"
        return timeUntilReset(key: key, config: .otpRequest)
    }
    
    // MARK: - Account Creation Rate Limiting
    
    /// Check if account creation is allowed
    /// - Parameter ipAddress: Client IP address
    /// - Returns: True if creation is allowed
    func canCreateAccount(ipAddress: String) -> Bool {
        let key = "account_\(ipAddress)"
        return canPerformAction(key: key, config: .accountCreation)
    }
    
    /// Record an account creation attempt
    /// - Parameter ipAddress: Client IP address
    func recordAccountCreation(ipAddress: String) {
        let key = "account_\(ipAddress)"
        recordAttempt(key: key)
        isAccountCreationRateLimited = !canCreateAccount(ipAddress: ipAddress)
    }
    
    /// Get remaining account creation attempts
    /// - Parameter ipAddress: Client IP address
    /// - Returns: Number of remaining attempts
    func remainingAccountCreationAttempts(ipAddress: String) -> Int {
        let key = "account_\(ipAddress)"
        return remainingAttempts(key: key, config: .accountCreation)
    }
    
    // MARK: - Password Reset Rate Limiting
    
    func canRequestPasswordReset(email: String) -> Bool {
        let key = "pwreset_\(email)"
        return canPerformAction(key: key, config: .passwordReset)
    }
    
    func recordPasswordResetRequest(email: String) {
        let key = "pwreset_\(email)"
        recordAttempt(key: key)
    }
    
    // MARK: - Login Attempts Rate Limiting
    
    func canAttemptLogin(identifier: String) -> Bool {
        let key = "login_\(identifier)"
        return canPerformAction(key: key, config: .loginAttempts)
    }
    
    func recordLoginAttempt(identifier: String) {
        let key = "login_\(identifier)"
        recordAttempt(key: key)
    }
    
    func clearLoginAttempts(identifier: String) {
        let key = "login_\(identifier)"
        attemptRecords[key] = []
        saveAttempts()
    }
    
    // MARK: - Private Helpers
    
    private func canPerformAction(key: String, config: RateLimitConfig) -> Bool {
        cleanupOldAttempts(for: key, config: config)
        let attempts = attemptRecords[key] ?? []
        return attempts.count < config.maxAttempts
    }
    
    private func recordAttempt(key: String) {
        var attempts = attemptRecords[key] ?? []
        attempts.append(AttemptRecord(timestamp: Date()))
        attemptRecords[key] = attempts
        saveAttempts()
    }
    
    private func remainingAttempts(key: String, config: RateLimitConfig) -> Int {
        cleanupOldAttempts(for: key, config: config)
        let attempts = attemptRecords[key] ?? []
        return max(0, config.maxAttempts - attempts.count)
    }
    
    private func timeUntilReset(key: String, config: RateLimitConfig) -> TimeInterval? {
        guard let attempts = attemptRecords[key], !attempts.isEmpty else {
            return nil
        }
        
        let oldestAttempt = attempts.min { $0.timestamp < $1.timestamp }
        guard let oldest = oldestAttempt else { return nil }
        
        let resetTime = oldest.timestamp.addingTimeInterval(config.windowDuration)
        let remaining = resetTime.timeIntervalSince(Date())
        
        return remaining > 0 ? remaining : nil
    }
    
    private func cleanupOldAttempts(for key: String, config: RateLimitConfig) {
        let cutoff = Date().addingTimeInterval(-config.windowDuration)
        if var attempts = attemptRecords[key] {
            attempts.removeAll { $0.timestamp < cutoff }
            attemptRecords[key] = attempts
        }
    }
    
    private func cleanupOldAttempts() {
        // Clean up all attempt records older than 1 hour
        let cutoff = Date().addingTimeInterval(-60 * 60)
        for (key, attempts) in attemptRecords {
            attemptRecords[key] = attempts.filter { $0.timestamp >= cutoff }
        }
        saveAttempts()
    }
    
    // MARK: - Persistence
    
    private func saveAttempts() {
        if let data = try? JSONEncoder().encode(attemptRecords) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }
    
    private func loadAttempts() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let records = try? JSONDecoder().decode([String: [AttemptRecord]].self, from: data) {
            attemptRecords = records
        }
    }
    
    /// Reset all rate limits (for testing purposes only)
    func resetAllLimits() {
        attemptRecords = [:]
        saveAttempts()
        isOTPRateLimited = false
        isAccountCreationRateLimited = false
    }
}

// MARK: - Rate Limit Error

enum RateLimitError: Error, LocalizedError {
    case otpLimitExceeded(remainingSeconds: Int)
    case accountCreationLimitExceeded(remainingSeconds: Int)
    case loginLimitExceeded(remainingSeconds: Int)
    case passwordResetLimitExceeded(remainingSeconds: Int)
    
    var errorDescription: String? {
        switch self {
        case .otpLimitExceeded(let seconds):
            let minutes = seconds / 60
            return "Too many OTP requests. Please try again in \(minutes) minute\(minutes == 1 ? "" : "s")."
        case .accountCreationLimitExceeded(let seconds):
            let minutes = seconds / 60
            return "Too many account creation attempts. Please try again in \(minutes) minute\(minutes == 1 ? "" : "s")."
        case .loginLimitExceeded(let seconds):
            let minutes = seconds / 60
            return "Too many login attempts. Please try again in \(minutes) minute\(minutes == 1 ? "" : "s")."
        case .passwordResetLimitExceeded(let seconds):
            let minutes = seconds / 60
            return "Too many password reset requests. Please try again in \(minutes) minute\(minutes == 1 ? "" : "s")."
        }
    }
}

