//
//  AlpacaTradingService.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation
import Combine

class AlpacaTradingService: ObservableObject {
    static let shared = AlpacaTradingService()
    
    private let apiKey = AppConfig.Alpaca.apiKey
    private let apiSecret = AppConfig.Alpaca.apiSecret
    private let brokerBaseURL = AppConfig.Alpaca.brokerBaseURL
    private let dataBaseURL = AppConfig.Alpaca.dataBaseURL
    
    @Published var isPlacingOrder = false
    @Published var currentAccount: AlpacaAccount?
    @Published var currentPositions: [AlpacaPosition] = []
    
    private init() {}
    
    // MARK: - Account Management
    
    /// Creates a new user account in Alpaca (Broker API)
    /// Returns the account ID
    func createAccount(email: String, firstName: String, lastName: String) async throws -> String {
        // Minimal dummy data for Sandbox
        let contact = AlpacaContact(
            email_address: email,
            phone_number: "555-555-5555",
            street_address: ["123 Main St"],
            city: "New York",
            state: "NY",
            postal_code: "10001",
            country: "USA"
        )
        
        let identity = AlpacaIdentity(
            given_name: firstName,
            family_name: lastName,
            date_of_birth: "1990-01-01",
            tax_id: "000-00-0000", // Dummy SSN for Sandbox
            tax_id_type: "USA_SSN",
            country_of_citizenship: "USA",
            country_of_birth: "USA",
            country_of_tax_residence: "USA",
            funding_source: ["employment_income"]
        )
        
        let disclosures = AlpacaDisclosures(
            is_control_person: false,
            is_affiliated_exchange_or_finra: false,
            is_politically_exposed: false,
            immediate_family_exposed: false
        )
        
        let agreement = AlpacaAgreement(
            agreement: "margin_agreement",
            signed_at: ISO8601DateFormatter().string(from: Date()),
            ip_address: "127.0.0.1"
        )
        
        let body = AlpacaCreateAccountRequest(
            contact: contact,
            identity: identity,
            disclosures: disclosures,
            agreements: [agreement]
        )
        
        let url = URL(string: "\(brokerBaseURL)/accounts")!
        var request = try createRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        return account.id
    }
    
    /// Fetches account details
    func fetchAccountDetails(accountId: String) async throws -> AlpacaAccount {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account")!
        let request = try createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        
        await MainActor.run {
            self.currentAccount = account
        }
        return account
    }
    
    /// Funds the account (Cash Injection Simulation)
    /// Amount in USD
    func fundAccount(accountId: String, amount: Double) async throws {
        guard amount > 0 else { return }
        
        let url = URL(string: "\(brokerBaseURL)/journals")!
        var request = try createRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "to_account": accountId,
            "from_account": "firm_account", // Assumes firm account has funds (default in Sandbox)
            "amount": String(format: "%.2f", amount),
            "entry_type": "JNLS", // Journal entry
            "description": "Cash Deposit Simulation"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        // Refresh account details after funding
        _ = try? await fetchAccountDetails(accountId: accountId)
    }
    
    // MARK: - Trading
    
    /// Place a buy order for a specific dollar amount (Notional)
    func placeOrder(accountId: String, symbol: String, notional: Double) async throws {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/orders")!
        var request = try createRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "symbol": symbol,
            "notional": String(format: "%.2f", notional),
            "side": "buy",
            "type": "market",
            "time_in_force": "day"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
    }
    
    /// Place orders for a portfolio allocation (Basket Order)
    func placeBasketOrder(accountId: String, amount: Double, portfolio: RiskLevel) async throws {
        await MainActor.run { isPlacingOrder = true }
        defer { Task { await MainActor.run { isPlacingOrder = false } } }
        
        let allocations = portfolio.allocations
        
        // Calculate notional amounts
        for allocation in allocations {
            let amountForAsset = amount * allocation.percentage
            
            // Skip very small amounts (< $1)
            if amountForAsset < 1.0 { continue }
            
            do {
                try await placeOrder(accountId: accountId, symbol: allocation.ticker, notional: amountForAsset)
                print("Placed order for \(allocation.ticker): $\(amountForAsset)")
            } catch {
                print("Failed to place order for \(allocation.ticker): \(error)")
            }
        }
    }
    
    /// Fetch open positions
    func fetchPositions(accountId: String) async throws -> [AlpacaPosition] {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/positions")!
        let request = try createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let positions = try JSONDecoder().decode([AlpacaPosition].self, from: data)
        
        await MainActor.run {
            self.currentPositions = positions
        }
        return positions
    }
    
    /// Fetch portfolio history for charts
    func fetchPortfolioHistory(accountId: String, period: String = "1M", timeframe: String = "1D") async throws -> [ChartDataPoint] {
        // URL: GET /trading/accounts/{account_id}/account/portfolio/history
        // Params: period (1D, 1W, 1M, 1A), timeframe (1Min, 15Min, 1H, 1D)
        
        var components = URLComponents(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account/portfolio/history")!
        components.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "timeframe", value: timeframe)
        ]
        
        guard let url = components.url else { return [] }
        let request = try createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        // Decode response
        struct HistoryResponse: Codable {
            let timestamp: [Int]
            let equity: [Double]
        }
        
        let history = try JSONDecoder().decode(HistoryResponse.self, from: data)
        
        var points: [ChartDataPoint] = []
        for (index, ts) in history.timestamp.enumerated() {
            if index < history.equity.count {
                let date = Date(timeIntervalSince1970: TimeInterval(ts))
                let value = history.equity[index]
                points.append(ChartDataPoint(date: date, value: value))
            }
        }
        
        return points
    }
    
    // MARK: - Market Data
    
    /// Fetch latest quote for a symbol
    func getLatestPrice(symbol: String) async throws -> Double {
        // Use Data API
        // Note: Data API usually requires different authentication if using a standalone Data Key,
        // but with Broker API, we often use the same Key/Secret as Basic Auth.
        // URL: https://data.alpaca.markets/v2/stocks/{symbol}/quotes/latest
        
        let url = URL(string: "\(dataBaseURL)/stocks/\(symbol)/quotes/latest")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Data API uses same headers
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let result = try JSONDecoder().decode(AlpacaLatestQuote.self, from: data)
        // Midpoint or just Bid/Ask? Let's use Ask Price as "Buy Price"
        return result.quote.ap 
    }
    
    // MARK: - Helpers
    
    private func createRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        // Basic Auth for Broker API
        let loginString = "\(apiKey):\(apiSecret)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw URLError(.userAuthenticationRequired)
        }
        let base64LoginString = loginData.base64EncodedString()
        
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Alpaca API Error: \(errorJson)")
            } else {
                print("Alpaca API Error: \(String(data: data, encoding: .utf8) ?? "Unknown")")
            }
            throw URLError(.badServerResponse)
        }
    }
}
