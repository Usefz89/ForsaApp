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
        
        print("🔐 Verifying OTP for: \(maskPhoneNumber(formattedPhone))")
        
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
                    return true
                } else if status == "pending" {
                    // Code was incorrect but verification is still active
                    let error = TwilioVerifyError.incorrectCode
                    lastError = error
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
    private func formatToE164(_ phone: String) -> String {
        // Remove all non-numeric characters except leading +
        var cleaned = phone.trimmingCharacters(in: .whitespaces)
        
        // If already starts with +, keep it
        if cleaned.hasPrefix("+") {
            let digits = cleaned.dropFirst().filter { $0.isNumber }
            return "+\(digits)"
        }
        
        // Remove all non-digits
        let digits = cleaned.filter { $0.isNumber }
        
        // Assume US number if 10 digits
        if digits.count == 10 {
            return "+1\(digits)"
        }
        
        // If 11 digits starting with 1, assume US
        if digits.count == 11 && digits.hasPrefix("1") {
            return "+\(digits)"
        }
        
        // Otherwise, add + prefix
        return "+\(digits)"
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
        // Twilio specific error codes
        switch code {
        case 20404:
            return .verificationNotFound
        case 20429:
            return .rateLimitExceeded
        case 60200:
            return .invalidPhoneNumber
        case 60202:
            return .maxAttemptsReached
        case 60203:
            return .maxSendAttemptsReached
        case 60212:
            return .incorrectCode
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
    case maxAttemptsReached
    case maxSendAttemptsReached
    case rateLimitExceeded
    case authenticationFailed
    case permissionDenied
    case serverError
    case networkError(String)
    case invalidResponse
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
    
    /// Whether this is a retryable error
    var isRetryable: Bool {
        switch self {
        case .incorrectCode, .invalidCode:
            return true
        default:
            return false
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

