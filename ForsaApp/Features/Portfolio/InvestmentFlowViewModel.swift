//
//  InvestmentFlowViewModel.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import Foundation
import SwiftUI

@MainActor
class InvestmentFlowViewModel: ObservableObject {
    // MARK: - Flow State
    @Published var currentStep: Int = 1
    @Published var isProcessing: Bool = false
    @Published var investmentCompleted: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Step 1: Pie Selection
    @Published var selectedPieType: PieSelectionType = .custom
    @Published var selectedModelPie: Portfolio?
    @Published var selectedCommunityPie: Portfolio?
    @Published var customPieAllocations: [PieAllocation] = []
    @Published var showingStockPicker: Bool = false

    // MARK: - Step 2: Investment Method
    @Published var investmentMethod: InvestmentMethod = .manual

    // MARK: - Step 3: Investment Configuration
    @Published var manualAmount: Double = 0
    @Published var initialDeposit: Double = 0
    @Published var monthlyContribution: Double = 0
    @Published var investmentDay: Int = 1
    @Published var investmentDuration: Int = 5

    // MARK: - Step 4: Value Projections
    @Published var selectedScenario: ProjectionScenario = .expected
    @Published var projections: [InvestmentProjection] = []

    // MARK: - Step 5: Name & Goals
    @Published var pieName: String = ""
    @Published var pieDescription: String = ""
    @Published var selectedGoal: InvestmentGoal?

    // MARK: - Step 6: Confirmation
    @Published var acceptTerms: Bool = false

    let maxSteps: Int = 6

    // MARK: - Mock Data
    @Published var modelPies: [Portfolio] = []
    @Published var communityPies: [Portfolio] = []
    @Published var cashAccount: CashAccount

    // MARK: - Text Bindings
    var manualAmountText: String {
        get { manualAmount > 0 ? String(format: "%.0f", manualAmount) : "" }
        set { manualAmount = Double(newValue) ?? 0 }
    }

    var initialDepositText: String {
        get { initialDeposit > 0 ? String(format: "%.0f", initialDeposit) : "" }
        set { initialDeposit = Double(newValue) ?? 0 }
    }

    var monthlyContributionText: String {
        get { monthlyContribution > 0 ? String(format: "%.0f", monthlyContribution) : "" }
        set { monthlyContribution = Double(newValue) ?? 0 }
    }

    // MARK: - Computed Properties
    var selectedPie: Portfolio? {
        switch selectedPieType {
        case .custom:
            return createCustomPie()
        case .model:
            return selectedModelPie
        case .community:
            return selectedCommunityPie
        }
    }

    var canProceedFromStep1: Bool {
        switch selectedPieType {
        case .custom:
            return !customPieAllocations.isEmpty && isValidAllocation
        case .model:
            return selectedModelPie != nil
        case .community:
            return selectedCommunityPie != nil
        }
    }

    var canProceedFromStep2: Bool {
        true // Investment method is always selected
    }

    var canProceedFromStep3: Bool {
        switch investmentMethod {
        case .manual:
            return manualAmount >= 5 && manualAmount <= maxInvestmentAmount
        case .autoInvest:
            return initialDeposit >= 5 && monthlyContribution >= 0 && investmentDuration >= 1
        }
    }

    var canProceedFromStep4: Bool {
        !projections.isEmpty
    }

    var canProceedFromStep5: Bool {
        !pieName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canConfirm: Bool {
        acceptTerms && canProceedFromStep5
    }

    var isValidAllocation: Bool {
        let total = customPieAllocations.reduce(0) { $0 + $1.percentage }
        return abs(total - 100.0) < 0.01
    }

    var maxInvestmentAmount: Double {
        cashAccount.balance
    }

    var currentStepTitle: String {
        switch currentStep {
        case 1: return "Select Pie"
        case 2: return "Investment Method"
        case 3: return "Configure"
        case 4: return "Value Projections"
        case 5: return "Name Pie"
        case 6: return "Confirm"
        default: return "Investment"
        }
    }

    var progressPercentage: Double {
        Double(currentStep) / Double(maxSteps)
    }

    init() {
        // Initialize with mock cash account
        self.cashAccount = CashAccount(
            userId: UUID(),
            balance: 5250.0,
            totalDeposited: 12500.0,
            kycStatus: .verified,
            verificationLevel: .full
        )

        // Load mock data
        loadMockData()
    }

    // MARK: - Navigation
    func nextStep() {
        if currentStep < maxSteps {
            currentStep += 1

            // Generate projections when entering step 4
            if currentStep == 4 {
                generateProjections()
            }
        }
    }

    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }

