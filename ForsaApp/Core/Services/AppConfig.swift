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
        // MARK: - WARNING: NEVER STORE SECRETS IN CLIENT CODE IN PRODUCTION
        // These should be fetched from a secure backend or environment variables.
        // For production, use a backend proxy to call Twilio API.
        
        // Twilio Account SID from: https://console.twilio.com/
        // Find this on your Twilio Console Dashboard
        static let recoveryCode = "41BD84A4GHCFYGW48T8T7U3Q"
        static let accountSid = "AC6d19af252d14306685f4bcd87cd27ffa"
        
        // Twilio Auth Token from: https://console.twilio.com/
        // Find this on your Twilio Console Dashboard
        static let authToken = "744c2584988f39133c561f3b7cdccd58"
        
        // Twilio Verify Service SID from: https://console.twilio.com/verify/services
        // Create a Verify Service and copy the Service SID
        static let verifyServiceSid = "VA8149770f7ed55f7339917fe88c7e0603"
        
        // OTP Configuration
        static let otpLength = 6
        static let otpExpirationMinutes = 10
        static let maxAttempts = 5
        
        // Whether to use sandbox mode (for testing without sending real SMS)
        static let useSandbox = true
    }
}

