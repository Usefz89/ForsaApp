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
        
        // TODO: Replace with your BROKER API credentials (not Trading API)
        // Get these from: https://broker-app.alpaca.markets/
        static let apiKey = "CKZPSCCOMX2OK2FGBAWMRQX62J"
        static let apiSecret = "dThe4wBZF4TZnCk2E9wq2SGNJk8DSdyWAFwXd5ujBs6"
        
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

