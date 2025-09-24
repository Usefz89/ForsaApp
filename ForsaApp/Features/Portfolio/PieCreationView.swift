//
//  PieCreationView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct PieCreationView: View {
    @StateObject private var viewModel = InvestmentFlowViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Breadcrumb navigation
                CompactBreadcrumb(
                    currentStep: viewModel.currentStep,
                    totalSteps: viewModel.maxSteps,
                    stepTitle: viewModel.currentStepTitle
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .background(Color.backgroundCard)

                // Step content
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
                .background(Color.backgroundPrimary)

                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Start Building Your Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.investmentCompleted) { _, completed in
            if completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $viewModel.showingStockPicker) {
            StockPickerView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            PieSelectionStepView(viewModel: viewModel)
        case 2:
            InvestmentMethodStepView(viewModel: viewModel)
        case 3:
            ConfigureInvestmentStepView(viewModel: viewModel)
        case 4:
            ValueProjectionsStepView(viewModel: viewModel)
        case 5:
            NamePieStepView(viewModel: viewModel)
        case 6:
            FinalizeInvestmentStepView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if viewModel.currentStep < viewModel.maxSteps && !viewModel.investmentCompleted {
                ForsaButton(
                    viewModel.currentStep == 6 ? "Confirm Investment" : "Next",
                    style: .primary,
                    size: .large,
                    isDisabled: !viewModel.canProceed(from: viewModel.currentStep),
                    isLoading: viewModel.isProcessing
                ) {
                    handleNext()
                }
            }

            if viewModel.currentStep > 1 && !viewModel.investmentCompleted {
                ForsaButton(
                    "Back",
                    style: .outline,
                    size: .large
                ) {
                    viewModel.previousStep()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.backgroundCard)
        .shadow(color: Color.shadowLight, radius: 8, x: 0, y: -2)
    }

    private func handleNext() {
        if viewModel.currentStep == 6 {
            viewModel.confirmInvestment()
        } else {
            viewModel.nextStep()
        }
    }
}

// MARK: - Step Views

struct PieSelectionStepView: View {
    @ObservedObject var viewModel: InvestmentFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose Your Investment Method")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Start by selecting how you want to build your pie")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            // Pie type tabs
            HStack(spacing: 0) {
                ForEach(PieSelectionType.allCases, id: \.self) { type in
                    Button(action: { viewModel.selectPieType(type) }) {
                        Text(type.displayName)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.selectedPieType == type ? .primaryPurple : .textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                viewModel.selectedPieType == type ?
                                Color.primaryPurple.opacity(0.1) : Color.clear
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color.backgroundSecondary)
            .cornerRadius(8)

            // Content based on selection
            switch viewModel.selectedPieType {
            case .custom:
                customPieContent
            case .model:
                modelPiesContent
            case .community:
                communityPiesContent
            }
        }
    }

    private var customPieContent: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Build Custom Pie")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("Create your own pie by selecting stocks and setting allocations")
                    .font(.callout)
                    .foregroundColor(.textSecondary)

                if viewModel.customPieAllocations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.title)
                            .foregroundColor(.textMuted)

                        Text("No stocks selected yet")
                            .font(.callout)
                            .foregroundColor(.textSecondary)

                        ForsaButton("Add Stocks", style: .outline) {
                            viewModel.showStockPicker()
                        }
                    }
                    .padding(.vertical, 20)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Selected Stocks (\(viewModel.customPieAllocations.count))")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Button("Edit") {
                                viewModel.showStockPicker()
                            }
                            .font(.callout)
                            .foregroundColor(.primaryPurple)
                        }

                        VStack(spacing: 8) {
                            ForEach(viewModel.customPieAllocations, id: \.stockId) { allocation in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(allocation.symbol)
                                            .font(.calloutMedium)
                                            .foregroundColor(.textPrimary)

                                        Text(allocation.name)
                                            .font(.caption1)
                                            .foregroundColor(.textSecondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text("\(String(format: "%.1f", allocation.percentage))%")
                                        .font(.calloutMedium)
                                        .foregroundColor(.primaryPurple)
                                }
                                .padding(.vertical, 4)

                                if allocation.stockId != viewModel.customPieAllocations.last?.stockId {
                                    Divider()
                                }
                            }
                        }

                        if !viewModel.isValidAllocation {
                            Text("Total allocation must equal 100%")
                                .font(.caption1)
                                .foregroundColor(.errorRed)
                        }
                    }
                }
            }
        }
    }

    private var modelPiesContent: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.modelPies) { pie in
                Button(action: { viewModel.selectModelPie(pie) }) {
                    ForsaCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(pie.name)
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.leading)

                                if let description = pie.description {
                                    Text(description)
                                        .font(.callout)
                                        .foregroundColor(.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }

                                HStack {
                                    Text("Expected AAR: \(String(format: "%.1f", pie.averageAnnualReturn))%")
                                        .font(.caption1)
                                        .foregroundColor(.primaryPurple)

                                    Spacer()

                                    Text("Moderate")
                                        .font(.caption1)
                                        .fontWeight(.medium)
                                        .foregroundColor(.halalGreen)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.halalBackground)
                                        .cornerRadius(4)
                                }
                            }

                            Spacer()

                            Image(systemName: viewModel.selectedModelPie?.id == pie.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(viewModel.selectedModelPie?.id == pie.id ? .primaryPurple : .borderPrimary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var communityPiesContent: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.communityPies) { pie in
                Button(action: { viewModel.selectCommunityPie(pie) }) {
                    ForsaCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(pie.name)
                                        .font(.headline)
                                        .foregroundColor(.textPrimary)

                                    Spacer()

                                    Text("\(pie.copyCount) copies")
                                        .font(.caption1)
                                        .foregroundColor(.textSecondary)
                                }

                                if let description = pie.description {
                                    Text(description)
                                        .font(.callout)
                                        .foregroundColor(.textSecondary)
                                        .lineLimit(2)
                                }

                                Text("Expected AAR: \(String(format: "%.1f", pie.averageAnnualReturn))%")
                                    .font(.caption1)
                                    .foregroundColor(.primaryPurple)
                            }

                            Spacer()

                            Image(systemName: viewModel.selectedCommunityPie?.id == pie.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(viewModel.selectedCommunityPie?.id == pie.id ? .primaryPurple : .borderPrimary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct InvestmentMethodStepView: View {
    @ObservedObject var viewModel: InvestmentFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose Your Investment Method")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("How would you like to invest in this pie?")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            VStack(spacing: 16) {
                ForEach(InvestmentMethod.allCases, id: \.self) { method in
                    InvestmentMethodCard(
                        method: method,
                        isSelected: viewModel.investmentMethod == method,
                        onSelect: { viewModel.selectInvestmentMethod(method) }
                    )
                }
            }
        }
    }
}

