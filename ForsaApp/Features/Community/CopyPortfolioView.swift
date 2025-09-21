//
//  CopyPortfolioView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct CopyPortfolioView: View {
    let portfolio: Portfolio
    @StateObject private var viewModel = CopyPortfolioViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Portfolio overview
                portfolioOverviewView

                // Copy settings
                copySettingsView

                // Allocation preview
                allocationPreviewView

                // Auto-sync settings
                autoSyncView

                // Investment amount
                investmentAmountView

                // Copy button
                copyButtonView
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Copy Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setPortfolio(portfolio)
        }
        .alert("Portfolio Copied!", isPresented: $viewModel.showingSuccess) {
            Button("View My Pies") {
                dismiss()
            }
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Successfully copied \(portfolio.name) to your investment pies.")
        }
    }

    private var portfolioOverviewView: some View {
        ForsaCard {
            VStack(spacing: 16) {
                // Creator info
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gradientPrimary)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("SK") // Mock creator initials
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sara Khalil") // Mock creator name
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("256 followers • Verified")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(portfolio.totalGainLossPercentageFormatted)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(portfolio.isPositive ? .gainGreen : .lossRed)

                        Text("30 days")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)
                    }
                }

                // Portfolio details
                VStack(alignment: .leading, spacing: 12) {
                    Text(portfolio.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    if let description = portfolio.description {
                        Text(description)
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                            .lineLimit(nil)
                    }

                    HStack(spacing: 24) {
                        StatView(
                            title: "Portfolio Value",
                            value: "$\(String(format: "%.0f", portfolio.totalValue))",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .primaryBlue
                        )

                        StatView(
                            title: "Copies",
                            value: "\(portfolio.copyCount)",
                            icon: "doc.on.doc.fill",
                            color: .primaryGreen
                        )

                        StatView(
                            title: "Likes",
                            value: "\(portfolio.likesCount)",
                            icon: "heart.fill",
                            color: .errorRed
                        )
                    }
                }
            }
        }
    }

    private var copySettingsView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Copy Settings")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 12) {
                    Toggle("Copy exact allocations", isOn: $viewModel.copyExactAllocations)
                        .font(.callout)

                    Toggle("Enable auto-rebalancing", isOn: $viewModel.enableAutoRebalancing)
                        .font(.callout)

                    if viewModel.enableAutoRebalancing {
                        HStack {
                            Text("Rebalance frequency:")
                                .font(.callout)
                                .foregroundColor(.textSecondary)

                            Spacer()

                            Menu {
                                ForEach(RebalanceFrequency.allCases, id: \.self) { frequency in
                                    Button(frequency.displayName) {
                                        viewModel.rebalanceFrequency = frequency
                                    }
                                }
                            } label: {
                                Text(viewModel.rebalanceFrequency.displayName)
                                    .font(.callout)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                    }
                }
            }
        }
    }

    private var allocationPreviewView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Allocation Preview")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                LazyVStack(spacing: 8) {
                    ForEach(portfolio.holdings) { holding in
                        HStack {
                            Circle()
                                .fill(Color.primaryPurple.opacity(0.1))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(holding.symbol.prefix(2)))
                                        .font(.caption1)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primaryPurple)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(holding.symbol)
                                    .font(.calloutMedium)
                                    .foregroundColor(.textPrimary)

                                Text(holding.name)
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(holding.allocationFormatted)
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private var autoSyncView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title3)
                        .foregroundColor(.primaryPurple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Sync")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("Automatically update your pie when the creator makes changes")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.enableAutoSync)
                }

                if viewModel.enableAutoSync {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auto-sync benefits:")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.gainGreen)
                                Text("Always stay aligned with expert strategy")
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)
                            }

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.gainGreen)
                                Text("Automatic rebalancing when creator adjusts")
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)
                            }

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.gainGreen)
                                Text("Option to disable sync anytime")
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

    private var investmentAmountView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Investment Amount")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Initial Investment")
                            .font(.inputLabel)
                            .foregroundColor(.textPrimary)

                        TextField("$0.00", text: $viewModel.initialInvestmentText)
                            .textFieldStyle(ForsaTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }

                    Toggle("Enable monthly auto-invest", isOn: $viewModel.enableAutoInvest)
                        .font(.callout)

                    if viewModel.enableAutoInvest {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Auto-Invest Amount")
                                .font(.inputLabel)
                                .foregroundColor(.textPrimary)

                            TextField("$0.00", text: $viewModel.autoInvestAmountText)
                                .textFieldStyle(ForsaTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                }

                // Investment breakdown
                if viewModel.initialInvestment > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Investment Breakdown")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        LazyVStack(spacing: 4) {
                            ForEach(portfolio.holdings.prefix(3)) { holding in
                                HStack {
                                    Text(holding.symbol)
                                        .font(.caption1)
                                        .foregroundColor(.textSecondary)

                                    Spacer()

                                    Text("$\(String(format: "%.2f", viewModel.initialInvestment * (holding.allocation / 100)))")
                                        .font(.caption1)
                                        .foregroundColor(.textPrimary)
                                }
                            }

                            if portfolio.holdings.count > 3 {
                                Text("+ \(portfolio.holdings.count - 3) more stocks")
                                    .font(.caption2)
                                    .foregroundColor(.textMuted)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private var copyButtonView: some View {
        VStack(spacing: 12) {
            ForsaButton(
                "Copy Portfolio",
                style: .primary,
                size: .large,
                isDisabled: !viewModel.canCopyPortfolio,
                isLoading: viewModel.isCopying
            ) {
                Task {
                    await viewModel.copyPortfolio()
                }
            }

            if !viewModel.canCopyPortfolio {
                Text("Please enter an initial investment amount")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        CopyPortfolioView(portfolio: MockDataService.shared.communityPortfolios.first!)
    }
}