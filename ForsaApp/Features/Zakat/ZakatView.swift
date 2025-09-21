//
//  ZakatView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct ZakatView: View {
    @StateObject private var viewModel = ZakatViewModel()
    @State private var selectedTab = 0

    private let tabs = ["Calculator", "History", "Learn"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Tab selector
                tabSelectorView

                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        calculatorView
                    case 1:
                        historyView
                    case 2:
                        educationView
                    default:
                        calculatorView
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadCurrentCalculation()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Zakat Calculator")
                    .font(.title1)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Calculate your Islamic obligations")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var tabSelectorView: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tab)
                        .font(.calloutMedium)
                        .foregroundColor(selectedTab == index ? .white : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == index ? Color.primaryPurple : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var calculatorView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Nisab status card
                nisabStatusView

                // Quick calculation from portfolio
                portfolioQuickCalcView

                // Manual asset entry
                assetCategoriesView

                // Debts section
                debtsView

                // Calculation summary
                calculationSummaryView
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }

    private var nisabStatusView: some View {
        ForsaCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nisab Threshold")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("Current threshold based on gold price")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "info.circle")
                        .foregroundColor(.primaryPurple)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.calculation.formattedNisabThreshold)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        Text("Gold: $\(String(format: "%.2f", viewModel.calculation.goldPricePerOunce))/oz")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: viewModel.calculation.isNisabMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.calculation.isNisabMet ? .gainGreen : .lossRed)

                        Text(viewModel.calculation.isNisabMet ? "Nisab Met" : "Below Nisab")
                            .font(.caption1)
                            .foregroundColor(viewModel.calculation.isNisabMet ? .gainGreen : .lossRed)
                    }
                }
            }
        }
    }

    private var portfolioQuickCalcView: some View {
        ForsaCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Portfolio Assets")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Button("Auto-Import") {
                        viewModel.importPortfolioAssets()
                    }
                    .font(.callout)
                    .foregroundColor(.primaryPurple)
                }

                if viewModel.portfolioValue > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Investment Portfolio")
                                .font(.callout)
                                .foregroundColor(.textSecondary)

                            Text("$\(String(format: "%.2f", viewModel.portfolioValue))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }

                        Spacer()

                        Button("Include") {
                            viewModel.includePortfolioInCalculation()
                        }
                        .font(.callout)
                        .foregroundColor(.primaryPurple)
                    }
                    .padding(12)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(8)
                } else {
                    Text("No portfolio data available")
                        .font(.callout)
                        .foregroundColor(.textTertiary)
                }
            }
        }
    }

    private var assetCategoriesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset Categories")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVStack(spacing: 12) {
                ForEach(AssetCategory.allCases, id: \.self) { category in
                    AssetCategoryRow(
                        category: category,
                        assets: viewModel.getAssets(for: category),
                        onAdd: {
                            viewModel.showingAddAsset = true
                            viewModel.selectedCategory = category
                        },
                        onEdit: { asset in
                            viewModel.editingAsset = asset
                            viewModel.showingAddAsset = true
                        }
                    )
                }
            }
        }
    }

    private var debtsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Deductible Debts")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: {
                    viewModel.showingAddDebt = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.primaryPurple)
                }
            }

            if viewModel.calculation.debts.isEmpty {
                ForsaCard {
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard")
                            .font(.title2)
                            .foregroundColor(.textMuted)

                        Text("No debts added")
                            .font(.callout)
                            .foregroundColor(.textSecondary)

                        Text("Add any deductible debts to get a more accurate calculation")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.calculation.debts) { debt in
                        DebtRowView(debt: debt) {
                            viewModel.removeDebt(debt)
                        }
                    }
                }
            }
        }
    }

    private var calculationSummaryView: some View {
        ForsaCard {
            VStack(spacing: 20) {
                Text("Zakat Calculation Summary")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 12) {
                    SummaryRow(title: "Total Assets", value: viewModel.calculation.formattedTotalAssets)
                    SummaryRow(title: "Total Debts", value: viewModel.calculation.formattedTotalDebts)

                    Divider()

                    SummaryRow(
                        title: "Net Zakatable Wealth",
                        value: viewModel.calculation.formattedNetWorth,
                        isHighlighted: true
                    )

                    SummaryRow(
                        title: "Zakat Due (2.5%)",
                        value: viewModel.calculation.formattedZakatDue,
                        isHighlighted: true,
                        color: viewModel.calculation.zakatDue > 0 ? .primaryGreen : .textSecondary
                    )
                }

                if viewModel.calculation.zakatDue > 0 {
                    VStack(spacing: 12) {
                        ForsaButton("Record Zakat Payment", style: .primary) {
                            viewModel.showingPaymentSheet = true
                        }

                        ForsaButton("Export Calculation", style: .outline) {
                            viewModel.exportCalculation()
                        }
                    }
                }
            }
        }
    }

    private var historyView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.zakatHistory.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Calculation History",
                        message: "Your previous Zakat calculations will appear here.",
                        actionTitle: "Calculate Now"
                    ) {
                        selectedTab = 0
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.zakatHistory) { payment in
                            ZakatHistoryCard(payment: payment)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }

    private var educationView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(ZakatEducationContent.allContent) { content in
                    EducationCard(content: content)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Supporting Views

struct AssetCategoryRow: View {
    let category: AssetCategory
    let assets: [ZakatAsset]
    let onAdd: () -> Void
    let onEdit: (ZakatAsset) -> Void

    private var totalValue: Double {
        assets.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        ForsaCard(padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.displayName)
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)

                        Text(category.description)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(String(format: "%.2f", totalValue))")
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)

                        Button(action: onAdd) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.primaryPurple)
                        }
                    }
                }

                if !assets.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(assets) { asset in
                            HStack {
                                Text(asset.name)
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)

                                Spacer()

                                Text(asset.formattedValue)
                                    .font(.caption1)
                                    .foregroundColor(.textPrimary)

                                Button(action: { onEdit(asset) }) {
                                    Image(systemName: "pencil")
                                        .font(.caption1)
                                        .foregroundColor(.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct DebtRowView: View {
    let debt: ZakatDebt
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(debt.name)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)

                if let dueDate = debt.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Text(debt.formattedAmount)
                .font(.calloutMedium)
                .foregroundColor(.textPrimary)

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.caption1)
                    .foregroundColor(.errorRed)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let isHighlighted: Bool
    let color: Color

    init(title: String, value: String, isHighlighted: Bool = false, color: Color = .textPrimary) {
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
        self.color = color
    }

    var body: some View {
        HStack {
            Text(title)
                .font(isHighlighted ? .calloutMedium : .callout)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(isHighlighted ? .calloutMedium : .callout)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundColor(color)
        }
    }
}

struct ZakatHistoryCard: View {
    let payment: ZakatPayment

    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Zakat Payment")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text(payment.paymentDate, style: .date)
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount Paid")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Text(payment.formattedAmount)
                            .font(.headline)
                            .foregroundColor(.primaryGreen)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Hijri Year")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Text(payment.hijriYear)
                            .font(.callout)
                            .foregroundColor(.textPrimary)
                    }
                }

                if let recipient = payment.recipient {
                    Text("Paid to: \(recipient)")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
        }
    }
}

