//
//  AlpacaModels.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation

// MARK: - Broker API Models

struct AlpacaAccount: Codable, Identifiable {
    let id: String
    let accountNumber: String?
    let status: String?
    let currency: String?
    let lastEquity: String?
    let cash: String?
    let buyingPower: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountNumber = "account_number"
        case status
        case currency
        case lastEquity = "last_equity"
        case cash
        case buyingPower = "buying_power"
        case createdAt = "created_at"
    }
    
    // Helpers to convert string values to Double
    var equityValue: Double { Double(lastEquity ?? "0") ?? 0.0 }
    var cashValue: Double { Double(cash ?? "0") ?? 0.0 }
    var buyingPowerValue: Double { Double(buyingPower ?? "0") ?? 0.0 }
}

struct AlpacaPosition: Codable, Identifiable {
    var id: String { symbol } // Use symbol as ID since API doesn't provide unique position ID
    let symbol: String
    let qty: String
    let marketValue: String?
    let costBasis: String
    let avgEntryPrice: String
    let currentPrice: String?
    let changeToday: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case qty
        case marketValue = "market_value"
        case costBasis = "cost_basis"
        case avgEntryPrice = "avg_entry_price"
        case currentPrice = "current_price"
        case changeToday = "change_today"
    }
    
    var qtyValue: Double { Double(qty) ?? 0.0 }
    var marketValueValue: Double { Double(marketValue ?? "0") ?? 0.0 }
    var avgEntryPriceValue: Double { Double(avgEntryPrice) ?? 0.0 }
    var currentPriceValue: Double { Double(currentPrice ?? "0") ?? 0.0 }
}

struct AlpacaOrder: Codable, Identifiable {
    let id: String
    let clientOrderId: String?
    let symbol: String
    let qty: String?
    let notional: String?
    let side: String
    let type: String
    let timeInForce: String
    let status: String
    let filledQty: String
    let filledAvgPrice: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case symbol
        case qty
        case notional
        case side
        case type
        case timeInForce = "time_in_force"
        case status
        case filledQty = "filled_qty"
        case filledAvgPrice = "filled_avg_price"
        case createdAt = "created_at"
    }
}

// MARK: - Market Data Models

struct AlpacaBar: Codable {
    let t: String // Timestamp
    let o: Double // Open
    let h: Double // High
    let l: Double // Low
    let c: Double // Close
    let v: Int    // Volume
}

struct AlpacaBarsResponse: Codable {
    let bars: [String: [AlpacaBar]]?
    // In V2, it might be structured differently
}

struct AlpacaTrade: Codable {
    let t: String
    let p: Double
    let s: Int
}

struct AlpacaLatestQuote: Codable {
    let symbol: String
    let quote: AlpacaQuoteData
}

struct AlpacaQuoteData: Codable {
    let t: String // Timestamp
    let ap: Double // Ask Price
    let as_size: Int // Ask Size
    let bp: Double // Bid Price
    let bs_size: Int // Bid Size
    
    enum CodingKeys: String, CodingKey {
        case t
        case ap
        case as_size = "as"
        case bp
        case bs_size = "bs"
    }
}

// Simplified creation request for Sandbox
struct AlpacaContact: Codable {
    let email_address: String
    let phone_number: String
    let street_address: [String]
    let city: String
    let state: String?
    let postal_code: String?
    let country: String?
}

struct AlpacaIdentity: Codable {
    let given_name: String
    let family_name: String
    let date_of_birth: String // YYYY-MM-DD
    let tax_id: String?
    let tax_id_type: String?
    let country_of_citizenship: String?
    let country_of_birth: String?
    let country_of_tax_residence: String?
    let funding_source: [String]?
}

struct AlpacaCreateAccountRequest: Codable {
    let contact: AlpacaContact
    let identity: AlpacaIdentity
    let disclosures: AlpacaDisclosures
    let agreements: [AlpacaAgreement]
}

struct AlpacaDisclosures: Codable {
    let is_control_person: Bool
    let is_affiliated_exchange_or_finra: Bool
    let is_politically_exposed: Bool
    let immediate_family_exposed: Bool
}

struct AlpacaAgreement: Codable {
    let agreement: String
    let signed_at: String
    let ip_address: String
}

