//
//  ZakatModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

enum AssetCategory: String, CaseIterable, Codable {
    case cash = "cash"
    case savings = "savings"
    case investments = "investments"
    case gold = "gold"
    case silver = "silver"
    case business = "business"
    case crypto = "crypto"
    case other = "other"

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .savings: return "Savings"
        case .investments: return "Investments"
        case .gold: return "Gold"
        case .silver: return "Silver"
        case .business: return "Business Assets"
        case .crypto: return "Cryptocurrency"
        case .other: return "Other Assets"
        }
    }

    var description: String {
        switch self {
        case .cash:
            return "Physical cash and money in checking accounts"
        case .savings:
            return "Money in savings accounts and term deposits"
        case .investments:
            return "Stocks, bonds, mutual funds, and other securities"
        case .gold:
            return "Gold jewelry, coins, and bullion"
        case .silver:
            return "Silver jewelry, coins, and bullion"
        case .business:
            return "Business inventory, equipment, and trade goods"
        case .crypto:
            return "Bitcoin, Ethereum, and other cryptocurrencies"
        case .other:
            return "Other zakatable assets"
        }
    }

    var zakatRate: Double {
        // All categories use 2.5% rate
        return 0.025
    }
}

struct ZakatAsset: Identifiable, Codable {
    let id: UUID
    let category: AssetCategory
    let name: String
    let value: Double
    let currency: String
    let lastUpdated: Date

    var formattedValue: String {
        "$\(String(format: "%.2f", value))"
    }

    init(id: UUID = UUID(), category: AssetCategory, name: String, value: Double, currency: String = "USD", lastUpdated: Date = Date()) {
        self.id = id
        self.category = category
        self.name = name
        self.value = value
        self.currency = currency
        self.lastUpdated = lastUpdated
    }
}

struct ZakatDebt: Identifiable, Codable {
    let id: UUID
    let name: String
    let amount: Double
    let currency: String
    let dueDate: Date?
    let isDeductible: Bool

    var formattedAmount: String {
        "$\(String(format: "%.2f", amount))"
    }

    init(id: UUID = UUID(), name: String, amount: Double, currency: String = "USD", dueDate: Date? = nil, isDeductible: Bool = true) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.dueDate = dueDate
        self.isDeductible = isDeductible
    }
}

struct ZakatCalculation: Codable {
    let assets: [ZakatAsset]
    let debts: [ZakatDebt]
    let calculationDate: Date
    let hijriYear: String
    let nisabThreshold: Double
    let goldPricePerOunce: Double
    let silverPricePerOunce: Double

    var totalAssets: Double {
        assets.reduce(0) { $0 + $1.value }
    }

    var totalDeductibleDebts: Double {
        debts.filter { $0.isDeductible }.reduce(0) { $0 + $1.amount }
    }

    var netWorth: Double {
        totalAssets - totalDeductibleDebts
    }

    var isNisabMet: Bool {
        netWorth >= nisabThreshold
    }

    var zakatDue: Double {
        guard isNisabMet else { return 0 }
        return netWorth * 0.025 // 2.5% zakat rate
    }

    var formattedTotalAssets: String {
        "$\(String(format: "%.2f", totalAssets))"
    }

    var formattedTotalDebts: String {
        "$\(String(format: "%.2f", totalDeductibleDebts))"
    }

    var formattedNetWorth: String {
        "$\(String(format: "%.2f", netWorth))"
    }

    var formattedZakatDue: String {
        "$\(String(format: "%.2f", zakatDue))"
    }

    var formattedNisabThreshold: String {
        "$\(String(format: "%.2f", nisabThreshold))"
    }

    // Nisab calculation based on gold (85 grams of gold)
    static func calculateNisab(goldPricePerOunce: Double) -> Double {
        let goldGramsPerOunce = 31.1035
        let nisabGoldGrams = 85.0
        let nisabOunces = nisabGoldGrams / goldGramsPerOunce
        return nisabOunces * goldPricePerOunce
    }

    init(assets: [ZakatAsset] = [], debts: [ZakatDebt] = [], calculationDate: Date = Date(), hijriYear: String = "", goldPricePerOunce: Double = 2000.0, silverPricePerOunce: Double = 25.0) {
        self.assets = assets
        self.debts = debts
        self.calculationDate = calculationDate
        self.hijriYear = hijriYear
        self.goldPricePerOunce = goldPricePerOunce
        self.silverPricePerOunce = silverPricePerOunce
        self.nisabThreshold = ZakatCalculation.calculateNisab(goldPricePerOunce: goldPricePerOunce)
    }
}

struct ZakatPayment: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let paymentDate: Date
    let hijriYear: String
    let recipient: String?
    let paymentMethod: String?
    let notes: String?
    let calculationId: UUID?

    var formattedAmount: String {
        "$\(String(format: "%.2f", amount))"
    }

    init(id: UUID = UUID(), amount: Double, paymentDate: Date = Date(), hijriYear: String, recipient: String? = nil, paymentMethod: String? = nil, notes: String? = nil, calculationId: UUID? = nil) {
        self.id = id
        self.amount = amount
        self.paymentDate = paymentDate
        self.hijriYear = hijriYear
        self.recipient = recipient
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.calculationId = calculationId
    }
}