//
//  MarketsViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation
import Combine

class MarketsViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var filteredStocks: [Stock] = []
    @Published var selectedAssetType: AssetType = .stock
    @Published var selectedMarket: Market? = nil
    @Published var showHalalOnly = false
    @Published var searchQuery = ""
    @Published var isLoading = false

    private let mockDataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Update filtered stocks when any filter changes
        Publishers.CombineLatest4(
            $selectedAssetType,
            $selectedMarket,
            $showHalalOnly,
            $searchQuery
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }

    func loadData() {
        stocks = mockDataService.getAllStocks()
        applyFilters()
    }

    @MainActor
    func refreshData() async {
        isLoading = true

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        loadData()
        isLoading = false
    }

    func searchStocks(_ query: String) {
        searchQuery = query
    }

    func clearSearch() {
        searchQuery = ""
    }

    func toggleWatchlist(_ stock: Stock) {
        // In a real app, this would update the backend
        // For now, we'll just update the local state
        if let index = stocks.firstIndex(where: { $0.id == stock.id }) {
            stocks[index] = Stock(
                id: stock.id,
                symbol: stock.symbol,
                name: stock.name,
                market: stock.market,
                assetType: stock.assetType,
                currentPrice: stock.currentPrice,
                previousClose: stock.previousClose,
                marketCap: stock.marketCap,
                volume: stock.volume,
                logoURL: stock.logoURL,
                sector: stock.sector,
                industry: stock.industry,
                description: stock.description,
                shariaCompliance: stock.shariaCompliance,
                currency: stock.currency,
                isWatchlisted: !stock.isWatchlisted,
                dividendYield: stock.dividendYield,
                peRatio: stock.peRatio,
                week52High: stock.week52High,
                week52Low: stock.week52Low
            )
            applyFilters()
        }
    }

    private func applyFilters() {
        var filtered = stocks

        // Filter by asset type
        filtered = filtered.filter { $0.assetType == selectedAssetType }

        // Filter by market if selected
        if let market = selectedMarket {
            filtered = filtered.filter { $0.market == market }
        }

        // Filter by Halal compliance if enabled
        if showHalalOnly {
            filtered = filtered.filter { $0.shariaCompliance == .compliant }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            filtered = filtered.filter { stock in
                stock.symbol.localizedCaseInsensitiveContains(searchQuery) ||
                stock.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Sort by market cap (descending) for stocks, or by name for ETFs
        if selectedAssetType == .stock {
            filtered.sort { (lhs, rhs) in
                guard let lhsMarketCap = lhs.marketCap,
                      let rhsMarketCap = rhs.marketCap else {
                    return lhs.name < rhs.name
                }
                return lhsMarketCap > rhsMarketCap
            }
        } else {
            filtered.sort { $0.name < $1.name }
        }

        filteredStocks = filtered
    }
}

class StockDetailViewModel: ObservableObject {
    @Published var stock: Stock?
    @Published var priceHistory: [StockPricePoint] = []
    @Published var selectedTimeframe: TimeFrame = .oneWeek
    @Published var isLoading = false

    func loadStockData(_ stock: Stock) {
        self.stock = stock
        generatePriceHistory()
    }

    private func generatePriceHistory() {
        guard let stock = stock else { return }

        let calendar = Calendar.current
        let now = Date()
        var history: [StockPricePoint] = []

        let days = selectedTimeframe.days
        let basePrice = stock.previousClose
        let currentPrice = stock.currentPrice
        let totalChange = currentPrice - basePrice

        for i in 0...days {
            let date = calendar.date(byAdding: .day, value: -days + i, to: now) ?? now
            let progress = Double(i) / Double(days)
            let randomVariation = Double.random(in: -0.05...0.05) * basePrice
            let price = basePrice + (totalChange * progress) + randomVariation

            history.append(StockPricePoint(date: date, price: max(price, basePrice * 0.8)))
        }

        priceHistory = history
    }
}

struct StockPricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}