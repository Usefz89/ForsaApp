//
//  AppConfig.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation

struct AppConfig {
    struct Alpaca {
        // MARK: - WARNING: NEVER STORE SECRETS IN CLIENT CODE IN PRODUCTION
        // These should be fetched from a secure backend or injected at build time.
        static let apiKey = "CKDZN7II6ODMWF4B4PZ2RD5CLS"
        static let apiSecret = "DU2mPL5f46TeKXQt4qf84gkAQoLNA8fDwK6JWm9sXyfV"
        
        // Broker API Base URL
        static let brokerBaseURL = "https://broker-api.sandbox.alpaca.markets/v1"
        
        // Trading API Base URL (for reference, though we use Broker API endpoints mostly)
        static let tradingBaseURL = "https://paper-api.alpaca.markets/v2"
        
        // Data API Base URL
        static let dataBaseURL = "https://data.alpaca.markets/v2" 
    }
    
    struct Currency {
        // Fixed rate for MVP: 1 KWD = 3.25 USD
        static let kwdToUsdRate: Double = 3.25
    }
}

