//
//  OrderModels.swift
//  ForsaApp
//
//  Order state management for tracking pending/open orders
//  This helps the app understand when funds are allocated but not yet invested
//

import Foundation

// MARK: - Order Status

/// Represents the current state of an order in the Alpaca system
enum AlpacaOrderStatus: String, Codable, CaseIterable {
    case new = "new"
    case partiallyFilled = "partially_filled"
    case filled = "filled"
    case doneForDay = "done_for_day"
    case canceled = "canceled"
    case expired = "expired"
    case replaced = "replaced"
    case pendingCancel = "pending_cancel"
    case pendingReplace = "pending_replace"
    case pendingNew = "pending_new"
    case accepted = "accepted"
    case acceptedForBidding = "accepted_for_bidding"
    case stopped = "stopped"
    case rejected = "rejected"
    case suspended = "suspended"
    case calculated = "calculated"
    case held = "held"
    
    /// Whether this order is still pending execution
    var isPending: Bool {
        switch self {
        case .new, .partiallyFilled, .pendingNew, .accepted, .acceptedForBidding, .held, .suspended:
            return true
        default:
            return false
        }
    }
    
    /// Whether this order is fully completed (filled or cancelled)
    var isComplete: Bool {
        switch self {
        case .filled, .canceled, .expired, .rejected:
            return true
        default:
            return false
        }
    }
    
    /// Whether funds are reserved for this order
    var hasFundsReserved: Bool {
        switch self {
        case .new, .partiallyFilled, .pendingNew, .accepted, .acceptedForBidding, .held:
            return true
        default:
            return false
        }
    }
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .new: return "Pending"
        case .partiallyFilled: return "Partially Filled"
        case .filled: return "Completed"
        case .doneForDay: return "Done for Day"
        case .canceled: return "Cancelled"
        case .expired: return "Expired"
        case .replaced: return "Replaced"
        case .pendingCancel: return "Cancelling..."
        case .pendingReplace: return "Replacing..."
        case .pendingNew: return "Processing..."
        case .accepted: return "Accepted"
        case .acceptedForBidding: return "Accepted"
        case .stopped: return "Stopped"
        case .rejected: return "Rejected"
        case .suspended: return "Suspended"
        case .calculated: return "Calculated"
        case .held: return "Held"
        }
    }
    
    /// Icon for UI display
    var icon: String {
        switch self {
        case .new, .pendingNew, .accepted, .acceptedForBidding:
            return "clock.fill"
        case .partiallyFilled:
            return "circle.lefthalf.filled"
        case .filled:
            return "checkmark.circle.fill"
        case .canceled, .expired, .rejected:
            return "xmark.circle.fill"
        case .held, .suspended:
            return "pause.circle.fill"
        default:
            return "questionmark.circle"
        }
    }
    
    /// Color for UI display
    var colorName: String {
        switch self {
        case .new, .pendingNew, .accepted, .acceptedForBidding, .partiallyFilled:
            return "warningYellow"
        case .filled:
            return "successGreen"
        case .canceled, .expired, .rejected:
            return "errorRed"
        case .held, .suspended:
            return "primaryPurple"
        default:
            return "textSecondary"
        }
    }
}

// MARK: - Open Order Model

