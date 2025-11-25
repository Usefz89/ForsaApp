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
    private let tradingBaseURL = AppConfig.Alpaca.tradingBaseURL
    private let dataBaseURL = AppConfig.Alpaca.dataBaseURL
    
    @Published var isPlacingOrder = false
    @Published var currentAccount: AlpacaAccount?
    @Published var currentPositions: [AlpacaPosition] = []
    
    // Mode Toggle: If true, we use Trading API endpoints (Single User). If false, Broker API (Sub-accounts).
    private(set) var isTradingMode = false
    
    private init() {}
    
    // MARK: - Initialization & Mode Check
    
    /// Verifies keys and determines if we should use Trading API or Broker API
    func initializeSession() async -> Bool {
        // For this specific implementation request, we are prioritizing Broker API.
        // We assume the keys provided in AppConfig are Broker API keys.
        
        // 1. Try Broker API first
        if await checkBrokerAPI() {
            print("Session Init: Verified Broker API Mode.")
            isTradingMode = false
            return true
        }
        
        // 2. If Broker check fails, fallback to Trading API check
        // This handles cases where the user might still be using Paper Trading keys
        if await checkTradingAPI() {
            print("Session Init: Broker check failed, but verified Trading API Mode.")
            isTradingMode = true
            return true
        }
        
        // 3. If both fail, default to Broker mode but log warning (as per user intent to reimplement as Broker)
        print("Session Init: Verification failed or offline. Defaulting to Broker Mode.")
        isTradingMode = false
        return false
    }
    
    private func checkTradingAPI() async -> Bool {
        let url = URL(string: "\(tradingBaseURL)/account")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
                await MainActor.run { self.currentAccount = account }
                return true
            }
        } catch {
            print("Trading API Check Failed: \(error)")
        }
        return false
    }
    
    private func checkBrokerAPI() async -> Bool {
        // Broker API usually requires Basic Auth.
        // Simple check: GET /v1/clock or /v1/assets (public-ish but auth required)
        // Or just try to list accounts (requires admin scope).
        // Let's try GET /v1/clock
        let url = URL(string: "\(brokerBaseURL)/clock")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let loginString = "\(apiKey):\(apiSecret)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return true
            }
        } catch {
            print("Broker API Check Failed: \(error)")
        }
        return false
    }
    
    // MARK: - Account Management
    
    /// Creates a new user account in Alpaca (Broker API Only)
    func createAccount(email: String, firstName: String, lastName: String) async throws -> String {
        print("📝 Starting Alpaca Account Creation...")
        print("   Email: \(email)")
        print("   Name: \(firstName) \(lastName)")
        
        if isTradingMode {
            // If in Trading Mode, we don't create accounts. We just return the existing Account ID.
            print("⚠️ In Trading Mode - returning existing account")
            if let account = currentAccount { return account.id }
            // If nil, fetch it
            _ = await checkTradingAPI()
            return currentAccount?.id ?? ""
        }
        
        // Broker API Flow
        let contact = AlpacaContact(
            email_address: email,
            phone_number: "+15555555555",
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
            tax_id: "555-12-3456",
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
        
        let signedAt = ISO8601DateFormatter().string(from: Date())
        let ipAddress = "127.0.0.1"
        
        // Required agreements for Alpaca Broker API
        let agreements = [
            AlpacaAgreement(agreement: "account_agreement", signed_at: signedAt, ip_address: ipAddress),
            AlpacaAgreement(agreement: "customer_agreement", signed_at: signedAt, ip_address: ipAddress),
            AlpacaAgreement(agreement: "margin_agreement", signed_at: signedAt, ip_address: ipAddress)
        ]
        
        let body = AlpacaCreateAccountRequest(
            contact: contact,
            identity: identity,
            disclosures: disclosures,
            agreements: agreements
        )
        
        let url = URL(string: "\(brokerBaseURL)/accounts")!
        var request = try createRequest(url: url, method: "POST")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(body)
        
        // Log the request body
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request Body:")
            print(bodyString)
        }
        
        print("📤 Sending POST to: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw Response:")
            print(responseString)
        }
        
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        print("✅ Account Created Successfully!")
        print("   Account ID: \(account.id)")
        print("   Status: \(account.status ?? "unknown")")
        
        return account.id
    }
    
    /// Fetches account details
    func fetchAccountDetails(accountId: String) async throws -> AlpacaAccount {
        let url: URL
        if isTradingMode {
            url = URL(string: "\(tradingBaseURL)/account")!
        } else {
            url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account")!
        }
        
        let request = try createRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        await MainActor.run { self.currentAccount = account }
        return account
    }
    
    /// Funds the account (Cash Injection Simulation)
    func fundAccount(accountId: String, amount: Double) async throws {
        if isTradingMode {
            // Trading API doesn't support Journals for self-funding in the same way.
            // Sandbox Paper Trading accounts are pre-funded. We might just log this or skip.
            print("Skipping funding in Trading Mode (Paper accounts are pre-funded)")
            return
        }
        
        guard amount > 0 else { return }
        let url = URL(string: "\(brokerBaseURL)/journals")!
        var request = try createRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "to_account": accountId,
            "from_account": "firm_account",
            "amount": String(format: "%.2f", amount),
            "entry_type": "JNLS",
            "description": "Cash Deposit Simulation"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        // Refresh account
        _ = try? await fetchAccountDetails(accountId: accountId)
    }
    
    // MARK: - Trading
    
    func placeOrder(accountId: String, symbol: String, notional: Double) async throws {
        let url: URL
        if isTradingMode {
            url = URL(string: "\(tradingBaseURL)/orders")!
        } else {
            url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/orders")!
        }
        
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
    
    func placeBasketOrder(accountId: String, amount: Double, portfolio: RiskLevel) async throws {
        await MainActor.run { isPlacingOrder = true }
        defer { Task { await MainActor.run { isPlacingOrder = false } } }
        
        let allocations = portfolio.allocations
        for allocation in allocations {
            let amountForAsset = amount * allocation.percentage
            if amountForAsset < 1.0 { continue }
            
            do {
                try await placeOrder(accountId: accountId, symbol: allocation.ticker, notional: amountForAsset)
                print("Placed order for \(allocation.ticker): $\(amountForAsset)")
            } catch {
                print("Failed to place order for \(allocation.ticker): \(error)")
            }
        }
    }
    
    func fetchPositions(accountId: String) async throws -> [AlpacaPosition] {
        let url: URL
        if isTradingMode {
            url = URL(string: "\(tradingBaseURL)/positions")!
        } else {
            url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/positions")!
        }
        
        let request = try createRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let positions = try JSONDecoder().decode([AlpacaPosition].self, from: data)
        await MainActor.run { self.currentPositions = positions }
        return positions
    }
    
    func fetchPortfolioHistory(accountId: String, period: String = "1M", timeframe: String = "1D") async throws -> [ChartDataPoint] {
        let url: URL
        if isTradingMode {
            url = URL(string: "\(tradingBaseURL)/account/portfolio/history")!
        } else {
            url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account/portfolio/history")!
        }
        
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "timeframe", value: timeframe)
        ]
        
        guard let finalUrl = components.url else { return [] }
        let request = try createRequest(url: finalUrl, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
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
    
    func getLatestPrice(symbol: String) async throws -> Double {
        let url = URL(string: "\(dataBaseURL)/stocks/\(symbol)/quotes/latest")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let result = try JSONDecoder().decode(AlpacaLatestQuote.self, from: data)
        return result.quote.ap 
    }
    
    // MARK: - Helpers
    
    private func createRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if isTradingMode {
            // Trading API Headers
            request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
            request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        } else {
            // Broker API Headers (Basic Auth)
            let loginString = "\(apiKey):\(apiSecret)"
            if let loginData = loginString.data(using: .utf8) {
                let base64LoginString = loginData.base64EncodedString()
                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            }
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("--------------------------------------------------")
            print("Alpaca API Error (Status \(httpResponse.statusCode)):")
            print(errorString)
            print("Request URL: \(response.url?.absoluteString ?? "Unknown")")
            print("--------------------------------------------------")
            
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Decoded Error: \(errorJson)")
            }
            
            throw URLError(.badServerResponse)
        }
    }
}