    func goToStep(_ step: Int) {
        if step >= 1 && step <= maxSteps {
            currentStep = step
        }
    }

    func canProceed(from step: Int) -> Bool {
        switch step {
        case 1: return canProceedFromStep1
        case 2: return canProceedFromStep2
        case 3: return canProceedFromStep3
        case 4: return canProceedFromStep4
        case 5: return canProceedFromStep5
        case 6: return canConfirm
        default: return false
        }
    }

    // MARK: - Step 1: Pie Selection
    func selectPieType(_ type: PieSelectionType) {
        selectedPieType = type
        // Clear other selections
        selectedModelPie = nil
        selectedCommunityPie = nil
        customPieAllocations = []
    }

    func selectModelPie(_ pie: Portfolio) {
        selectedModelPie = pie
        selectedPieType = .model
    }

    func selectCommunityPie(_ pie: Portfolio) {
        selectedCommunityPie = pie
        selectedPieType = .community
    }

    func addCustomAllocation(_ allocation: PieAllocation) {
        customPieAllocations.append(allocation)
    }

    func removeCustomAllocation(at index: Int) {
        if customPieAllocations.indices.contains(index) {
            customPieAllocations.remove(at: index)
        }
    }

    func setCustomPieAllocations(_ allocations: [PieAllocation]) {
        customPieAllocations = allocations
    }

    func showStockPicker() {
        showingStockPicker = true
    }

    func updateAllocation(_ stockId: UUID, percentage: Double) {
        guard let index = customPieAllocations.firstIndex(where: { $0.stockId == stockId }) else { return }

        let oldPercentage = customPieAllocations[index].percentage
        let difference = percentage - oldPercentage
        let otherAllocationsCount = customPieAllocations.count - 1

        if otherAllocationsCount > 0 && abs(difference) > 0.01 {
            let adjustmentPerAllocation = -difference / Double(otherAllocationsCount)

            for i in 0..<customPieAllocations.count {
                if customPieAllocations[i].stockId != stockId {
                    let newPercentage = max(0, min(100, customPieAllocations[i].percentage + adjustmentPerAllocation))
                    customPieAllocations[i] = PieAllocation(
                        stockId: customPieAllocations[i].stockId,
                        symbol: customPieAllocations[i].symbol,
                        name: customPieAllocations[i].name,
                        percentage: newPercentage
                    )
                }
            }
        }

        customPieAllocations[index] = PieAllocation(
            stockId: stockId,
            symbol: customPieAllocations[index].symbol,
            name: customPieAllocations[index].name,
            percentage: percentage
        )
    }

    func removeAllocation(_ stockId: UUID) {
        customPieAllocations.removeAll { $0.stockId == stockId }
    }

    func rebalanceAllocations() {
        guard !customPieAllocations.isEmpty else { return }

        let equalPercentage = 100.0 / Double(customPieAllocations.count)

        withAnimation(.easeInOut(duration: 0.5)) {
            for i in 0..<customPieAllocations.count {
                customPieAllocations[i] = PieAllocation(
                    stockId: customPieAllocations[i].stockId,
                    symbol: customPieAllocations[i].symbol,
                    name: customPieAllocations[i].name,
                    percentage: equalPercentage
                )
            }
        }
    }

    // MARK: - Step 2: Investment Method
    func selectInvestmentMethod(_ method: InvestmentMethod) {
        investmentMethod = method
    }

    // MARK: - Step 4: Projections
    private func generateProjections() {
        guard let pie = selectedPie else { return }

        projections = ProjectionScenario.allCases.map { scenario in
            let amount = investmentMethod == .manual ? manualAmount : initialDeposit
            let monthly = investmentMethod == .manual ? 0 : monthlyContribution
            let duration = investmentMethod == .manual ? 1 : investmentDuration

            return InvestmentProjection(
                pieId: pie.id,
                scenario: scenario,
                initialDeposit: amount,
                monthlyContribution: monthly,
                investmentDuration: duration,
                pieAAR: pie.averageAnnualReturn
            )
        }
    }

