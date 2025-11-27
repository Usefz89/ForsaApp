//
//  TwilioVerifyService.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//
//  Twilio Verify API integration for phone number OTP verification
//  Documentation: https://www.twilio.com/docs/verify/api
//

import Foundation
import Combine

// MARK: - Twilio Verify Service

/// Service for handling phone number verification using Twilio Verify API
/// Provides OTP sending and verification functionality with rate limiting
@MainActor
final class TwilioVerifyService: ObservableObject {
    
    static let shared = TwilioVerifyService()
    
    // MARK: - Published State
    
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: TwilioVerifyError?
    @Published private(set) var verificationSid: String?
    @Published private(set) var isVerified = false
    
    // MARK: - Attempt Tracking State
    
    /// Maximum verification attempts allowed by Twilio per session
    static let maxVerificationAttempts = 5
    
    /// Current number of verification attempts made in this session
    @Published private(set) var verificationAttempts: Int = 0
    
    /// Remaining verification attempts before session is locked
    @Published private(set) var remainingAttempts: Int = maxVerificationAttempts
    
    /// Whether max attempts have been reached and a new OTP is required
    @Published private(set) var maxAttemptsReached: Bool = false
    
    /// Phone number for the current verification session
    @Published private(set) var currentPhoneNumber: String?
    
    // MARK: - Configuration
    
    private var accountSid: String { AppConfig.Twilio.accountSid }
    private var authToken: String { AppConfig.Twilio.authToken }
    private var serviceSid: String { AppConfig.Twilio.verifyServiceSid }
    private var baseURL: String { "https://verify.twilio.com/v2" }
    
    private init() {}
    
    // MARK: - Send OTP
    