struct InvestmentMethodCard: View {
    let method: InvestmentMethod
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ForsaCard(shadowStyle: isSelected ? .medium : .light) {
                HStack(spacing: 16) {
                    Image(systemName: method.iconName)
                        .font(.title2)
                        .foregroundColor(.primaryPurple)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(method.displayName)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.leading)

                        Text(method.description)
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if method == .autoInvest {
                            Text("Recommended")
                                .font(.caption1)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryPurple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primaryPurple.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .primaryPurple : .borderPrimary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primaryPurple : Color.clear, lineWidth: 2)
        )
    }

}

struct ConfigureInvestmentStepView: View {
    @ObservedObject var viewModel: InvestmentFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configure Your Investment")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Set your investment parameters")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            if viewModel.investmentMethod == .manual {
                manualInvestmentConfig
            } else {
                autoInvestmentConfig
            }
        }
    }

    private var manualInvestmentConfig: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Investment Amount")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Enter amount", text: $viewModel.manualAmountText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(ForsaTextFieldStyle())
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("Available: KWD \(String(format: "%.0f", viewModel.cashAccount.balance))")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text("Minimum: KWD 5")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }

    private var autoInvestmentConfig: some View {
        VStack(spacing: 16) {
            // Initial Deposit
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Initial Deposit")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    TextField("Enter initial amount", text: $viewModel.initialDepositText)
                        .textFieldStyle(ForsaTextFieldStyle())
                        .keyboardType(.decimalPad)

                    Text("KWD 5 - KWD 50,000")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
            }

            // Monthly Contribution
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monthly Contribution")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    TextField("Enter monthly amount", text: $viewModel.monthlyContributionText)
                        .textFieldStyle(ForsaTextFieldStyle())
                        .keyboardType(.decimalPad)

                    Text("KWD 0 - KWD 2,000")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
            }

            // Investment Duration
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Investment Duration")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    HStack {
                        Text("\(viewModel.investmentDuration) years")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)

                        Spacer()
                    }

                    Slider(
                        value: Binding(
                            get: { Double(viewModel.investmentDuration) },
                            set: { viewModel.investmentDuration = Int($0) }
                        ),
                        in: 1...30,
                        step: 1
                    )
                    .accentColor(.primaryPurple)

                    HStack {
                        Text("1 year")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text("30 years")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
}

struct ValueProjectionsStepView: View {
    @ObservedObject var viewModel: InvestmentFlowViewModel
    @State private var animateChart = false

