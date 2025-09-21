//
//  ZakatViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

class ZakatViewModel: ObservableObject {
    @Published var calculation = ZakatCalculation()
    @Published var zakatHistory: [ZakatPayment] = []
    @Published var portfolioValue: Double = 0
    @Published var showingAddAsset = false
    @Published var showingAddDebt = false
    @Published var showingPaymentSheet = false
    @Published var selectedCategory: AssetCategory = .cash
    @Published var editingAsset: ZakatAsset?

    private let currentHijriYear = "1445" // This should be calculated dynamically

    init() {
        loadDemoData()
    }

    func loadCurrentCalculation() {
        // In a real app, this would load from persistent storage
        loadDemoData()
    }

    func loadDemoData() {
        // Mock portfolio value
        portfolioValue = 25420.50

        // Mock assets
        let demoAssets = [
            ZakatAsset(category: .cash, name: "Checking Account", value: 5000.00),
            ZakatAsset(category: .savings, name: "Savings Account", value: 15000.00),
            ZakatAsset(category: .gold, name: "Gold Jewelry", value: 3000.00),
            ZakatAsset(category: .investments, name: "Stock Portfolio", value: 25420.50)
        ]

        let demoDebts = [
            ZakatDebt(name: "Credit Card", amount: 2500.00, dueDate: Date().addingTimeInterval(60*60*24*30)),
            ZakatDebt(name: "Personal Loan", amount: 5000.00, dueDate: Date().addingTimeInterval(60*60*24*90))
        ]

        let demoPayments = [
            ZakatPayment(amount: 1205.52, hijriYear: "1444", recipient: "Local Islamic Center"),
            ZakatPayment(amount: 987.30, hijriYear: "1443", recipient: "Charity Organization")
        ]

        calculation = ZakatCalculation(
            assets: demoAssets,
            debts: demoDebts,
            hijriYear: currentHijriYear
        )

        zakatHistory = demoPayments
    }

    func importPortfolioAssets() {
        // In a real app, this would fetch actual portfolio data
        let portfolioAsset = ZakatAsset(
            category: .investments,
            name: "Investment Portfolio",
            value: portfolioValue
        )

        // Check if portfolio asset already exists
        if let index = calculation.assets.firstIndex(where: { $0.category == .investments && $0.name == "Investment Portfolio" }) {
            var updatedAssets = calculation.assets
            updatedAssets[index] = portfolioAsset
            updateCalculation(assets: updatedAssets)
        } else {
            var updatedAssets = calculation.assets
            updatedAssets.append(portfolioAsset)
            updateCalculation(assets: updatedAssets)
        }
    }

    func includePortfolioInCalculation() {
        importPortfolioAssets()
    }

    func addAsset(category: AssetCategory, name: String, value: Double) {
        let newAsset = ZakatAsset(category: category, name: name, value: value)
        var updatedAssets = calculation.assets
        updatedAssets.append(newAsset)
        updateCalculation(assets: updatedAssets)
    }

    func updateAsset(_ asset: ZakatAsset, name: String, value: Double) {
        guard let index = calculation.assets.firstIndex(where: { $0.id == asset.id }) else { return }

        let updatedAsset = ZakatAsset(
            id: asset.id,
            category: asset.category,
            name: name,
            value: value
        )

        var updatedAssets = calculation.assets
        updatedAssets[index] = updatedAsset
        updateCalculation(assets: updatedAssets)
    }

    func removeAsset(_ asset: ZakatAsset) {
        let updatedAssets = calculation.assets.filter { $0.id != asset.id }
        updateCalculation(assets: updatedAssets)
    }

    func addDebt(name: String, amount: Double, dueDate: Date?) {
        let newDebt = ZakatDebt(name: name, amount: amount, dueDate: dueDate)
        var updatedDebts = calculation.debts
        updatedDebts.append(newDebt)
        updateCalculation(debts: updatedDebts)
    }

    func removeDebt(_ debt: ZakatDebt) {
        let updatedDebts = calculation.debts.filter { $0.id != debt.id }
        updateCalculation(debts: updatedDebts)
    }

    func recordPayment(amount: Double, recipient: String?, paymentMethod: String?, notes: String?) {
        let payment = ZakatPayment(
            amount: amount,
            hijriYear: currentHijriYear,
            recipient: recipient,
            paymentMethod: paymentMethod,
            notes: notes,
            calculationId: calculation.calculationDate.timeIntervalSince1970.hashValue
        )

        zakatHistory.insert(payment, at: 0)
        showingPaymentSheet = false

        // In a real app, this would save to persistent storage
    }

    func exportCalculation() {
        // In a real app, this would generate a PDF or export data
        print("Exporting Zakat calculation...")
    }

    func getAssets(for category: AssetCategory) -> [ZakatAsset] {
        return calculation.assets.filter { $0.category == category }
    }

    private func updateCalculation(assets: [ZakatAsset]? = nil, debts: [ZakatDebt]? = nil) {
        calculation = ZakatCalculation(
            assets: assets ?? calculation.assets,
            debts: debts ?? calculation.debts,
            calculationDate: Date(),
            hijriYear: currentHijriYear,
            goldPricePerOunce: calculation.goldPricePerOunce,
            silverPricePerOunce: calculation.silverPricePerOunce
        )
    }
}