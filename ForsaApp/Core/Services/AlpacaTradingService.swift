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
    
    // MARK: - Initialization
    
    /// Verifies Broker API keys are valid
    func initializeSession() async -> Bool {
        if await checkBrokerAPI() {
            print("✅ Session Init: Broker API verified successfully.")
            return true
        }
        
        print("❌ Session Init: Broker API verification failed.")
        return false
    }
    
    private func checkBrokerAPI() async -> Bool {
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
    
    /// Creates a new user account in Alpaca Broker API
    func createAccount(email: String, firstName: String, lastName: String) async throws -> String {
        print("📝 Starting Alpaca Account Creation...")
        print("   Email: \(email)")
        print("   Name: \(firstName) \(lastName)")
        
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
        var request = try createBrokerRequest(url: url, method: "POST")
        
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
    
    /// Fetches account details for a sub-account
    func fetchAccountDetails(accountId: String) async throws -> AlpacaAccount {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account")!
        
        let request = try createBrokerRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        await MainActor.run { self.currentAccount = account }
        return account
    }
    
    /// Creates an ACH relationship for sandbox funding
    func createSandboxACHRelationship(accountId: String) async throws -> String {
        print("🏦 Creating sandbox ACH relationship for account: \(accountId)")
        
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/ach_relationships")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        // Sandbox test bank details
        let body: [String: Any] = [
            "account_owner_name": "Test User",
            "bank_account_type": "CHECKING",
            "bank_account_number": "32131231abc",
            "bank_routing_number": "121000358",
            "nickname": "Test Bank Account"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 ACH Relationship Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        
        // Parse the relationship ID
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let relationshipId = json["id"] as? String {
            print("✅ ACH Relationship Created: \(relationshipId)")
            return relationshipId
        }
        
        throw URLError(.badServerResponse)
    }
    
    /// Gets existing ACH relationships
    func getACHRelationships(accountId: String) async throws -> [[String: Any]] {
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/ach_relationships")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        if let relationships = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return relationships
        }
        return []
    }
    
    /// Funds the account via ACH Transfer (Sandbox)
    func fundAccount(accountId: String, amount: Double) async throws {
        print("💰 Funding account \(accountId) with $\(amount)")
        
        guard amount > 0 else { return }
        
        // First, check if we have an ACH relationship, if not create one
        var relationshipId: String?
        let relationships = try await getACHRelationships(accountId: accountId)
        
        if let firstRelationship = relationships.first,
           let id = firstRelationship["id"] as? String {
            relationshipId = id
            print("📌 Using existing ACH relationship: \(id)")
        } else {
            // Create a new ACH relationship for sandbox
            relationshipId = try await createSandboxACHRelationship(accountId: accountId)
        }
        
        guard let achRelationshipId = relationshipId else {
            throw URLError(.badServerResponse)
        }
        
        // Create transfer
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/transfers")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "transfer_type": "ach",
            "relationship_id": achRelationshipId,
            "amount": String(format: "%.2f", amount),
            "direction": "INCOMING"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Transfer Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        print("✅ Funding transfer initiated successfully!")
        
        // Refresh account
        _ = try? await fetchAccountDetails(accountId: accountId)
    }
    
    /// Withdraws funds from the account via ACH Transfer (Sandbox)
    func withdrawFunds(accountId: String, amount: Double) async throws {
        print("💸 Withdrawing $\(amount) from account \(accountId)")
        
        guard amount > 0 else { return }
        
        // Get existing ACH relationship
        let relationships = try await getACHRelationships(accountId: accountId)
        
        guard let firstRelationship = relationships.first,
              let achRelationshipId = firstRelationship["id"] as? String else {
            print("❌ No ACH relationship found. Cannot withdraw.")
            throw URLError(.badServerResponse)
        }
        
        // Create withdrawal transfer
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/transfers")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "transfer_type": "ach",
            "relationship_id": achRelationshipId,
            "amount": String(format: "%.2f", amount),
            "direction": "OUTGOING"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Withdrawal Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        print("✅ Withdrawal transfer initiated successfully!")
        
        // Refresh account
        _ = try? await fetchAccountDetails(accountId: accountId)
    }
    
    /// Gets transfer history for an account
    func getTransfers(accountId: String) async throws -> [[String: Any]] {
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/transfers")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        if let transfers = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return transfers
        }
        return []
    }
    
    // MARK: - Trading
    
    func placeOrder(accountId: String, symbol: String, notional: Double) async throws {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/orders")!
        
        var request = try createBrokerRequest(url: url, method: "POST")
        
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
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/positions")!
        
        let request = try createBrokerRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let positions = try JSONDecoder().decode([AlpacaPosition].self, from: data)
        await MainActor.run { self.currentPositions = positions }
        return positions
    }
    
    func fetchPortfolioHistory(accountId: String, period: String = "1M", timeframe: String = "1D") async throws -> [ChartDataPoint] {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account/portfolio/history")!
        
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "timeframe", value: timeframe)
        ]
        
        guard let finalUrl = components.url else { return [] }
        let request = try createBrokerRequest(url: finalUrl, method: "GET")
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
        // Market Data API uses the same Basic Auth for Broker API
        let loginString = "\(apiKey):\(apiSecret)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let result = try JSONDecoder().decode(AlpacaLatestQuote.self, from: data)
        return result.quote.ap 
    }
    
    // MARK: - Helpers
    
    private func createBrokerRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Broker API uses Basic Auth
        let loginString = "\(apiKey):\(apiSecret)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
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