    // MARK: - Step 5: Goals
    func selectGoal(_ goal: InvestmentGoal) {
        selectedGoal = goal

        // Auto-fill pie name if empty
        if pieName.isEmpty {
            pieName = "\(goal.name) Pie"
        }

        // Suggest duration based on goal
        if investmentMethod == .autoInvest {
            investmentDuration = goal.suggestedDuration
            // Regenerate projections with new duration
            generateProjections()
        }
    }

    // MARK: - Step 6: Confirmation
    func confirmInvestment() {
        guard canConfirm else { return }

        Task {
            isProcessing = true

            // Mock processing delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // Create the investment pie
            let newPie = createInvestmentPie()

            // Mock success
            isProcessing = false
            investmentCompleted = true
        }
    }

    // MARK: - Helper Methods
    private func createCustomPie() -> Portfolio? {
        guard !customPieAllocations.isEmpty else { return nil }

        let holdings = customPieAllocations.map { allocation in
            Holding(
                stockId: allocation.stockId,
                symbol: allocation.symbol,
                name: allocation.name,
                shares: 0,
                averagePrice: 100, // Mock price
                currentPrice: 105, // Mock price
                allocation: allocation.percentage
            )
        }

        return Portfolio(
            name: "Custom Pie",
            description: "Custom allocation pie",
            totalValue: 0,
            totalInvested: 0,
            holdings: holdings,
            creatorId: UUID()
        )
    }

    private func createInvestmentPie() -> InvestmentPie {
        return InvestmentPie(
            name: pieName,
            description: pieDescription.isEmpty ? nil : pieDescription,
            allocations: customPieAllocations,
            totalInvested: investmentMethod == .manual ? manualAmount : initialDeposit,
            autoInvestEnabled: investmentMethod == .autoInvest,
            autoInvestAmount: investmentMethod == .autoInvest ? monthlyContribution : nil
        )
    }

    private func loadMockData() {
        // Mock model pies
        modelPies = [
            Portfolio(
                name: "Conservative Growth",
                description: "Balanced portfolio focusing on stable growth with lower volatility",
                totalValue: 15420,
                totalInvested: 12000,
                holdings: [],
                creatorId: UUID()
            ),
            Portfolio(
                name: "WisdomTree Tech",
                description: "Technology-focused growth portfolio with established companies",
                totalValue: 8750,
                totalInvested: 7500,
                holdings: [],
                creatorId: UUID()
            )
        ]

        // Mock community pies
        communityPies = [
            Portfolio(
                name: "Sharia Compliant",
                description: "Halal investment portfolio compliant with Islamic principles",
                totalValue: 12345,
                totalInvested: 10000,
                holdings: [],
                isPublic: true,
                creatorId: UUID(),
                copyCount: 127
            )
        ]
    }

    func reset() {
        currentStep = 1
        selectedPieType = .custom
        selectedModelPie = nil
        selectedCommunityPie = nil
        customPieAllocations = []
        investmentMethod = .manual
        manualAmount = 0
        initialDeposit = 0
        monthlyContribution = 0
        investmentDay = 1
        investmentDuration = 5
        selectedScenario = .expected
        projections = []
        pieName = ""
        pieDescription = ""
        selectedGoal = nil
        acceptTerms = false
        isProcessing = false
        investmentCompleted = false
        errorMessage = ""
        showingError = false
    }
}

enum PieSelectionType: String, CaseIterable {
    case custom = "custom"
    case model = "model"
    case community = "community"

    var displayName: String {
        switch self {
        case .custom: return "Custom Pie"
        case .model: return "Model Pies"
        case .community: return "Community Pies"
        }
    }
}

enum InvestmentMethod: String, CaseIterable {
    case manual = "manual"
    case autoInvest = "auto_invest"

    var displayName: String {
        switch self {
        case .manual: return "Manual Investment"
        case .autoInvest: return "AutoInvest"
        }
    }

    var description: String {
        switch self {
        case .manual: return "One-time investment with your available funds"
        case .autoInvest: return "Set up recurring investments with projections"
        }
    }

    var iconName: String {
        switch self {
        case .manual: return "hand.point.up.left.fill"
        case .autoInvest: return "arrow.clockwise.circle.fill"
        }
    }
}