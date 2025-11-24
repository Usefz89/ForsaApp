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
    @Published var showingPurificationReport = false
    @Published var selectedCategory: AssetCategory = .cash
    @Published var editingAsset: ZakatAsset?

    private let currentHijriYear = "1445" // This should be calculated dynamically

    init() {
        loadData()
    }

    func loadCurrentCalculation() {
        loadData()
    }

    func loadData() {
        // Simulate fetching user's portfolio value
        // In a real app, this would come from a PortfolioService or UserSession
        if let user = MockDataService.shared.demoUsers.first {
            portfolioValue = user.totalPortfolioValue
        }

        // Initialize calculation with default values if empty
        if calculation.assets.isEmpty {
            calculation = ZakatCalculation(
                assets: [],
                debts: [],
                hijriYear: currentHijriYear
            )
        }
    }

    func importPortfolioAssets() {
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
            calculationId: UUID()
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