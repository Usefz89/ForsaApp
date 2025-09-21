//
//  Portfolio.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

struct Portfolio: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let createdAt: Date
    let updatedAt: Date
    let totalValue: Double
    let totalInvested: Double
    let totalGainLoss: Double
    let totalGainLossPercentage: Double
    let holdings: [Holding]
    let isPublic: Bool
    let creatorId: UUID
    let likesCount: Int
    let copyCount: Int
    let autoInvestEnabled: Bool
    let autoInvestAmount: Double?

    var totalGainLossFormatted: String {
        let sign = totalGainLoss >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", totalGainLoss))"
    }

    var totalGainLossPercentageFormatted: String {
        let sign = totalGainLossPercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", totalGainLossPercentage))%"
    }

    var isPositive: Bool {
        totalGainLoss >= 0
    }

    init(id: UUID = UUID(), name: String, description: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), totalValue: Double = 0, totalInvested: Double = 0, holdings: [Holding] = [], isPublic: Bool = false, creatorId: UUID, likesCount: Int = 0, copyCount: Int = 0, autoInvestEnabled: Bool = false, autoInvestAmount: Double? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalValue = totalValue
        self.totalInvested = totalInvested
        self.totalGainLoss = totalValue - totalInvested
        self.totalGainLossPercentage = totalInvested > 0 ? ((totalValue - totalInvested) / totalInvested) * 100 : 0
        self.holdings = holdings
        self.isPublic = isPublic
        self.creatorId = creatorId
        self.likesCount = likesCount
        self.copyCount = copyCount
        self.autoInvestEnabled = autoInvestEnabled
        self.autoInvestAmount = autoInvestAmount
    }
}

struct Holding: Identifiable, Codable {
    let id: UUID
    let stockId: UUID
    let symbol: String
    let name: String
    let shares: Double
    let averagePrice: Double
    let currentPrice: Double
    let totalValue: Double
    let totalInvested: Double
    let gainLoss: Double
    let gainLossPercentage: Double
    let dividendsReceived: Double
    let allocation: Double // Percentage of portfolio

    var gainLossFormatted: String {
        let sign = gainLoss >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", gainLoss))"
    }

    var gainLossPercentageFormatted: String {
        let sign = gainLossPercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", gainLossPercentage))%"
    }

    var isPositive: Bool {
        gainLoss >= 0
    }

    var allocationFormatted: String {
        "\(String(format: "%.1f", allocation))%"
    }

    init(id: UUID = UUID(), stockId: UUID, symbol: String, name: String, shares: Double, averagePrice: Double, currentPrice: Double, dividendsReceived: Double = 0, allocation: Double = 0) {
        self.id = id
        self.stockId = stockId
        self.symbol = symbol
        self.name = name
        self.shares = shares
        self.averagePrice = averagePrice
        self.currentPrice = currentPrice
        self.totalValue = shares * currentPrice
        self.totalInvested = shares * averagePrice
        self.gainLoss = totalValue - totalInvested
        self.gainLossPercentage = totalInvested > 0 ? ((totalValue - totalInvested) / totalInvested) * 100 : 0
        self.dividendsReceived = dividendsReceived
        self.allocation = allocation
    }
}

struct InvestmentPie: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let allocations: [PieAllocation]
    let totalInvested: Double
    let autoInvestEnabled: Bool
    let autoInvestAmount: Double?
    let rebalanceFrequency: RebalanceFrequency
    let createdAt: Date
    let updatedAt: Date

    var isValid: Bool {
        let totalAllocation = allocations.reduce(0) { $0 + $1.percentage }
        return abs(totalAllocation - 100.0) < 0.01 // Allow for small floating point errors
    }

    init(id: UUID = UUID(), name: String, description: String? = nil, allocations: [PieAllocation] = [], totalInvested: Double = 0, autoInvestEnabled: Bool = false, autoInvestAmount: Double? = nil, rebalanceFrequency: RebalanceFrequency = .monthly, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.allocations = allocations
        self.totalInvested = totalInvested
        self.autoInvestEnabled = autoInvestEnabled
        self.autoInvestAmount = autoInvestAmount
        self.rebalanceFrequency = rebalanceFrequency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct PieAllocation: Identifiable, Codable {
    let id: UUID
    let stockId: UUID
    let symbol: String
    let name: String
    let percentage: Double
    let logoURL: String?

    init(id: UUID = UUID(), stockId: UUID, symbol: String, name: String, percentage: Double, logoURL: String? = nil) {
        self.id = id
        self.stockId = stockId
        self.symbol = symbol
        self.name = name
        self.percentage = percentage
        self.logoURL = logoURL
    }
}

enum RebalanceFrequency: String, CaseIterable, Codable {
    case never = "never"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case annually = "annually"

    var displayName: String {
        switch self {
        case .never: return "Never"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .annually: return "Annually"
        }
    }
}