//
//  Stock.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

enum AssetType: String, CaseIterable, Codable {
    case stock = "stock"
    case etf = "etf"
    case crypto = "crypto"
    case commodity = "commodity"
}

enum Market: String, CaseIterable, Codable {
    case kse = "KSE" // Kuwait Stock Exchange
    case tadawul = "TADAWUL" // Saudi Stock Exchange
    case adx = "ADX" // Abu Dhabi Securities Exchange
    case dfm = "DFM" // Dubai Financial Market
    case nasdaq = "NASDAQ"
    case nyse = "NYSE"
    case lse = "LSE" // London Stock Exchange
}

enum ShariaCompliance: String, CaseIterable, Codable {
    case compliant = "compliant"
    case nonCompliant = "non_compliant"
    case underReview = "under_review"
}

struct Stock: Identifiable, Codable, Hashable {
    let id: UUID
    let symbol: String
    let name: String
    let market: Market
    let assetType: AssetType
    let currentPrice: Double
    let previousClose: Double
    let dayChange: Double
    let dayChangePercentage: Double
    let marketCap: Double?
    let volume: Int
    let logoURL: String?
    let sector: String?
    let industry: String?
    let description: String?
    let shariaCompliance: ShariaCompliance
    let currency: String
    let isWatchlisted: Bool
    let dividendYield: Double?
    let peRatio: Double?
    let week52High: Double?
    let week52Low: Double?

    var isPositive: Bool {
        dayChange >= 0
    }

    var formattedPrice: String {
        String(format: "%.2f", currentPrice)
    }

    var formattedChange: String {
        let sign = dayChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", dayChange))"
    }

    var formattedChangePercentage: String {
        let sign = dayChangePercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", dayChangePercentage))%"
    }

    var formattedMarketCap: String {
        guard let marketCap = marketCap else { return "N/A" }

        if marketCap >= 1_000_000_000 {
            return String(format: "%.1fB", marketCap / 1_000_000_000)
        } else if marketCap >= 1_000_000 {
            return String(format: "%.1fM", marketCap / 1_000_000)
        } else {
            return String(format: "%.0f", marketCap)
        }
    }

    init(id: UUID = UUID(), symbol: String, name: String, market: Market, assetType: AssetType, currentPrice: Double, previousClose: Double, marketCap: Double? = nil, volume: Int, logoURL: String? = nil, sector: String? = nil, industry: String? = nil, description: String? = nil, shariaCompliance: ShariaCompliance, currency: String = "USD", isWatchlisted: Bool = false, dividendYield: Double? = nil, peRatio: Double? = nil, week52High: Double? = nil, week52Low: Double? = nil) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.market = market
        self.assetType = assetType
        self.currentPrice = currentPrice
        self.previousClose = previousClose
        self.dayChange = currentPrice - previousClose
        self.dayChangePercentage = ((currentPrice - previousClose) / previousClose) * 100
        self.marketCap = marketCap
        self.volume = volume
        self.logoURL = logoURL
        self.sector = sector
        self.industry = industry
        self.description = description
        self.shariaCompliance = shariaCompliance
        self.currency = currency
        self.isWatchlisted = isWatchlisted
        self.dividendYield = dividendYield
        self.peRatio = peRatio
        self.week52High = week52High
        self.week52Low = week52Low
    }
}

extension Stock {
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}