struct EducationCard: View {
    let content: ZakatEducationContent

    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: content.iconName)
                        .font(.title2)
                        .foregroundColor(.primaryPurple)

                    Text(content.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()
                }

                Text(content.description)
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                    .lineLimit(nil)

                if !content.keyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(content.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.primaryPurple)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 6)

                                Text(point)
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct ZakatEducationContent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let keyPoints: [String]

    static let allContent = [
        ZakatEducationContent(
            title: "What is Zakat?",
            description: "Zakat is one of the Five Pillars of Islam and represents the obligation to give a portion of one's wealth to those in need.",
            iconName: "heart.fill",
            keyPoints: [
                "Third pillar of Islam",
                "Purifies wealth and soul",
                "Benefits the community",
                "Mandatory for eligible Muslims"
            ]
        ),
        ZakatEducationContent(
            title: "Nisab Threshold",
            description: "Nisab is the minimum amount of wealth a Muslim must possess before they become eligible to pay Zakat.",
            iconName: "scale.3d",
            keyPoints: [
                "Based on 85 grams of gold",
                "Updates with gold prices",
                "Must be maintained for one lunar year",
                "Calculated on net worth"
            ]
        ),
        ZakatEducationContent(
            title: "Calculation Rate",
            description: "Zakat is calculated at 2.5% (1/40th) of your eligible wealth that has been in your possession for a full lunar year.",
            iconName: "percent",
            keyPoints: [
                "2.5% of eligible wealth",
                "Applied to net worth above Nisab",
                "Calculated annually",
                "Different rates for different assets"
            ]
        ),
        ZakatEducationContent(
            title: "Who Receives Zakat?",
            description: "Zakat should be distributed to eight categories of recipients as outlined in the Quran.",
            iconName: "person.3.fill",
            keyPoints: [
                "The poor (Al-Fuqara)",
                "The needy (Al-Masakin)",
                "Zakat administrators",
                "Those whose hearts are reconciled"
            ]
        )
    ]
}

// MARK: - Preview
#Preview {
    ZakatView()
}