//
//  DepositFlowView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct DepositFlowView: View {
    @StateObject private var viewModel = CashDepositViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Content
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
            .navigationTitle("Add Money to Your Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.depositCompleted) { _, completed in
            if completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack {
                Text("Step \(viewModel.currentStep) of \(viewModel.maxSteps)")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text(viewModel.currentStepTitle)
                    .font(.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.borderPrimary)
                        .frame(height: 4)

                    Rectangle()
                        .fill(Color.primaryPurple)
                        .frame(width: geometry.size.width * viewModel.progressPercentage, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.top, 8)
        .background(Color.backgroundCard)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            AmountSelectionView(viewModel: viewModel)
        case 2:
            PaymentMethodSelectionView(viewModel: viewModel)
        case 3:
            SecurityVerificationView(viewModel: viewModel)
        case 4:
            DepositConfirmationView(viewModel: viewModel)
        case 5:
            DepositSuccessView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if viewModel.currentStep < viewModel.maxSteps && !viewModel.depositCompleted {
                ForsaButton(
                    viewModel.currentStep == 4 ? "Confirm Deposit" : "Continue",
                    style: .primary,
                    size: .large,
                    isDisabled: !viewModel.canProceed(from: viewModel.currentStep),
                    isLoading: viewModel.isProcessing
                ) {
                    handleContinue()
                }
            }

            if viewModel.currentStep > 1 && !viewModel.depositCompleted {
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

    private func handleContinue() {
        if viewModel.currentStep == 4 {
            viewModel.confirmDeposit()
        } else {
            viewModel.nextStep()
        }
    }
}

// MARK: - Step Views

struct AmountSelectionView: View {
    @ObservedObject var viewModel: CashDepositViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Account balance card
            ForsaCard {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Balance")
                                .font(.callout)
                                .foregroundColor(.textSecondary)

                            Text(viewModel.cashAccount.formattedBalance)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Available Limit")
                                .font(.callout)
                                .foregroundColor(.textSecondary)

                            Text("KWD \(String(format: "%.0f", viewModel.cashAccount.availableDailyLimit))")
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                        }
                    }

                    // KYC Status
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption1)
                            .foregroundColor(.halalGreen)

                        Text("Sharia Compliant Funding")
                            .font(.caption1)
                            .foregroundColor(.halalGreen)

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.halalBackground)
                    .cornerRadius(6)
                }
            }

            // Amount input
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Deposit Amount (KWD)")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    // Amount input field
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("0.00", text: $viewModel.depositAmountText)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(ForsaTextFieldStyle())

                        Text("Minimum: KWD 5 • Maximum: KWD \(String(format: "%.0f", viewModel.cashAccount.availableDailyLimit))")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    // Quick select amounts
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(viewModel.suggestedAmounts, id: \.self) { amount in
                            Button(action: { viewModel.selectAmount(amount) }) {
                                Text("KWD \(String(format: "%.0f", amount))")
                                    .font(.calloutMedium)
                                    .foregroundColor(viewModel.depositAmount == amount ? .white : .textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.depositAmount == amount ? Color.primaryPurple : Color.backgroundSecondary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Validation message
                    if viewModel.depositAmount > 0 && !viewModel.canProceedFromAmount {
                        Text("Amount must be between KWD 5 and KWD \(String(format: "%.0f", viewModel.cashAccount.availableDailyLimit))")
                            .font(.caption1)
                            .foregroundColor(.errorRed)
                    }
                }
            }

            // Recent transactions
            if !viewModel.recentTransactions.isEmpty {
                ForsaCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Deposits")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        VStack(spacing: 12) {
                            ForEach(viewModel.recentTransactions.prefix(3)) { transaction in
                                HStack {
                                    Image(systemName: transaction.paymentMethod.iconName)
                                        .font(.callout)
                                        .foregroundColor(.primaryPurple)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(transaction.paymentMethod.displayName)
                                            .font(.callout)
                                            .foregroundColor(.textPrimary)

                                        Text(transaction.createdAt, style: .date)
                                            .font(.caption1)
                                            .foregroundColor(.textSecondary)
                                    }

                                    Spacer()

                                    Text(transaction.formattedAmount)
                                        .font(.calloutMedium)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PaymentMethodSelectionView: View {
    @ObservedObject var viewModel: CashDepositViewModel

    var body: some View {
        VStack(spacing: 24) {
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Payment Method")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Depositing KWD \(String(format: "%.0f", viewModel.depositAmount)) • Choose your preferred funding method")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            VStack(spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodCard(
                        method: method,
                        depositAmount: viewModel.depositAmount,
                        isSelected: viewModel.selectedPaymentMethod == method,
                        onSelect: { viewModel.selectPaymentMethod(method) }
                    )
                }
            }
        }
    }
}

struct SecurityVerificationView: View {
    @ObservedObject var viewModel: CashDepositViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Security header
            ForsaCard {
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48))
                        .foregroundColor(.primaryPurple)

                    VStack(spacing: 8) {
                        Text("Security Verification")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("For your security, we need to verify this transaction")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            // Transaction summary
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transaction Summary")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Deposit Amount:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text("KWD \(String(format: "%.0f", viewModel.depositAmount))")
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }

                        HStack {
                            Text("Processing Fee:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text("KWD \(String(format: "%.2f", viewModel.processingFee))")
                                .foregroundColor(.textPrimary)
                        }

                        Divider()

                        HStack {
                            Text("Net Credit:")
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("KWD \(String(format: "%.2f", viewModel.netAmount))")
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryPurple)
                        }

                        HStack {
                            Text("Payment Method:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.selectedPaymentMethod?.displayName ?? "Unknown")
                                .foregroundColor(.textPrimary)
                        }

                        HStack {
                            Text("Processing Time:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.estimatedSettlementTime)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .font(.callout)
                }
            }

            // Verification steps
            VStack(spacing: 16) {
                // Sharia Compliance
                SecurityCheckView(
                    title: "Sharia Compliance Verified",
                    subtitle: "Fully compliant with Sharia investment principles",
                    icon: "checkmark.shield.fill",
                    status: .verified,
                    color: .halalGreen,
                    action: nil
                )

                // Identity Verified
                SecurityCheckView(
                    title: "Identity Verified",
                    subtitle: "Your KYC status is approved",
                    icon: "person.badge.shield.checkmark.fill",
                    status: .verified,
                    color: .halalGreen,
                    action: nil
                )

                // Two Factor Authentication (if required)
                if viewModel.requiresTwoFactor {
                    SecurityCheckView(
                        title: "Two Factor Authentication",
                        subtitle: "Required for amounts over KWD 1,000",
                        icon: "key.fill",
                        status: viewModel.twoFactorEnabled ? .verified : .pending,
                        color: viewModel.twoFactorEnabled ? .halalGreen : .primaryPurple,
                        action: viewModel.twoFactorEnabled ? nil : {
                            viewModel.enableTwoFactor()
                        }
                    )
                }
            }
        }
    }
}

