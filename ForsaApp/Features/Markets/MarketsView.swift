//
//  MarketsView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct MarketsView: View {
    @StateObject private var viewModel = MarketsViewModel()
    @State private var searchText = ""
    @State private var selectedSegment = 0

    private let segments = ["Stocks", "ETFs"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                headerView

                // Market selector tabs
                segmentedControlView

                // Market filters
                if viewModel.selectedAssetType == .stock {
                    marketFiltersView
                }

                // Stock/ETF list
                stockListView
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Markets")
                    .font(.title1)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                }
            }

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textTertiary)

                TextField("Search stocks & ETFs", text: $searchText)
                    .font(.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { newValue in
                        viewModel.searchStocks(newValue)
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var segmentedControlView: some View {
        HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                Button(action: {
                    selectedSegment = index
                    viewModel.selectedAssetType = index == 0 ? .stock : .etf
                }) {
                    Text(segment)
                        .font(.calloutMedium)
                        .foregroundColor(selectedSegment == index ? .white : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedSegment == index ? Color.primaryPurple : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var marketFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All Markets",
                    isSelected: viewModel.selectedMarket == nil
                ) {
                    viewModel.selectedMarket = nil
                }

                ForEach(Market.allCases, id: \.self) { market in
                    FilterChip(
                        title: market.rawValue,
                        isSelected: viewModel.selectedMarket == market
                    ) {
                        viewModel.selectedMarket = market
                    }
                }

                FilterChip(
                    title: "Halal Only",
                    isSelected: viewModel.showHalalOnly,
                    style: .halal
                ) {
                    viewModel.showHalalOnly.toggle()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
    }

    private var stockListView: some View {
        List {
            ForEach(viewModel.filteredStocks) { stock in
                NavigationLink(destination: StockDetailView(stock: stock)) {
                    StockRowView(stock: stock) {
                        viewModel.toggleWatchlist(stock)
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshData()
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let style: FilterChipStyle
    let action: () -> Void

    init(title: String, isSelected: Bool, style: FilterChipStyle = .normal, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if style == .halal {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption1)
                        .foregroundColor(isSelected ? .white : .halalGreen)
                }

                Text(title)
                    .font(.caption1Medium)
                    .foregroundColor(isSelected ? .white : (style == .halal ? .halalGreen : .textSecondary))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                (style == .halal ? Color.halalGreen : Color.primaryPurple) :
                (style == .halal ? Color.halalBackground : Color.backgroundSecondary)
            )
            .cornerRadius(20)
        }
    }
}

enum FilterChipStyle {
    case normal
    case halal
}

struct StockRowView: View {
    let stock: Stock
    let onWatchlistToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Stock logo
            Circle()
                .fill(Color.primaryPurple.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(stock.symbol.prefix(2)))
                        .font(.calloutMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryPurple)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(stock.symbol)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    HalalBadge(stock.shariaCompliance, size: .small)

                    Spacer(minLength: 0)
                }

                Text(stock.name)
                    .font(.footnote)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)

                if let sector = stock.sector {
                    Text(sector)
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(stock.formattedPrice)")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundColor(stock.isPositive ? .gainGreen : .lossRed)

                    Text(stock.formattedChangePercentage)
                        .font(.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(stock.isPositive ? .gainGreen : .lossRed)
                }

                if let marketCap = stock.marketCap {
                    Text("MC: \(stock.formattedMarketCap)")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }

            Button(action: onWatchlistToggle) {
                Image(systemName: stock.isWatchlisted ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(stock.isWatchlisted ? .primaryPurple : .textTertiary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .shadow(color: .shadowLight, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Stock Detail View
struct StockDetailView: View {
    let stock: Stock
    @StateObject private var viewModel = StockDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                stockHeaderView

                // Price Chart
                priceChartView

                // Key Stats
                keyStatsView

                // About
                aboutSectionView

                // Action Buttons
                actionButtonsView
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadStockData(stock)
        }
    }

    private var stockHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text(stock.symbol)
                            .font(.title1)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        HalalBadge(stock.shariaCompliance, size: .medium)
                    }

                    Text(stock.name)
                        .font(.body)
                        .foregroundColor(.textSecondary)

                    if let sector = stock.sector {
                        Text(sector)
                            .font(.callout)
                            .foregroundColor(.textTertiary)
                    }
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: stock.isWatchlisted ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundColor(stock.isWatchlisted ? .primaryPurple : .textTertiary)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(stock.formattedPrice)")
                        .font(.priceXLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.callout)
                            .foregroundColor(stock.isPositive ? .gainGreen : .lossRed)

                        Text("\(stock.formattedChange) (\(stock.formattedChangePercentage))")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(stock.isPositive ? .gainGreen : .lossRed)

                        Text("today")
                            .font(.callout)
                            .foregroundColor(.textTertiary)
                    }
                }

                Spacer()
            }
        }
    }

    private var priceChartView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Price Chart")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                // Placeholder chart
                Rectangle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        Text("Interactive Price Chart")
                            .font(.callout)
                            .foregroundColor(.textTertiary)
                    )
            }
        }
    }

    private var keyStatsView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Key Statistics")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    if let marketCap = stock.marketCap {
                        StatRowView(title: "Market Cap", value: stock.formattedMarketCap)
                    }

                    if let peRatio = stock.peRatio {
                        StatRowView(title: "P/E Ratio", value: String(format: "%.1f", peRatio))
                    }

                    if let dividendYield = stock.dividendYield {
                        StatRowView(title: "Dividend Yield", value: "\(String(format: "%.1f", dividendYield))%")
                    }

                    StatRowView(title: "Volume", value: "\(stock.volume / 1000)K")

                    if let week52High = stock.week52High {
                        StatRowView(title: "52W High", value: "$\(String(format: "%.2f", week52High))")
                    }

                    if let week52Low = stock.week52Low {
                        StatRowView(title: "52W Low", value: "$\(String(format: "%.2f", week52Low))")
                    }
                }
            }
        }
    }

    private var aboutSectionView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("About")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                if let description = stock.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .lineLimit(nil)
                }

                if stock.shariaCompliance == .compliant {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.halalGreen)

                        Text("This investment has been verified as Sharia-compliant by our Islamic finance scholars.")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(12)
                    .background(Color.halalBackground)
                    .cornerRadius(8)
                }
            }
        }
    }

    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForsaButton("Buy", style: .primary, size: .large) {
                    // Handle buy action
                }

                ForsaButton("Add to Pie", style: .outline, size: .large) {
                    // Handle add to pie action
                }
            }

            ForsaButton("Add to Watchlist", style: .tertiary, size: .medium) {
                // Handle watchlist action
            }
        }
    }
}

struct StatRowView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption1)
                .foregroundColor(.textTertiary)

            Text(value)
                .font(.calloutMedium)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    MarketsView()
}