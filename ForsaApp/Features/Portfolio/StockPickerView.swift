//
//  StockPickerView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct StockPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: InvestmentFlowViewModel

    @State private var searchText = ""
    @State private var selectedStocks: Set<UUID> = []

    init(viewModel: InvestmentFlowViewModel) {
        self.viewModel = viewModel
    }

    private var sampleStocks: [SampleStock] = [
        SampleStock(symbol: "AAPL", name: "Apple Inc.", sector: "Technology", price: 175.43, change: 2.1, isHalal: true),
        SampleStock(symbol: "MSFT", name: "Microsoft Corp.", sector: "Technology", price: 338.11, change: 1.8, isHalal: true),
        SampleStock(symbol: "GOOGL", name: "Alphabet Inc.", sector: "Technology", price: 131.96, change: -0.5, isHalal: true),
        SampleStock(symbol: "NVDA", name: "NVIDIA Corp.", sector: "Technology", price: 421.13, change: 3.2, isHalal: true),
        SampleStock(symbol: "AMZN", name: "Amazon.com Inc.", sector: "Consumer Discretionary", price: 131.49, change: 1.1, isHalal: true),
        SampleStock(symbol: "TSLA", name: "Tesla Inc.", sector: "Automotive", price: 248.42, change: -1.3, isHalal: true),
        SampleStock(symbol: "META", name: "Meta Platforms Inc.", sector: "Technology", price: 296.73, change: 0.8, isHalal: true),
        SampleStock(symbol: "NFLX", name: "Netflix Inc.", sector: "Media & Entertainment", price: 389.25, change: 2.4, isHalal: true),
        SampleStock(symbol: "SPUS", name: "SPDR Portfolio S&P 500 ETF", sector: "ETF", price: 44.22, change: 0.6, isHalal: true),
        SampleStock(symbol: "HLAL", name: "Wahed FTSE USA Shariah ETF", sector: "ETF", price: 49.15, change: 0.9, isHalal: true),
        SampleStock(symbol: "SPSK", name: "SPDR Portfolio Developed World ex-US ETF", sector: "ETF", price: 29.44, change: 0.3, isHalal: true),
        SampleStock(symbol: "UMMA", name: "Wahed Dow Jones Islamic World ETF", sector: "ETF", price: 32.87, change: 0.7, isHalal: true)
    ]

    private var filteredStocks: [SampleStock] {
        if searchText.isEmpty {
            return sampleStocks
        } else {
            return sampleStocks.filter {
                $0.symbol.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.sector.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Stock list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredStocks, id: \.id) { stock in
                            StockPickerRowView(
                                stock: stock,
                                isSelected: selectedStocks.contains(stock.id),
                                onToggle: {
                                    if selectedStocks.contains(stock.id) {
                                        selectedStocks.remove(stock.id)
                                    } else {
                                        selectedStocks.insert(stock.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                // Add selected stocks button
                if !selectedStocks.isEmpty {
                    addSelectedButton
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Select Stocks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }

                if !selectedStocks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            selectedStocks.removeAll()
                        }
                        .foregroundColor(.primaryPurple)
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textSecondary)

                TextField("Search stocks, ETFs, or sectors", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())

                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption1)
                    .foregroundColor(.primaryPurple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()
        }
        .background(Color.backgroundCard)
    }

    private var addSelectedButton: some View {
        VStack(spacing: 0) {
            Divider()

            ForsaButton(
                "Add \(selectedStocks.count) Stock\(selectedStocks.count == 1 ? "" : "s")",
                style: .primary,
                size: .large
            ) {
                addSelectedStocks()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.backgroundCard)
        }
    }

    private func addSelectedStocks() {
        let selectedStockData = sampleStocks.filter { selectedStocks.contains($0.id) }

        // Prevent division by zero crash
        guard !selectedStockData.isEmpty else {
            dismiss()
            return
        }

        let allocations = selectedStockData.enumerated().map { index, stock in
            let basePercentage = 100.0 / Double(selectedStockData.count)
            let adjustedPercentage = index == 0 ? 100.0 - basePercentage * Double(selectedStockData.count - 1) : basePercentage

            return PieAllocation(
                stockId: stock.id,
                symbol: stock.symbol,
                name: stock.name,
                percentage: adjustedPercentage
            )
        }

        viewModel.setCustomPieAllocations(allocations)
        dismiss()
    }
}

struct SampleStock {
    let id = UUID()
    let symbol: String
    let name: String
    let sector: String
    let price: Double
    let change: Double
    let isHalal: Bool
}

struct StockPickerRowView: View {
    let stock: SampleStock
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            ForsaCard(shadowStyle: isSelected ? .medium : .light) {
                HStack(spacing: 12) {
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .primaryPurple : .borderPrimary)

                    // Stock info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(stock.symbol)
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)

                            if stock.isHalal {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundColor(.halalGreen)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$\(String(format: "%.2f", stock.price))")
                                    .font(.calloutMedium)
                                    .foregroundColor(.textPrimary)

                                HStack(spacing: 2) {
                                    Image(systemName: stock.change >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.caption2)

                                    Text("\(String(format: "%.1f", abs(stock.change)))%")
                                        .font(.caption1)
                                }
                                .foregroundColor(stock.change >= 0 ? .gainGreen : .lossRed)
                            }
                        }

                        HStack {
                            Text(stock.name)
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)

                            Spacer()

                            Text(stock.sector)
                                .font(.caption2)
                                .foregroundColor(.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.backgroundSecondary)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primaryPurple : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    StockPickerView(viewModel: InvestmentFlowViewModel())
}