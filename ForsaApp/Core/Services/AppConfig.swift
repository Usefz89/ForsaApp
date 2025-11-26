//
//  AppConfig.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation

struct AppConfig {
    // Environment: "sandbox" or "production"
    static let alpacaEnvironment = "sandbox"
    
    struct Alpaca {
        // MARK: - WARNING: NEVER STORE SECRETS IN CLIENT CODE IN PRODUCTION
        // These should be fetched from a secure backend or injected at build time.
        
        // Broker API credentials from: https://broker-app.alpaca.markets/
        static let apiKey = "CKZPSCCOMX2OK2FGBAWMRQX62J"
        static let apiSecret = "dThe4wBZF4TZnCk2E9wq2SGNJk8DSdyWAFwXd5ujBs6"
        
        // Broker API Base URL (Sandbox)
        static let brokerBaseURL = "https://broker-api.sandbox.alpaca.markets/v1"
        
        // Market Data API Base URL
        static let dataBaseURL = "https://data.alpaca.markets/v2" 
    }
    
    struct Currency {
        // Fixed rate for MVP: 1 KWD = 3.25 USD
        static let kwdToUsdRate: Double = 3.25
    }
    
    // MARK: - Twilio Verify API
    
    struct Twilio {
        // MARK: - WARNING: NEVER STORE SECRETS IN CLIENT CODE IN PRODUCTION
        // These should be fetched from a secure backend or environment variables.
        // For production, use a backend proxy to call Twilio API.
        
        // Twilio Account SID from: https://console.twilio.com/
        // Find this on your Twilio Console Dashboard
        static let accountSid = "YOUR_TWILIO_ACCOUNT_SID"
        
        // Twilio Auth Token from: https://console.twilio.com/
        // Find this on your Twilio Console Dashboard
        static let authToken = "YOUR_TWILIO_AUTH_TOKEN"
        
        // Twilio Verify Service SID from: https://console.twilio.com/verify/services
        // Create a Verify Service and copy the Service SID
        static let verifyServiceSid = "YOUR_TWILIO_VERIFY_SERVICE_SID"
        
        // OTP Configuration
        static let otpLength = 6
        static let otpExpirationMinutes = 10
        static let maxAttempts = 5
        
        // Whether to use sandbox mode (for testing without sending real SMS)
        static let useSandbox = true
    }
}

