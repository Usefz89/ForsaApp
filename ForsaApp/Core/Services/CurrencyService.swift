//
//  CurrencyService.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation

class CurrencyService {
    static let shared = CurrencyService()
    
    private init() {}
    
    /// Converts Kuwaiti Dinar (KWD) to US Dollar (USD)
    func convertKWDtoUSD(_ amount: Double) -> Double {
        return amount * AppConfig.Currency.kwdToUsdRate
    }
    
    /// Converts US Dollar (USD) to Kuwaiti Dinar (KWD)
    func convertUSDtoKWD(_ amount: Double) -> Double {
        return amount / AppConfig.Currency.kwdToUsdRate
    }
    
    /// Format USD for display
    func formatUSD(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    /// Format KWD for display
    func formatKWD(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "KWD"
        return formatter.string(from: NSNumber(value: amount)) ?? "KD \(amount)"
    }
}