/// Represents an open/pending order from Alpaca
struct OpenOrder: Identifiable, Codable {
    let id: String
    let clientOrderId: String?
    let symbol: String
    let qty: String?
    let notional: String?
    let filledQty: String
    let filledAvgPrice: String?
    let side: String
    let type: String
    let timeInForce: String
    let status: String
    let createdAt: String
    let updatedAt: String?
    let submittedAt: String?
    let assetClass: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case symbol
        case qty
        case notional
        case filledQty = "filled_qty"
        case filledAvgPrice = "filled_avg_price"
        case side
        case type
        case timeInForce = "time_in_force"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case submittedAt = "submitted_at"
        case assetClass = "asset_class"
    }
    
    // MARK: - Computed Properties
    
    var orderStatus: AlpacaOrderStatus {
        AlpacaOrderStatus(rawValue: status.lowercased()) ?? .new
    }
    
    var isPending: Bool {
        orderStatus.isPending
    }
    
    var hasFundsReserved: Bool {
        orderStatus.hasFundsReserved
    }
    
    var notionalValue: Double {
        Double(notional ?? "0") ?? 0
    }
    
    var filledQtyValue: Double {
        Double(filledQty) ?? 0
    }
    
    var requestedQtyValue: Double? {
        guard let qty = qty else { return nil }
        return Double(qty)
    }
    
    var isBuyOrder: Bool {
        side.lowercased() == "buy"
    }
    
    var createdDate: Date? {
        ISO8601DateFormatter().date(from: createdAt)
    }
    
    var displayAmount: String {
        if let notional = notional, let value = Double(notional) {
            return String(format: "$%.2f", value)
        } else if let qty = qty {
            return "\(qty) shares"
        }
        return "—"
    }
    
    var statusDisplayName: String {
        orderStatus.displayName
    }
    
    var statusIcon: String {
        orderStatus.icon
    }
    
    var statusColor: String {
        orderStatus.colorName
    }
}

// MARK: - Order Summary

/// Summary of pending orders for UI display
struct PendingOrdersSummary {
    let orders: [OpenOrder]
    let totalPendingAmount: Double
    let pendingSymbols: [String]
    
    var hasPendingOrders: Bool {
        !orders.isEmpty
    }
    
    var pendingCount: Int {
        orders.count
    }
    
    var formattedTotalAmount: String {
        String(format: "$%.2f", totalPendingAmount)
    }
    
    var statusMessage: String {
        if orders.isEmpty {
            return "No pending orders"
        } else if orders.count == 1 {
            return "1 order waiting for market to open"
        } else {
            return "\(orders.count) orders waiting for market to open"
        }
    }
    
    static let empty = PendingOrdersSummary(orders: [], totalPendingAmount: 0, pendingSymbols: [])
    
    init(orders: [OpenOrder]) {
        self.orders = orders.filter { $0.hasFundsReserved }
        self.totalPendingAmount = self.orders.reduce(0) { $0 + $1.notionalValue }
        self.pendingSymbols = self.orders.map { $0.symbol }
    }
    
    init(orders: [OpenOrder], totalPendingAmount: Double, pendingSymbols: [String]) {
        self.orders = orders
        self.totalPendingAmount = totalPendingAmount
        self.pendingSymbols = pendingSymbols
    }
}

// MARK: - Investment State

/// Represents the current state of the user's investment capability
enum InvestmentState {
    case canInvest(availableAmount: Double)
    case ordersPending(summary: PendingOrdersSummary)
    case insufficientFunds
    case noPortfolioSelected
    case accountNotReady
    
    var canPlaceNewOrders: Bool {
        switch self {
        case .canInvest:
            return true
        default:
            return false
        }
    }
    
    var displayMessage: String {
        switch self {
        case .canInvest(let amount):
            return "Ready to invest \(String(format: "$%.2f", amount))"
        case .ordersPending(let summary):
            return summary.statusMessage
        case .insufficientFunds:
            return "Add funds to start investing"
        case .noPortfolioSelected:
            return "Select a portfolio to invest"
        case .accountNotReady:
            return "Complete account setup to invest"
        }
    }
    
    var icon: String {
        switch self {
        case .canInvest:
            return "checkmark.circle.fill"
        case .ordersPending:
            return "clock.fill"
        case .insufficientFunds:
            return "dollarsign.circle"
        case .noPortfolioSelected:
            return "chart.pie"
        case .accountNotReady:
            return "person.badge.clock"
        }
    }
    
    var iconColor: String {
        switch self {
        case .canInvest:
            return "successGreen"
        case .ordersPending:
            return "warningYellow"
        case .insufficientFunds, .noPortfolioSelected, .accountNotReady:
            return "textSecondary"
        }
    }
}