    var body: some View {
        VStack(spacing: 24) {
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Value Projections")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("See how your investment could grow over time")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            // Scenario toggle
            ProjectionScenarioToggle(selectedScenario: $viewModel.selectedScenario)

            // Projections chart
            ForsaCard(padding: EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16)) {
                ProjectionsChart(
                    projections: viewModel.projections,
                    selectedScenario: viewModel.selectedScenario
                )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateChart = true
            }
        }
    }
}

struct NamePieStepView: View {
    @ObservedObject var viewModel: InvestmentFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Name Your Investment")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Give your pie a name and set your investment goal")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            // Pie name input
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Name Your Investment Pie")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    TextField("Enter pie name", text: $viewModel.pieName)
                        .textFieldStyle(ForsaTextFieldStyle())

                    TextField("Description (Optional)", text: $viewModel.pieDescription, axis: .vertical)
                        .textFieldStyle(ForsaTextFieldStyle())
                        .lineLimit(3...5)
                }
            }

            // Investment goals
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Investment Goal")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(InvestmentGoal.presetGoals) { goal in
                            GoalTemplateCard(
                                goal: goal,
                                isSelected: viewModel.selectedGoal?.id == goal.id,
                                onSelect: { viewModel.selectGoal(goal) }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct GoalTemplateCard: View {
    let goal: InvestmentGoal
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ForsaCard(
                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
                shadowStyle: isSelected ? .medium : .light
            ) {
                VStack(spacing: 8) {
                    Image(systemName: goal.iconName)
                        .font(.title3)
                        .foregroundColor(isSelected ? .primaryPurple : .textSecondary)

                    Text(goal.name)
                        .font(.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .primaryPurple : .textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("\(goal.suggestedDuration) years")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primaryPurple : Color.clear, lineWidth: 1)
        )
    }
}

struct FinalizeInvestmentStepView: View {
    @ObservedObject var viewModel: InvestmentFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Success indicator
            if viewModel.investmentCompleted {
                completedState
            } else {
                confirmationContent
            }
        }
    }

    private var confirmationContent: some View {
        VStack(spacing: 24) {
            ForsaCard {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.primaryPurple)

                    VStack(spacing: 8) {
                        Text("Investment Summary")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("Review your investment details")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            // Investment details
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(viewModel.pieName)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    if let goal = viewModel.selectedGoal {
                        Text(goal.name)
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }

                    Divider()

                    VStack(spacing: 12) {
                        HStack {
                            Text("Investment Method:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.investmentMethod.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }

                        if viewModel.investmentMethod == .manual {
                            HStack {
                                Text("Amount:")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("KWD \(String(format: "%.0f", viewModel.manualAmount))")
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                            }
                        } else {
                            HStack {
                                Text("Initial Deposit:")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("KWD \(String(format: "%.0f", viewModel.initialDeposit))")
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                            }

                            HStack {
                                Text("Monthly Contribution:")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("KWD \(String(format: "%.0f", viewModel.monthlyContribution))")
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                            }

                            HStack {
                                Text("Duration:")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("\(viewModel.investmentDuration) years")
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    .font(.callout)

                    // Projected returns if AutoInvest
                    if viewModel.investmentMethod == .autoInvest,
                       let projection = viewModel.projections.first(where: { $0.scenario == viewModel.selectedScenario }) {
                        Divider()

                        VStack(spacing: 8) {
                            Text("Projected Returns (\(viewModel.selectedScenario.displayName))")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            HStack {
                                Text("Final Value:")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text(projection.formattedProjectedValue)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryPurple)
                            }

                            HStack {
                                Text("Total Gains:")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text(projection.formattedTotalGains)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gainGreen)
                            }
                        }
                        .font(.callout)
                    }
                }
            }

            // Terms and conditions
            ForsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("I accept the investment terms and conditions and confirm this investment", isOn: $viewModel.acceptTerms)
                        .font(.callout)
                        .foregroundColor(.textPrimary)

                    if !viewModel.acceptTerms {
                        Text("Please accept the terms to proceed")
                            .font(.caption1)
                            .foregroundColor(.errorRed)
                    }
                }
            }
        }
    }

    private var completedState: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.halalGreen)

            VStack(spacing: 8) {
                Text("Investment Created!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Your \"\(viewModel.pieName)\" pie has been successfully created")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ForsaCard {
                VStack(spacing: 12) {
                    Text("Next Steps")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Your investment will be processed shortly")
                        Text("• You can track performance in your portfolio")
                        Text("• Rebalancing will happen automatically")
                    }
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PieCreationView()
}