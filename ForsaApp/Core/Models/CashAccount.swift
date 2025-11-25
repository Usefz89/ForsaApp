//
//  CashAccount.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import Foundation

struct CashAccount: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let balance: Double
    let currency: String
    let dailyDepositLimit: Double
    let monthlyDepositLimit: Double
    let totalDeposited: Double
    let totalWithdrawn: Double
    let kycStatus: KYCStatus
    let verificationLevel: VerificationLevel
    let createdAt: Date
    let updatedAt: Date

    var availableDailyLimit: Double {
        dailyDepositLimit - todaysDeposits
    }

    var availableMonthlyLimit: Double {
        monthlyDepositLimit - thisMonthsDeposits
    }

    var formattedBalance: String {
        if currency == "USD" {
            return "$\(String(format: "%.2f", balance))"
        }
        return "KWD \(String(format: "%.3f", balance))"
    }

    var todaysDeposits: Double {
        // Mock calculation - in real app would query transactions
        250.0
    }

    var thisMonthsDeposits: Double {
        // Mock calculation - in real app would query transactions
        2150.0
    }

    init(id: UUID = UUID(), userId: UUID, balance: Double = 0, currency: String = "KWD", dailyDepositLimit: Double = 10000, monthlyDepositLimit: Double = 50000, totalDeposited: Double = 0, totalWithdrawn: Double = 0, kycStatus: KYCStatus = .verified, verificationLevel: VerificationLevel = .full, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.balance = balance
        self.currency = currency
        self.dailyDepositLimit = dailyDepositLimit
        self.monthlyDepositLimit = monthlyDepositLimit
        self.totalDeposited = totalDeposited
        self.totalWithdrawn = totalWithdrawn
        self.kycStatus = kycStatus
        self.verificationLevel = verificationLevel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct DepositTransaction: Identifiable, Codable {
    let id: UUID
    let accountId: UUID
    let amount: Double
    let currency: String
    let paymentMethod: PaymentMethod
    let status: DepositStatus
    let referenceNumber: String
    let processingFee: Double
    let netAmount: Double
    let estimatedSettlementTime: String
    let createdAt: Date
    let completedAt: Date?

    var formattedAmount: String {
        if currency == "USD" {
            return "$\(String(format: "%.2f", amount))"
        }
        return "KWD \(String(format: "%.3f", amount))"
    }

    var formattedNetAmount: String {
        if currency == "USD" {
            return "$\(String(format: "%.2f", netAmount))"
        }
        return "KWD \(String(format: "%.3f", netAmount))"
    }

    var formattedFee: String {
        if currency == "USD" {
            return "$\(String(format: "%.2f", processingFee))"
        }
        return "KWD \(String(format: "%.3f", processingFee))"
    }

    init(id: UUID = UUID(), accountId: UUID, amount: Double, currency: String = "KWD", paymentMethod: PaymentMethod, processingFee: Double = 0, estimatedSettlementTime: String, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.accountId = accountId
        self.amount = amount
        self.currency = currency
        self.paymentMethod = paymentMethod
        self.status = .processing
        self.referenceNumber = "FUL-\(Int.random(in: 100000...999999))"
        self.processingFee = processingFee
        self.netAmount = amount - processingFee
        self.estimatedSettlementTime = estimatedSettlementTime
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

enum PaymentMethod: String, CaseIterable, Codable {
    case knet = "knet"
    case wireTransfer = "wire_transfer"
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case cryptocurrency = "cryptocurrency"

    var displayName: String {
        switch self {
        case .knet: return "KNET (Kuwaiti Banks)"
        case .wireTransfer: return "International Wire Transfer"
        case .creditCard: return "Credit/Debit Card"
        case .debitCard: return "Debit Card"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .cryptocurrency: return "Cryptocurrency"
        }
    }

    var subtitle: String {
        switch self {
        case .knet: return "Instant transfer from Kuwaiti banks"
        case .wireTransfer: return "Bank transfer from international accounts"
        case .creditCard: return "Visa, Mastercard, or local credit cards"
        case .debitCard: return "Direct debit from your bank account"
        case .applePay: return "Quick and secure mobile payment"
        case .googlePay: return "Fast mobile payment solution"
        case .cryptocurrency: return "USDC/USDT conversion"
        }
    }

    var processingTime: String {
        switch self {
        case .knet: return "Instant"
        case .wireTransfer: return "1-3 business days"
        case .creditCard: return "Instant"
        case .debitCard: return "Instant"
        case .applePay: return "Instant"
        case .googlePay: return "Instant"
        case .cryptocurrency: return "10-30 minutes"
        }
    }

    var processingFeePercentage: Double {
        switch self {
        case .knet: return 0.0
        case .wireTransfer: return 1.5
        case .creditCard: return 2.9
        case .debitCard: return 1.0
        case .applePay: return 0.0
        case .googlePay: return 0.0
        case .cryptocurrency: return 1.2
        }
    }

    var iconName: String {
        switch self {
        case .knet: return "building.columns.fill"
        case .wireTransfer: return "globe"
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        case .applePay: return "apple.logo"
        case .googlePay: return "g.circle.fill"
        case .cryptocurrency: return "bitcoinsign.circle.fill"
        }
    }

    var isRecommended: Bool {
        self == .knet
    }

    var isInstant: Bool {
        [.knet, .creditCard, .debitCard, .applePay, .googlePay].contains(self)
    }
}

enum DepositStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .pending: return "warningYellow"
        case .processing: return "infoBlue"
        case .completed: return "successGreen"
        case .failed: return "errorRed"
        case .cancelled: return "textMuted"
        }
    }
}

enum KYCStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inReview = "in_review"
    case verified = "verified"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .pending: return "Pending Verification"
        case .inReview: return "Under Review"
        case .verified: return "Verified"
        case .rejected: return "Verification Failed"
        }
    }

    var isCompliant: Bool {
        self == .verified
    }
}

enum VerificationLevel: String, CaseIterable, Codable {
    case basic = "basic"
    case full = "full"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .full: return "Full"
        case .premium: return "Premium"
        }
    }

    var maxDailyDeposit: Double {
        switch self {
        case .basic: return 1000
        case .full: return 10000
        case .premium: return 50000
        }
    }

    var maxMonthlyDeposit: Double {
        switch self {
        case .basic: return 5000
        case .full: return 50000
        case .premium: return 200000
        }
    }
}