//
//  KNETPaymentService.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import Foundation

// MARK: - KNET Test Card Information

/// KNET Sandbox Test Card Details
/// Use these credentials when testing in sandbox mode
enum KNETTestCards {
    /// Primary test card for KNET sandbox transactions
    static let testCard = KNETTestCard(
        bankName: "Knet Test Card [KNET1]",
        cardNumber: "8888880000000001",
        expiryDate: "09/30",
        pin: "1234"
    )
    
    /// Alternative test scenarios
    static let declinedCard = KNETTestCard(
        bankName: "Knet Test Card [DECLINED]",
        cardNumber: "8888880000000002",
        expiryDate: "09/30",
        pin: "1234"
    )
}

struct KNETTestCard {
    let bankName: String
    let cardNumber: String
    let expiryDate: String
    let pin: String
    
    var maskedNumber: String {
        let last4 = String(cardNumber.suffix(4))
        return "**** **** **** \(last4)"
    }
}

// MARK: - KNET Payment Models

/// KNET Transaction Request - Sent to initiate a payment
struct KNETPaymentRequest: Codable {
    let merchantId: String
    let amount: Double
    let currency: String
    let trackId: String
    let responseUrl: String
    let errorUrl: String
    let language: String
    let customerEmail: String?
    let customerPhone: String?
    
    enum CodingKeys: String, CodingKey {
        case merchantId = "merchant_id"
        case amount
        case currency
        case trackId = "track_id"
        case responseUrl = "response_url"
        case errorUrl = "error_url"
        case language = "lang"
        case customerEmail = "customer_email"
        case customerPhone = "customer_phone"
    }
}

/// KNET Payment Response - Returned after payment initiation
struct KNETPaymentResponse: Codable {
    let paymentId: String
    let paymentUrl: String
    let trackId: String
    let status: KNETPaymentStatus
    
    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case paymentUrl = "payment_url"
        case trackId = "track_id"
        case status
    }
}

/// KNET Payment Result - Returned after user completes payment
struct KNETPaymentResult: Codable {
    let paymentId: String
    let trackId: String
    let tranId: String?
    let authCode: String?
    let result: String
    let postDate: String?
    let referenceId: String?
    let amount: Double
    let status: KNETPaymentStatus
    
    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case trackId = "track_id"
        case tranId = "tran_id"
        case authCode = "auth"
        case result
        case postDate = "post_date"
        case referenceId = "ref"
        case amount
        case status
    }
    
    var isSuccessful: Bool {
        result.uppercased() == "CAPTURED" || status == .captured
    }
}

/// KNET Payment Status
enum KNETPaymentStatus: String, Codable {
    case initiated = "INITIATED"
    case pending = "PENDING"
    case captured = "CAPTURED"
    case cancelled = "CANCELLED"
    case failed = "FAILED"
    case notCaptured = "NOT_CAPTURED"
    
    var displayName: String {
        switch self {
        case .initiated: return "Payment Initiated"
        case .pending: return "Payment Pending"
        case .captured: return "Payment Successful"
        case .cancelled: return "Payment Cancelled"
        case .failed: return "Payment Failed"
        case .notCaptured: return "Payment Not Captured"
        }
    }
    
    var isSuccessful: Bool {
        self == .captured
    }
}

// MARK: - KNET Configuration

/// KNET API Configuration
/// Switch between sandbox and production environments
enum KNETEnvironment {
    case sandbox
    case production
    
    var baseURL: String {
        switch self {
        case .sandbox:
            // UPayments Sandbox (recommended for testing)
            return "https://sandboxapi.upayments.com/api/v1"
        case .production:
            return "https://api.upayments.com/api/v1"
        }
    }
    
    /// KNET Test Portal (Direct KNET integration)
    var knetPortalURL: String {
        switch self {
        case .sandbox:
            return "https://kpaytest.com.kw"
        case .production:
            return "https://kpay.com.kw"
        }
    }
}

// MARK: - KNET Payment Service

/// Service to handle KNET payment gateway integration
/// 
/// # Integration Options:
/// 
/// ## Option 1: UPayments (Recommended)
/// - Sign up at: https://upayments.com
/// - Provides full sandbox environment
/// - iOS SDK available
/// - REST API documentation: https://developers.upayments.com
/// 
/// ## Option 2: Direct KNET Integration
/// - Register with KNET through your bank
/// - Obtain Transportal ID, Password, and Terminal Resource Key
/// - Test portal: https://kpaytest.com.kw
/// 
/// # Payment Flow:
/// 1. App sends payment request to backend (or directly to UPayments)
/// 2. Backend/UPayments creates KNET payment session
/// 3. User is redirected to KNET payment page (WebView)
/// 4. User selects bank and enters credentials
/// 5. KNET redirects back with result
/// 6. Backend verifies payment and credits account
///
/// # Sandbox Test Card:
/// - Bank: Knet Test Card [KNET1]
/// - Card Number: 8888880000000001
/// - Expiry: 09/30
/// - PIN: 1234
///
@MainActor
class KNETPaymentService: ObservableObject {
    static let shared = KNETPaymentService()
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var currentPayment: KNETPaymentResponse?
    @Published var lastResult: KNETPaymentResult?
    @Published var errorMessage: String?
    
    // MARK: - Configuration
    
