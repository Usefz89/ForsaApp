//
//  Transaction.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

enum TransactionType: String, CaseIterable, Codable {
    case buy = "buy"
    case sell = "sell"
    case dividend = "dividend"
    case deposit = "deposit"
    case withdrawal = "withdrawal"
    case fee = "fee"

    var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .dividend: return "Dividend"
        case .deposit: return "Deposit"
        case .withdrawal: return "Withdrawal"
        case .fee: return "Fee"
        }
    }

    var isPositive: Bool {
        switch self {
        case .buy, .dividend, .deposit:
            return true
        case .sell, .withdrawal, .fee:
            return false
        }
    }
}

enum TransactionStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case executed = "executed"
    case cancelled = "cancelled"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .executed: return "Executed"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        }
    }
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    let type: TransactionType
    let status: TransactionStatus
    let stockId: UUID?
    let symbol: String?
    let stockName: String?
    let shares: Double?
    let pricePerShare: Double?
    let totalAmount: Double
    let fees: Double
    let netAmount: Double
    let executedAt: Date
    let createdAt: Date
    let note: String?

    var formattedAmount: String {
        let sign = type.isPositive ? "+" : "-"
        return "\(sign)$\(String(format: "%.2f", abs(totalAmount)))"
    }

    var formattedNetAmount: String {
        let sign = type.isPositive ? "+" : "-"
        return "\(sign)$\(String(format: "%.2f", abs(netAmount)))"
    }

    var formattedShares: String {
        guard let shares = shares else { return "N/A" }
        return String(format: "%.4f", shares)
    }

    var formattedPricePerShare: String {
        guard let pricePerShare = pricePerShare else { return "N/A" }
        return "$\(String(format: "%.2f", pricePerShare))"
    }

    init(id: UUID = UUID(), type: TransactionType, status: TransactionStatus = .executed, stockId: UUID? = nil, symbol: String? = nil, stockName: String? = nil, shares: Double? = nil, pricePerShare: Double? = nil, totalAmount: Double, fees: Double = 0, executedAt: Date = Date(), createdAt: Date = Date(), note: String? = nil) {
        self.id = id
        self.type = type
        self.status = status
        self.stockId = stockId
        self.symbol = symbol
        self.stockName = stockName
        self.shares = shares
        self.pricePerShare = pricePerShare
        self.totalAmount = totalAmount
        self.fees = fees
        self.netAmount = totalAmount - fees
        self.executedAt = executedAt
        self.createdAt = createdAt
        self.note = note
    }
}

enum OrderType: String, CaseIterable, Codable {
    case market = "market"
    case limit = "limit"
    case stopLoss = "stop_loss"
    case stopLimit = "stop_limit"

    var displayName: String {
        switch self {
        case .market: return "Market"
        case .limit: return "Limit"
        case .stopLoss: return "Stop Loss"
        case .stopLimit: return "Stop Limit"
        }
    }
}

enum OrderSide: String, CaseIterable, Codable {
    case buy = "buy"
    case sell = "sell"

    var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
}

enum OrderStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case partiallyFilled = "partially_filled"
    case filled = "filled"
    case cancelled = "cancelled"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .partiallyFilled: return "Partially Filled"
        case .filled: return "Filled"
        case .cancelled: return "Cancelled"
        case .rejected: return "Rejected"
        }
    }
}

struct Order: Identifiable, Codable {
    let id: UUID
    let stockId: UUID
    let symbol: String
    let stockName: String
    let side: OrderSide
    let type: OrderType
    let status: OrderStatus
    let quantity: Double
    let filledQuantity: Double
    let price: Double?
    let stopPrice: Double?
    let limitPrice: Double?
    let totalValue: Double
    let fees: Double
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date?

    var remainingQuantity: Double {
        quantity - filledQuantity
    }

    var fillPercentage: Double {
        quantity > 0 ? (filledQuantity / quantity) * 100 : 0
    }

    var formattedPrice: String {
        guard let price = price else { return "Market" }
        return "$\(String(format: "%.2f", price))"
    }

    var formattedTotalValue: String {
        "$\(String(format: "%.2f", totalValue))"
    }

    var formattedQuantity: String {
        String(format: "%.4f", quantity)
    }

    init(id: UUID = UUID(), stockId: UUID, symbol: String, stockName: String, side: OrderSide, type: OrderType, status: OrderStatus = .pending, quantity: Double, filledQuantity: Double = 0, price: Double? = nil, stopPrice: Double? = nil, limitPrice: Double? = nil, fees: Double = 0, createdAt: Date = Date(), updatedAt: Date = Date(), expiresAt: Date? = nil) {
        self.id = id
        self.stockId = stockId
        self.symbol = symbol
        self.stockName = stockName
        self.side = side
        self.type = type
        self.status = status
        self.quantity = quantity
        self.filledQuantity = filledQuantity
        self.price = price
        self.stopPrice = stopPrice
        self.limitPrice = limitPrice
        self.totalValue = (price ?? 0) * quantity
        self.fees = fees
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
    }
}