struct DepositConfirmationView: View {
    @ObservedObject var viewModel: CashDepositViewModel

    var body: some View {
        VStack(spacing: 24) {
            ForsaCard {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.halalGreen)

                    VStack(spacing: 8) {
                        Text("Ready to Process")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("Your deposit is ready to be processed")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            // Final confirmation details
            ForsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Final Confirmation")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Deposit Amount:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text("KWD \(String(format: "%.2f", viewModel.netAmount))")
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }

                        HStack {
                            Text("Payment Method:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.selectedPaymentMethod?.displayName ?? "Unknown")
                                .foregroundColor(.textPrimary)
                        }

                        HStack {
                            Text("Expected Credit:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.estimatedSettlementTime)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .font(.callout)

                    Divider()

                    HStack {
                        Text("Reference:")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("FUL-\(Int.random(in: 100000...999999))")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.textPrimary)
                    }
                    .font(.caption1)

                    Text("Save this reference for tracking your account")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
            }

            // Auto invest option
            ForsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle("Auto invest in existing pies", isOn: $viewModel.autoInvestExistingPies)
                            .font(.callout)
                            .foregroundColor(.textPrimary)
                    }

                    if viewModel.autoInvestExistingPies {
                        Text("Automatically allocate this deposit to your current pie investments")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
}

struct DepositSuccessView: View {
    @ObservedObject var viewModel: CashDepositViewModel

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.halalGreen)

                VStack(spacing: 8) {
                    Text("Deposit Successful!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Your funds will be available shortly")
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }

            ForsaCard {
                VStack(spacing: 16) {
                    Text("Deposit Summary")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Amount Deposited:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text("KWD \(String(format: "%.2f", viewModel.netAmount))")
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                        }

                        HStack {
                            Text("New Balance:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.cashAccount.formattedBalance)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryPurple)
                        }

                        HStack {
                            Text("Processing Time:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(viewModel.estimatedSettlementTime)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .font(.callout)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let depositAmount: Double
    let isSelected: Bool
    let onSelect: () -> Void

    private var processingFee: Double {
        depositAmount * (method.processingFeePercentage / 100)
    }

    var body: some View {
        Button(action: onSelect) {
            ForsaCard(
                shadowStyle: isSelected ? .medium : .light
            ) {
                HStack(spacing: 12) {
                    Image(systemName: method.iconName)
                        .font(.title3)
                        .foregroundColor(.primaryPurple)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(method.displayName)
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)

                            if method.isRecommended {
                                Text("Recommended")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primaryPurple)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.primaryPurple.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }

                        Text(method.subtitle)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)

                        HStack {
                            Text("Fee: \(method.processingFeePercentage > 0 ? String(format: "%.1f", method.processingFeePercentage) + "%" : "Free")")
                                .font(.caption1)
                                .foregroundColor(method.processingFeePercentage > 0 ? .textSecondary : .halalGreen)

                            Text("•")
                                .foregroundColor(.textMuted)

                            Text(method.processingTime)
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        if method.processingFeePercentage > 0 {
                            Text("KWD \(String(format: "%.2f", processingFee))")
                                .font(.caption1)
                                .foregroundColor(.textSecondary)
                        }

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(isSelected ? .primaryPurple : .borderPrimary)
                    }
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

struct SecurityCheckView: View {
    let title: String
    let subtitle: String
    let icon: String
    let status: SecurityStatus
    let color: Color
    let action: (() -> Void)?

    var body: some View {
        ForsaCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)

                    Text(subtitle)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if let action = action {
                    ForsaButton("Verify", style: .outline, size: .small, action: action)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(color)
                }
            }
        }
    }
}

enum SecurityStatus {
    case pending
    case verified
    case failed
}

// MARK: - Preview
#Preview {
    DepositFlowView()
}