    /// Current environment - change to .production when going live
    private let environment: KNETEnvironment = .sandbox
    
    /// UPayments API credentials (obtain from https://upayments.com)
    /// In production, store these securely (Keychain/Environment)
    private var apiKey: String {
        // TODO: Replace with your UPayments API key
        return "jtest123" // Sandbox test key
    }
    
    private var merchantId: String {
        // TODO: Replace with your merchant ID
        return "1201" // Sandbox merchant ID
    }
    
    private var baseURL: String {
        environment.baseURL
    }
    
    private var sandboxMode: Bool {
        environment == .sandbox
    }
    
    // MARK: - Public Methods
    
    /// Initiates a KNET payment
    /// - Parameters:
    ///   - amount: Amount in KWD
    ///   - trackId: Unique transaction identifier
    /// - Returns: Payment response with redirect URL
    func initiatePayment(amount: Double, trackId: String) async throws -> KNETPaymentResponse {
        isProcessing = true
        errorMessage = nil
        
        defer { isProcessing = false }
        
        // In production, this would call your backend which then calls KNET
        // For now, simulate the payment initiation
        if sandboxMode {
            return try await simulatePaymentInitiation(amount: amount, trackId: trackId)
        }
        
        // Production implementation would be:
        // let request = KNETPaymentRequest(...)
        // let response = try await networkService.post(baseURL, body: request)
        // return response
        
        throw KNETError.notImplemented
    }
    
    /// Handles the payment callback from KNET
    /// - Parameter url: The callback URL with payment result parameters
    /// - Returns: Payment result
    func handlePaymentCallback(url: URL) async throws -> KNETPaymentResult {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw KNETError.invalidCallback
        }
        
        // Parse KNET callback parameters
        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value
        }
        
        // In production, verify the payment with backend
        if sandboxMode {
            return try await simulatePaymentResult(params: params)
        }
        
        throw KNETError.notImplemented
    }
    
    /// Verifies a payment status
    /// - Parameter paymentId: The KNET payment ID
    /// - Returns: Current payment status
    func verifyPayment(paymentId: String) async throws -> KNETPaymentResult {
        isProcessing = true
        errorMessage = nil
        
        defer { isProcessing = false }
        
        // In production, query backend for payment status
        if sandboxMode {
            return try await simulatePaymentVerification(paymentId: paymentId)
        }
        
        throw KNETError.notImplemented
    }
    
    // MARK: - Sandbox Simulation
    
    private func simulatePaymentInitiation(amount: Double, trackId: String) async throws -> KNETPaymentResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let paymentId = "KNET-\(UUID().uuidString.prefix(8))"
        let response = KNETPaymentResponse(
            paymentId: paymentId,
            paymentUrl: "https://sandbox.knet.com.kw/payment?id=\(paymentId)",
            trackId: trackId,
            status: .initiated
        )
        
        currentPayment = response
        return response
    }
    
    private func simulatePaymentResult(params: [String: String]) async throws -> KNETPaymentResult {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let result = KNETPaymentResult(
            paymentId: params["payment_id"] ?? UUID().uuidString,
            trackId: params["track_id"] ?? "",
            tranId: "TRN\(Int.random(in: 100000...999999))",
            authCode: "\(Int.random(in: 100000...999999))",
            result: "CAPTURED",
            postDate: ISO8601DateFormatter().string(from: Date()),
            referenceId: "REF\(Int.random(in: 100000...999999))",
            amount: Double(params["amount"] ?? "0") ?? 0,
            status: .captured
        )
        
        lastResult = result
        return result
    }
    
    private func simulatePaymentVerification(paymentId: String) async throws -> KNETPaymentResult {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let current = currentPayment else {
            throw KNETError.paymentNotFound
        }
        
        return KNETPaymentResult(
            paymentId: current.paymentId,
            trackId: current.trackId,
            tranId: "TRN\(Int.random(in: 100000...999999))",
            authCode: "\(Int.random(in: 100000...999999))",
            result: "CAPTURED",
            postDate: ISO8601DateFormatter().string(from: Date()),
            referenceId: "REF\(Int.random(in: 100000...999999))",
            amount: 0,
            status: .captured
        )
    }
}

// MARK: - KNET Errors

enum KNETError: LocalizedError {
    case notImplemented
    case invalidCallback
    case paymentNotFound
    case paymentFailed(String)
    case networkError(Error)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "KNET integration is not yet configured for production."
        case .invalidCallback:
            return "Invalid payment callback received."
        case .paymentNotFound:
            return "Payment not found."
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from payment gateway."
        }
    }
}

// MARK: - KNET URL Handler

extension KNETPaymentService {
    /// Generates the KNET payment URL for WebView
    /// In production, this URL comes from your backend
    func getPaymentURL(for response: KNETPaymentResponse) -> URL? {
        // In sandbox mode, return a simulated payment page
        if sandboxMode {
            // This would be a real KNET URL in production
            return URL(string: response.paymentUrl)
        }
        return URL(string: response.paymentUrl)
    }
    
    /// Checks if a URL is a KNET callback URL
    func isCallbackURL(_ url: URL) -> Bool {
        let callbackHosts = ["forsa.app", "localhost", "127.0.0.1"]
        guard let host = url.host else { return false }
        return callbackHosts.contains(host) && url.path.contains("knet/callback")
    }
}

