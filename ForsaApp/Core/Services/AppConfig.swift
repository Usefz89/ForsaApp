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
        // MARK: - API Credentials (loaded from Secrets.xcconfig via Info.plist)

        static let apiKey: String = {
            guard let key = Bundle.main.infoDictionary?["ALPACA_API_KEY"] as? String,
                  !key.isEmpty, !key.contains("$(") else {
                fatalError("ALPACA_API_KEY not configured. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your values.")
            }
            return key
        }()

        static let apiSecret: String = {
            guard let secret = Bundle.main.infoDictionary?["ALPACA_API_SECRET"] as? String,
                  !secret.isEmpty, !secret.contains("$(") else {
                fatalError("ALPACA_API_SECRET not configured. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your values.")
            }
            return secret
        }()

        // Broker API Base URL (Sandbox)
        static let brokerBaseURL = "https://broker-api.sandbox.alpaca.markets/v1"

        // Market Data API Base URL
        static let dataBaseURL = "https://data.alpaca.markets/v2"

        // MARK: - Rebalancing API Settings
        // Enable/disable server-side rebalancing feature
        static let rebalancingAPIEnabled = true

        // Rebalancing API uses beta endpoints
        // See: https://alpaca.markets/learn/how-to-get-started-with-rebalancing-api
        static let rebalancingBaseURL = "https://broker-api.sandbox.alpaca.markets/v1/beta/rebalancing"
    }
    
    struct Currency {
        // Fixed rate for MVP: 1 KWD = 3.25 USD
        static let kwdToUsdRate: Double = 3.25
        
        /// Primary display currency for Kuwait users
        static let primaryCurrency = "KWD"
        
        /// Secondary currency (trading currency)
        static let secondaryCurrency = "USD"
        
        // MARK: - Currency Conversion Helpers
        
        /// Convert USD to KWD
        static func usdToKwd(_ usdAmount: Double) -> Double {
            return usdAmount / kwdToUsdRate
        }
        
        /// Convert KWD to USD
        static func kwdToUsd(_ kwdAmount: Double) -> Double {
            return kwdAmount * kwdToUsdRate
        }
        
        // MARK: - Dual Currency Formatting
        
        /// Format amount showing KWD with USD equivalent
        /// Example: "30.77 KWD (100.00 USD)"
        static func formatDualCurrency(usdAmount: Double) -> String {
            let kwdAmount = usdToKwd(usdAmount)
            return String(format: "%.2f KWD (%.2f USD)", kwdAmount, usdAmount)
        }
        
        /// Format amount showing KWD primary with USD in parentheses
        /// Example: "٣٠.٧٧ د.ك ($100.00)"
        static func formatDualCurrencyArabic(usdAmount: Double) -> String {
            let kwdAmount = usdToKwd(usdAmount)
            return String(format: "%.2f د.ك ($%.2f)", kwdAmount, usdAmount)
        }
        
        /// Format just KWD amount from USD
        static func formatKWD(fromUSD usdAmount: Double) -> String {
            let kwdAmount = usdToKwd(usdAmount)
            return String(format: "%.2f KWD", kwdAmount)
        }
        
        /// Format just USD amount
        static func formatUSD(_ usdAmount: Double) -> String {
            return String(format: "$%.2f", usdAmount)
        }
        
        /// Format with compact notation for large amounts
        /// Example: "30.77K KWD (100K USD)"
        static func formatDualCurrencyCompact(usdAmount: Double) -> String {
            let kwdAmount = usdToKwd(usdAmount)
            
            if usdAmount >= 1_000_000 {
                return String(format: "%.1fM KWD (%.1fM USD)", kwdAmount / 1_000_000, usdAmount / 1_000_000)
            } else if usdAmount >= 1_000 {
                return String(format: "%.1fK KWD (%.1fK USD)", kwdAmount / 1_000, usdAmount / 1_000)
            } else {
                return formatDualCurrency(usdAmount: usdAmount)
            }
        }
        
        /// Format portfolio value for display
        static func formatPortfolioValue(usdAmount: Double, showBothCurrencies: Bool = true) -> String {
            if showBothCurrencies {
                return formatDualCurrency(usdAmount: usdAmount)
            } else {
                return formatKWD(fromUSD: usdAmount)
            }
        }
    }
    
    // MARK: - Twilio Verify API

    struct Twilio {
        // MARK: - API Credentials (loaded from Secrets.xcconfig via Info.plist)

        static let accountSid: String = {
            guard let sid = Bundle.main.infoDictionary?["TWILIO_ACCOUNT_SID"] as? String,
                  !sid.isEmpty, !sid.contains("$(") else {
                fatalError("TWILIO_ACCOUNT_SID not configured. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your values.")
            }
            return sid
        }()

        static let authToken: String = {
            guard let token = Bundle.main.infoDictionary?["TWILIO_AUTH_TOKEN"] as? String,
                  !token.isEmpty, !token.contains("$(") else {
                fatalError("TWILIO_AUTH_TOKEN not configured. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your values.")
            }
            return token
        }()

        static let recoveryCode: String = {
            guard let code = Bundle.main.infoDictionary?["TWILIO_RECOVERY_CODE"] as? String,
                  !code.isEmpty, !code.contains("$(") else {
                fatalError("TWILIO_RECOVERY_CODE not configured. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your values.")
            }
            return code
        }()

        static let verifyServiceSid: String = {
            guard let sid = Bundle.main.infoDictionary?["TWILIO_VERIFY_SERVICE_SID"] as? String,
                  !sid.isEmpty, !sid.contains("$(") else {
                fatalError("TWILIO_VERIFY_SERVICE_SID not configured. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your values.")
            }
            return sid
        }()

        // OTP Configuration
        static let otpLength = 6
        static let otpExpirationMinutes = 10
        static let maxAttempts = 5

        // Whether to use sandbox mode (for testing without sending real SMS)
        static let useSandbox = true

        // MARK: - Development Bypass Mode
        // When enabled, skips real Twilio API calls to save credits during development
        // Set to FALSE for production!
        static let useDevelopmentBypass = true

        // Test OTP code accepted in development mode
        // Users can enter this code to verify without receiving real SMS
        static let testOTPCode = "123456"
    }
}