    /// Sends an OTP verification code to the specified phone number
    /// - Parameters:
    ///   - phoneNumber: Phone number in E.164 format (+1XXXXXXXXXX)
    ///   - channel: Delivery channel (sms or call)
    /// - Returns: Verification SID on success
    func sendOTP(to phoneNumber: String, channel: VerificationChannel = .sms) async throws -> String {
        // ========== DEVELOPMENT BYPASS MODE ==========
        // Skip real Twilio API calls to save credits during development
        if AppConfig.Twilio.useDevelopmentBypass {
            let formattedPhone = formatToE164(phoneNumber)
            
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🧪 DEVELOPMENT MODE - Twilio Bypass Active")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📱 Simulating OTP send to: \(maskPhoneNumber(formattedPhone))")
            print("🔑 Use code: \(AppConfig.Twilio.testOTPCode)")
            print("💰 No Twilio credits consumed!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // Simulate network delay for realistic UX
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Generate fake verification SID
            let fakeSid = "DEV_\(UUID().uuidString.prefix(20))"
            self.verificationSid = fakeSid
            
            // Reset attempt tracking for new session
            resetAttemptTracking()
            self.currentPhoneNumber = formattedPhone
            
            return fakeSid
        }
        // =============================================
        
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        // Format phone number to E.164
        let formattedPhone = formatToE164(phoneNumber)
        
        guard isValidE164(formattedPhone) else {
            let error = TwilioVerifyError.invalidPhoneNumber
            lastError = error
            throw error
        }
        
        // Build request
        let url = URL(string: "\(baseURL)/Services/\(serviceSid)/Verifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(createAuthHeader(), forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Request body
        let bodyParams = [
            "To": formattedPhone,
            "Channel": channel.rawValue
        ]
        request.httpBody = bodyParams.percentEncoded()
        
        print("📱 Sending OTP to: \(maskPhoneNumber(formattedPhone))")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TwilioVerifyError.networkError("Invalid response")
            }
            
            // Parse response
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if (200...299).contains(httpResponse.statusCode) {
                guard let sid = json?["sid"] as? String else {
                    throw TwilioVerifyError.invalidResponse
                }
                
                print("✅ OTP sent successfully. SID: \(sid.prefix(10))...")
                self.verificationSid = sid
                
                // Reset attempt tracking for new verification session
                resetAttemptTracking()
                self.currentPhoneNumber = formattedPhone
                
                return sid
                
            } else {
                // Handle error
                let errorCode = json?["code"] as? Int
                let errorMessage = json?["message"] as? String ?? "Unknown error"
                
                let error = mapTwilioError(code: errorCode, message: errorMessage, statusCode: httpResponse.statusCode)
                lastError = error
                throw error
            }
            
        } catch let error as TwilioVerifyError {
            throw error
        } catch {
            let twilioError = TwilioVerifyError.networkError(error.localizedDescription)
            lastError = twilioError
            throw twilioError
        }
    }
    
    // MARK: - Verify OTP
    
    /// Verifies the OTP code entered by the user
    /// - Parameters:
    ///   - phoneNumber: Phone number that received the OTP
    ///   - code: 6-digit OTP code
    /// - Returns: True if verification successful
    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool {
        // ========== DEVELOPMENT BYPASS MODE ==========
        // Skip real Twilio API calls to save credits during development
        if AppConfig.Twilio.useDevelopmentBypass {
            // Check if max attempts already reached
            guard !maxAttemptsReached else {
                let error = TwilioVerifyError.maxAttemptsReached
                lastError = error
                print("🧪 DEV MODE: Max attempts reached - request new code")
                throw error
            }
            
            let cleanCode = code.filter { $0.isNumber }
            
            print("🧪 DEV MODE: Verifying code '\(cleanCode)' (expected: '\(AppConfig.Twilio.testOTPCode)')")
            
            // Simulate network delay for realistic UX
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            if cleanCode == AppConfig.Twilio.testOTPCode {
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("✅ DEV MODE: Phone verified successfully!")
                print("💰 No Twilio credits consumed!")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                isVerified = true
                resetAttemptTracking()
                return true
            } else {
                // Simulate wrong code behavior - increment attempts
                incrementAttemptCount()
                
                if maxAttemptsReached {
                    let error = TwilioVerifyError.maxAttemptsReached
                    lastError = error
                    print("❌ DEV MODE: Max attempts reached - must request new code")
                    throw error
                }
                
                let error = TwilioVerifyError.incorrectCode
                lastError = error
                print("⚠️ DEV MODE: Incorrect code. \(remainingAttempts) attempts remaining.")
                print("💡 Hint: Use code '\(AppConfig.Twilio.testOTPCode)'")
                throw error
            }
        }
        // =============================================
        
        // Check if max attempts already reached before making API call
        guard !maxAttemptsReached else {
            let error = TwilioVerifyError.maxAttemptsReached
            lastError = error
            throw error
        }
        
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        // Validate code format
        let cleanCode = code.filter { $0.isNumber }
        guard cleanCode.count == 6 else {
            let error = TwilioVerifyError.invalidCode
            lastError = error
            throw error
        }
        
        // Format phone number
        let formattedPhone = formatToE164(phoneNumber)
        
        // Build request
        let url = URL(string: "\(baseURL)/Services/\(serviceSid)/VerificationCheck")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(createAuthHeader(), forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Request body
        let bodyParams = [
            "To": formattedPhone,
            "Code": cleanCode
        ]
        request.httpBody = bodyParams.percentEncoded()
        
        print("🔐 Verifying OTP for: \(maskPhoneNumber(formattedPhone)) (Attempt \(verificationAttempts + 1)/\(Self.maxVerificationAttempts))")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TwilioVerifyError.networkError("Invalid response")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if (200...299).contains(httpResponse.statusCode) {
                let status = json?["status"] as? String
                
                if status == "approved" {
                    print("✅ Phone number verified successfully!")
                    isVerified = true
                    // Reset on success
                    resetAttemptTracking()
                    return true
                    
                } else if status == "pending" {
                    // Code was incorrect - increment attempt counter
                    incrementAttemptCount()
                    
                    // Check if this was the last attempt
                    if maxAttemptsReached {
                        let error = TwilioVerifyError.maxAttemptsReached
                        lastError = error
                        print("❌ Max verification attempts reached. User must request new code.")
                        throw error
                    }
                    
                    let error = TwilioVerifyError.incorrectCode
                    lastError = error
                    print("⚠️ Incorrect code. \(remainingAttempts) attempts remaining.")
                    throw error
                    
                } else {
                    // Verification failed or expired
                    let error = TwilioVerifyError.verificationFailed(status ?? "unknown")
                    lastError = error
                    throw error
                }
                
            } else {
                let errorCode = json?["code"] as? Int
                let errorMessage = json?["message"] as? String ?? "Verification failed"
                
                // Check for max attempts error from Twilio (60203)
                if errorCode == 60203 {
                    handleMaxAttemptsReached()
                }
                
                let error = mapTwilioError(code: errorCode, message: errorMessage, statusCode: httpResponse.statusCode)
                lastError = error
                throw error
            }
            
        } catch let error as TwilioVerifyError {
            throw error
        } catch {
            let twilioError = TwilioVerifyError.networkError(error.localizedDescription)
            lastError = twilioError
            throw twilioError
        }
    }
    
    // MARK: - Attempt Tracking Methods
    
    /// Resets the verification attempt tracking for a new session
    private func resetAttemptTracking() {
        verificationAttempts = 0
        remainingAttempts = Self.maxVerificationAttempts
        maxAttemptsReached = false
        print("🔄 Verification attempt counter reset")
    }
    
    /// Increments the attempt counter and updates remaining attempts
    private func incrementAttemptCount() {
        verificationAttempts += 1
        remainingAttempts = max(0, Self.maxVerificationAttempts - verificationAttempts)
        
        if verificationAttempts >= Self.maxVerificationAttempts {
            maxAttemptsReached = true
        }
    }
    
    /// Handles when Twilio reports max attempts reached (code 60203)
    private func handleMaxAttemptsReached() {
        verificationAttempts = Self.maxVerificationAttempts
        remainingAttempts = 0
        maxAttemptsReached = true
        print("🚫 Twilio reported max verification attempts reached")
    }
    
    /// Returns formatted string of remaining attempts for UI display
    var attemptsRemainingText: String {
        if maxAttemptsReached {
            return "No attempts remaining. Please request a new code."
        }
        return "\(remainingAttempts) attempt\(remainingAttempts == 1 ? "" : "s") remaining"
    }
    
    /// Returns true if user should be warned they're running low on attempts
    var isRunningLowOnAttempts: Bool {
        remainingAttempts <= 2 && remainingAttempts > 0
    }
    
    // MARK: - Retry Methods
    
    /// Sends OTP with automatic retry for transient network failures
    /// Uses exponential backoff between retries
    /// - Parameters:
    ///   - phoneNumber: Phone number in E.164 format
    ///   - channel: Delivery channel (sms or call)
    ///   - maxAttempts: Maximum number of attempts (default: 3)
    /// - Returns: Verification SID on success
    func sendOTPWithRetry(
        to phoneNumber: String,
        channel: VerificationChannel = .sms,
        maxAttempts: Int = 3
    ) async throws -> String {
        var lastError: TwilioVerifyError?
        
        for attempt in 1...maxAttempts {
            do {
                let sid = try await sendOTP(to: phoneNumber, channel: channel)
                return sid
                
            } catch let error as TwilioVerifyError {
                lastError = error
                print("⚠️ OTP send attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Don't retry certain errors
                guard error.isRetryable else {
                    throw error
                }
                
                // Wait before retrying with exponential backoff
                if attempt < maxAttempts {
                    let delaySeconds = pow(2.0, Double(attempt))
                    print("   Retrying in \(Int(delaySeconds)) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? TwilioVerifyError.unknownError("Failed after \(maxAttempts) attempts")
    }
    
    /// Verifies OTP with automatic retry for transient network failures
    /// - Parameters:
    ///   - phoneNumber: Phone number that received the OTP
    ///   - code: 6-digit verification code
    ///   - maxAttempts: Maximum number of attempts (default: 2 - fewer since incorrect codes use up attempts)
    /// - Returns: True if verification successful
    func verifyOTPWithRetry(
        phoneNumber: String,
        code: String,
        maxAttempts: Int = 2
    ) async throws -> Bool {
        var lastError: TwilioVerifyError?
        
        for attempt in 1...maxAttempts {
            do {
                let success = try await verifyOTP(phoneNumber: phoneNumber, code: code)
                return success
                
            } catch let error as TwilioVerifyError {
                lastError = error
                print("⚠️ OTP verify attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Don't retry certain errors - incorrect code should not be retried automatically
                guard error.isNetworkRetryable else {
                    throw error
                }
                
                // Wait before retrying
                if attempt < maxAttempts {
                    let delaySeconds = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? TwilioVerifyError.unknownError("Verification failed after \(maxAttempts) attempts")
    }
    
    // MARK: - Cancel Verification
    
    /// Cancels an ongoing verification (optional cleanup)
    func cancelVerification() {
        verificationSid = nil
        isVerified = false
        lastError = nil
    }
    
    // MARK: - Reset State
    
    /// Resets the service state for a new verification
    func reset() {
        verificationSid = nil
        isVerified = false
        lastError = nil
        isLoading = false
        currentPhoneNumber = nil
        
        // Reset attempt tracking
        resetAttemptTracking()
    }
    
    // MARK: - Private Helpers
    
    /// Creates Basic Auth header for Twilio API
    private func createAuthHeader() -> String {
        let credentials = "\(accountSid):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
    
    /// Formats phone number to E.164 format
    /// Supports Kuwait (+965) as default, with fallback for US numbers
    private func formatToE164(_ phone: String, defaultCountry: String = "KWT") -> String {
        var cleaned = phone.trimmingCharacters(in: .whitespaces)
        
        // If already has + prefix, validate and return
        if cleaned.hasPrefix("+") {
            let digits = String(cleaned.dropFirst().filter { $0.isNumber })
            return "+\(digits)"
        }
        
        // Remove all non-digits
        let digits = cleaned.filter { $0.isNumber }
        let digitString = String(digits)
        
        // Handle based on default country
        switch defaultCountry {
        case "KWT":
            // Kuwait: 8 digits, country code +965
            if digitString.count == 8 {
                return "+965\(digitString)"
            }
            // Already includes country code
            if digitString.count == 11 && digitString.hasPrefix("965") {
                return "+\(digitString)"
            }
            
        case "USA":
            // US: 10 digits, country code +1
            if digitString.count == 10 {
                return "+1\(digitString)"
            }
            // Already includes country code
            if digitString.count == 11 && digitString.hasPrefix("1") {
                return "+\(digitString)"
            }
            
        case "SAU":
            // Saudi Arabia: 9 digits (without 0), country code +966
            if digitString.count == 9 && digitString.hasPrefix("5") {
                return "+966\(digitString)"
            }
            if digitString.count == 10 && digitString.hasPrefix("05") {
                return "+966\(digitString.dropFirst())"
            }
            
        case "ARE":
            // UAE: 9 digits, country code +971
            if digitString.count == 9 && digitString.hasPrefix("5") {
                return "+971\(digitString)"
            }
            
        case "QAT":
            // Qatar: 8 digits, country code +974
            if digitString.count == 8 {
                return "+974\(digitString)"
            }
            
        default:
            break
        }
        
        // Fallback: if digits look like they include a known country code
        if digitString.hasPrefix("965") && digitString.count == 11 {
            return "+\(digitString)" // Kuwait with country code
        }
        if digitString.hasPrefix("1") && digitString.count == 11 {
            return "+\(digitString)" // US with country code
        }
        
        // Default: assume Kuwait for 8 digits, otherwise add + prefix
        if digitString.count == 8 {
            return "+965\(digitString)"
        }
        
        return "+\(digitString)"
    }
    
    /// Validates E.164 phone number format
    private func isValidE164(_ phone: String) -> Bool {
        // E.164: + followed by 1-15 digits
        let regex = "^\\+[1-9]\\d{1,14}$"
        return phone.range(of: regex, options: .regularExpression) != nil
    }
    
    /// Masks phone number for logging
    private func maskPhoneNumber(_ phone: String) -> String {
        guard phone.count > 6 else { return "***" }
        let prefix = phone.prefix(4)
        let suffix = phone.suffix(2)
        let masked = String(repeating: "*", count: phone.count - 6)
        return "\(prefix)\(masked)\(suffix)"
    }
    
    /// Maps Twilio error codes to local error types
    private func mapTwilioError(code: Int?, message: String, statusCode: Int) -> TwilioVerifyError {
        // Twilio Verify specific error codes
        // Reference: https://www.twilio.com/docs/verify/api/verification-check#check-a-verification-errors
        switch code {
        // General errors
        case 20404:
            return .verificationNotFound
        case 20429:
            return .rateLimitExceeded
            
        // Verification errors (60xxx)
        case 60200:
            return .invalidPhoneNumber
        case 60202:
            // Max SEND attempts reached - can't send more OTPs to this number
            return .maxSendAttemptsReached
        case 60203:
            // Max CHECK attempts reached - too many wrong codes entered
            // User must request a new verification code
            handleMaxAttemptsReached()
            return .maxAttemptsReached
        case 60212:
            // Too many concurrent requests for this phone number
            return .rateLimitExceeded
        case 60223:
            // Verification expired
            return .verificationExpired
        case 60410:
            // Verification delivery attempt blocked (carrier/spam filter)
            return .deliveryBlocked
            
        default:
            break
        }
        
        // HTTP status based errors
        switch statusCode {
        case 401:
            return .authenticationFailed
        case 403:
            return .permissionDenied
        case 429:
            return .rateLimitExceeded
        case 500...599:
            return .serverError
        default:
            return .unknownError(message)
        }
    }
}

// MARK: - Verification Channel

/// Channel for sending verification code
enum VerificationChannel: String {
    case sms = "sms"
    case call = "call"
    case email = "email"
    case whatsapp = "whatsapp"
    
    var displayName: String {
        switch self {
        case .sms: return "SMS"
        case .call: return "Voice Call"
        case .email: return "Email"
        case .whatsapp: return "WhatsApp"
        }
    }
    
    var icon: String {
        switch self {
        case .sms: return "message.fill"
        case .call: return "phone.fill"
        case .email: return "envelope.fill"
        case .whatsapp: return "text.bubble.fill"
        }
    }
}

// MARK: - Twilio Verify Error

/// Errors that can occur during phone verification
enum TwilioVerifyError: Error, LocalizedError, Equatable {
    case invalidPhoneNumber
    case invalidCode
    case incorrectCode
    case verificationNotFound
    case verificationExpired
    case verificationFailed(String)
    case maxAttemptsReached          // Too many wrong codes - must request new OTP
    case maxSendAttemptsReached      // Too many OTP requests to this number
    case rateLimitExceeded
    case authenticationFailed
    case permissionDenied
    case serverError
    case networkError(String)
    case invalidResponse
    case deliveryBlocked             // Carrier/spam filter blocked delivery
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .invalidCode:
            return "Please enter a 6-digit verification code"
        case .incorrectCode:
            return "Incorrect code. Please try again."
        case .verificationNotFound:
            return "Verification session not found. Please request a new code."
        case .verificationExpired:
            return "Verification code has expired. Please request a new one."
        case .verificationFailed(let status):
            return "Verification failed: \(status)"
        case .maxAttemptsReached:
            return "Too many incorrect attempts. Please request a new code."
        case .maxSendAttemptsReached:
            return "Too many code requests. Please wait before trying again."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
        case .authenticationFailed:
            return "Service configuration error. Please contact support."
        case .permissionDenied:
            return "Service access denied. Please contact support."
        case .serverError:
            return "Server error. Please try again later."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from verification service"
        case .deliveryBlocked:
            return "Verification code could not be delivered. Your carrier may have blocked it. Please try a different phone number or use voice call instead."
        case .unknownError(let message):
            return message
        }
    }
    
    /// Whether the user should request a new OTP
    var shouldRequestNewCode: Bool {
        switch self {
        case .verificationNotFound, .verificationExpired, .maxAttemptsReached:
            return true
        default:
            return false
        }
    }
    
    /// Number of remaining attempts, if known from the error
    /// Returns nil if not applicable
    var remainingAttemptsFromError: Int? {
        switch self {
        case .maxAttemptsReached:
            return 0
        default:
            return nil
        }
    }
    
    /// Whether this error can be retried (including user input errors)
    var isRetryable: Bool {
        switch self {
        case .incorrectCode, .invalidCode:
            return true  // User can try entering a different code
        case .serverError, .networkError, .rateLimitExceeded:
            return true  // Transient errors that may resolve
        default:
            return false
        }
    }
    
    /// Whether this error is specifically a network/server issue that should be auto-retried
    /// (Does NOT include incorrect code - we don't want to auto-retry wrong codes)
    var isNetworkRetryable: Bool {
        switch self {
        case .serverError, .networkError:
            return true
        default:
            return false
        }
    }
    
    /// Suggested wait time before retrying (in seconds)
    var suggestedRetryDelay: TimeInterval {
        switch self {
        case .rateLimitExceeded:
            return 60  // Wait 1 minute for rate limits
        case .serverError:
            return 5   // Wait 5 seconds for server errors
        case .networkError:
            return 2   // Wait 2 seconds for network issues
        default:
            return 0
        }
    }
}

// MARK: - Dictionary Extension for URL Encoding

extension Dictionary where Key == String, Value == String {
    /// Encodes dictionary as percent-encoded form data
    func percentEncoded() -> Data? {
        let pairs = self.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }
        return pairs.joined(separator: "&").data(using: .utf8)
    }
}

extension CharacterSet {
    /// Characters allowed in URL query values (stricter than urlQueryAllowed)
    static let urlQueryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        return allowed
    }()
}

// MARK: - Verification Result

/// Result of a verification attempt
struct VerificationResult {
    let success: Bool
    let phoneNumber: String
    let verifiedAt: Date?
    let error: TwilioVerifyError?
    
    static func success(phoneNumber: String) -> VerificationResult {
        VerificationResult(
            success: true,
            phoneNumber: phoneNumber,
            verifiedAt: Date(),
            error: nil
        )
    }
    
    static func failure(phoneNumber: String, error: TwilioVerifyError) -> VerificationResult {
        VerificationResult(
            success: false,
            phoneNumber: phoneNumber,
            verifiedAt: nil,
            error: error
        )
    }
}

