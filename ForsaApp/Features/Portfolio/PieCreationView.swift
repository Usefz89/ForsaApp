//
//  PieCreationView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct PieCreationView: View {
    @StateObject private var viewModel = PieCreationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header info
                    headerView

                    // Pie details
                    pieDetailsView

                    // Stock allocation
                    allocationView

                    // Auto-invest settings
                    autoInvestView

                    // Create button
                    createButtonView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Create Investment Pie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Build Your Portfolio")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("Create a diversified investment pie with automatic rebalancing and halal-compliant stocks.")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                    .lineLimit(nil)

                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index <= viewModel.currentStep ? Color.primaryPurple : Color.borderPrimary)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    private var pieDetailsView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pie Details")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pie Name")
                            .font(.inputLabel)
                            .foregroundColor(.textPrimary)

                        TextField("Enter pie name", text: $viewModel.pieName)
                            .textFieldStyle(ForsaTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.inputLabel)
                            .foregroundColor(.textPrimary)

                        TextField("Describe your investment strategy", text: $viewModel.pieDescription, axis: .vertical)
                            .textFieldStyle(ForsaTextFieldStyle())
                            .lineLimit(3...5)
                    }
                }
            }
        }
    }

    private var allocationView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Stock Allocation")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text("\(String(format: "%.1f", viewModel.totalAllocation))%")
                        .font(.calloutMedium)
                        .foregroundColor(viewModel.isValidAllocation ? .gainGreen : .errorRed)
                }

                // Selected stocks
                if !viewModel.selectedStocks.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.selectedStocks) { allocation in
                            AllocationRowView(
                                allocation: allocation,
                                onPercentageChange: { newPercentage in
                                    viewModel.updateAllocation(allocation.id, percentage: newPercentage)
                                },
                                onRemove: {
                                    viewModel.removeStock(allocation.id)
                                }
                            )
                        }
                    }

                    if !viewModel.isValidAllocation {
                        Text("Total allocation must equal 100%")
                            .font(.caption1)
                            .foregroundColor(.errorRed)
                            .padding(.top, 8)
                    }
                }

                // Add stock button
                ForsaButton("Add Stocks", style: .outline) {
                    viewModel.showingStockPicker = true
                }
            }
        }
    }

    private var autoInvestView: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Auto-Invest Settings")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Toggle("Enable Auto-Invest", isOn: $viewModel.autoInvestEnabled)
                    .font(.callout)

                if viewModel.autoInvestEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Amount")
                                .font(.inputLabel)
                                .foregroundColor(.textPrimary)

                            TextField("$0.00", text: $viewModel.autoInvestAmountText)
                                .textFieldStyle(ForsaTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rebalance Frequency")
                                .font(.inputLabel)
                                .foregroundColor(.textPrimary)

                            Menu {
                                ForEach(RebalanceFrequency.allCases, id: \.self) { frequency in
                                    Button(frequency.displayName) {
                                        viewModel.rebalanceFrequency = frequency
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.rebalanceFrequency.displayName)
                                        .foregroundColor(.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.backgroundSecondary)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }

    private var createButtonView: some View {
        VStack(spacing: 12) {
            ForsaButton(
                "Create Investment Pie",
                style: .primary,
                size: .large,
                isDisabled: !viewModel.canCreatePie,
                isLoading: viewModel.isCreating
            ) {
                Task {
                    await viewModel.createPie()
                    if viewModel.pieCreated {
                        dismiss()
                    }
                }
            }

            if !viewModel.canCreatePie {
                Text("Please add stocks and ensure allocation totals 100%")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct AllocationRowView: View {
    let allocation: PieAllocation
    let onPercentageChange: (Double) -> Void
    let onRemove: () -> Void

    @State private var percentageText: String

    init(allocation: PieAllocation, onPercentageChange: @escaping (Double) -> Void, onRemove: @escaping () -> Void) {
        self.allocation = allocation
        self.onPercentageChange = onPercentageChange
        self.onRemove = onRemove
        self._percentageText = State(initialValue: String(format: "%.1f", allocation.percentage))
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.primaryPurple.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(allocation.symbol.prefix(2)))
                        .font(.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryPurple)
                )

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

            HStack(spacing: 8) {
                TextField("0", text: $percentageText)
                    .textFieldStyle(ForsaTextFieldStyle())
                    .frame(width: 60)
                    .keyboardType(.decimalPad)
                    .onChange(of: percentageText) { newValue in
                        if let percentage = Double(newValue) {
                            onPercentageChange(percentage)
                        }
                    }

                Text("%")
                    .font(.callout)
                    .foregroundColor(.textSecondary)

                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.errorRed)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    PieCreationView()
}