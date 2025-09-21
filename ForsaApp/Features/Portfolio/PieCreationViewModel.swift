//
//  PieCreationViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

class PieCreationViewModel: ObservableObject {
    @Published var pieName = ""
    @Published var pieDescription = ""
    @Published var selectedStocks: [PieAllocation] = []
    @Published var autoInvestEnabled = false
    @Published var autoInvestAmountText = ""
    @Published var rebalanceFrequency: RebalanceFrequency = .monthly
    @Published var showingStockPicker = false
    @Published var isCreating = false
    @Published var pieCreated = false
    @Published var currentStep = 0

    var totalAllocation: Double {
        selectedStocks.reduce(0) { $0 + $1.percentage }
    }

    var isValidAllocation: Bool {
        abs(totalAllocation - 100.0) < 0.01
    }

    var canCreatePie: Bool {
        !pieName.isEmpty && !selectedStocks.isEmpty && isValidAllocation
    }

    var autoInvestAmount: Double {
        Double(autoInvestAmountText) ?? 0
    }

    func updateAllocation(_ id: UUID, percentage: Double) {
        if let index = selectedStocks.firstIndex(where: { $0.id == id }) {
            selectedStocks[index] = PieAllocation(
                id: selectedStocks[index].id,
                stockId: selectedStocks[index].stockId,
                symbol: selectedStocks[index].symbol,
                name: selectedStocks[index].name,
                percentage: percentage,
                logoURL: selectedStocks[index].logoURL
            )
        }
    }

    func removeStock(_ id: UUID) {
        selectedStocks.removeAll { $0.id == id }
    }

    func addStock(_ stock: Stock, percentage: Double = 0) {
        let allocation = PieAllocation(
            stockId: stock.id,
            symbol: stock.symbol,
            name: stock.name,
            percentage: percentage,
            logoURL: stock.logoURL
        )
        selectedStocks.append(allocation)
    }

    @MainActor
    func createPie() async {
        isCreating = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let pie = InvestmentPie(
            name: pieName,
            description: pieDescription.isEmpty ? nil : pieDescription,
            allocations: selectedStocks,
            totalInvested: 0,
            autoInvestEnabled: autoInvestEnabled,
            autoInvestAmount: autoInvestEnabled ? autoInvestAmount : nil,
            rebalanceFrequency: rebalanceFrequency
        )

        // In a real app, this would save to backend
        print("Created pie: \(pie.name)")

        pieCreated = true
        isCreating = false
    }

    func resetPie() {
        pieName = ""
        pieDescription = ""
        selectedStocks = []
        autoInvestEnabled = false
        autoInvestAmountText = ""
        rebalanceFrequency = .monthly
        currentStep = 0
        pieCreated = false
    }
}