import Foundation

class AlpacaTradingService: ObservableObject {
    static let shared = AlpacaTradingService()
    
    // Placeholder Config - In production, use secure storage
    private let apiKey = "CKDZN7II6ODMWF4B4PZ2RD5CLS"
    private let apiSecret = "DU2mPL5f46TeKXQt4qf84gkAQoLNA8fDwK6JWm9sXyfV"
    private let baseURL = "https://broker-api.sandbox.alpaca.markets"
    
    @Published var isPlacingOrder = false
    
    func placeBasketOrder(amount: Double, portfolio: RiskLevel) async throws {
        await MainActor.run { isPlacingOrder = true }
        
        defer {
            Task { await MainActor.run { isPlacingOrder = false } }
        }
        
        let allocations = portfolio.allocations
        
        for allocation in allocations {
            let amountForAsset = amount * allocation.percentage
            
            // Skip very small amounts to avoid API errors
            if amountForAsset < 1.0 {
                print("Skipping \(allocation.ticker) due to small amount: $\(amountForAsset)")
                continue
            }
            
            do {
                try await placeOrder(ticker: allocation.ticker, notional: amountForAsset)
                print("Successfully placed order for \(allocation.ticker): $\(amountForAsset)")
            } catch {
                print("Failed to place order for \(allocation.ticker): \(error)")
                // In a real app, you'd want robust error handling/retry logic here
            }
        }
    }
    
    private func placeOrder(ticker: String, notional: Double) async throws {
        guard let url = URL(string: "\(baseURL)/v2/orders") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "symbol": ticker,
            "notional": String(format: "%.2f", notional), // Send as string for precision
            "side": "buy",
            "type": "market",
            "time_in_force": "day"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
