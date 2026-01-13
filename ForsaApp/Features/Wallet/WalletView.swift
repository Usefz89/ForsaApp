//
//  WalletView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = WalletViewModel()

    // MARK: - State
    @State private var contentAppeared = false

    /// Check if user is using a demo account (not a real signed-up user)
    private var isDemoAccount: Bool {
        coordinator.currentUser?.isDemoAccount ?? false
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    loadingView
                        .transition(.opacity)
                } else {
                    contentView
                        .transition(.opacity)
                }
            }
            .navigationTitle(WalletStrings.walletTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showingDepositFlow, onDismiss: {
                viewModel.loadData()
            }) {
                DepositFlowView()
                    .environmentObject(coordinator)
            }
            .sheet(isPresented: $viewModel.showingWithdrawFlow, onDismiss: {
                viewModel.loadData()
            }) {
                WithdrawFlowView(
                    availableBalance: viewModel.availableBalance,
                    onWithdrawalComplete: { _ in
                        viewModel.loadData()
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadData()
            Task {
                let didInvest = await coordinator.checkAndAutoInvestAvailableCash()
                if didInvest {
                    viewModel.loadData()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: WalletConstants.cardSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: WalletConstants.loadingIconSize, height: WalletConstants.loadingIconSize)

                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: WalletConstants.loadingIconInnerSize))
                    .foregroundColor(.primaryPurple)
            }

            VStack(spacing: 8) {
                Text(WalletStrings.loadingWallet)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(WalletStrings.fetchingData)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryPurple))
                .scaleEffect(1.2)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(WalletStrings.loadingWallet)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Error Banner
                if let error = viewModel.errorMessage {
                    WalletErrorBanner(message: error) {
                        viewModel.clearError()
                    }
                    .padding(.horizontal, WalletConstants.horizontalPadding)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Balance Header (Simplified)
                balanceHeader
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)

                // Action Buttons
                actionButtons
                    .padding(.top, 20)
                    .padding(.horizontal, WalletConstants.horizontalPadding)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: WalletConstants.springResponse,
                                       dampingFraction: WalletConstants.springDamping)
                               .delay(WalletConstants.cardAppearanceDelay),
                               value: contentAppeared)

                // Pending Transactions Banner (if any)
                if viewModel.hasPendingTransactions {
                    pendingBanner
                        .padding(.top, 16)
                        .padding(.horizontal, WalletConstants.horizontalPadding)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: WalletConstants.springResponse,
                                           dampingFraction: WalletConstants.springDamping)
                                   .delay(WalletConstants.cardAppearanceDelay * 1.5),
                                   value: contentAppeared)
                }

                // Account Stats
                accountStats
                    .padding(.top, 24)
                    .padding(.horizontal, WalletConstants.horizontalPadding)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: WalletConstants.springResponse,
                                       dampingFraction: WalletConstants.springDamping)
                               .delay(WalletConstants.cardAppearanceDelay * 2),
                               value: contentAppeared)

                // Recent Activity
                if viewModel.hasTransactions {
                    recentActivity
                        .padding(.top, 24)
                        .padding(.horizontal, WalletConstants.horizontalPadding)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: WalletConstants.springResponse,
                                           dampingFraction: WalletConstants.springDamping)
                                   .delay(WalletConstants.cardAppearanceDelay * 3),
                                   value: contentAppeared)
                }
            }
            .padding(.top, WalletConstants.contentTopPadding)
            .padding(.bottom, WalletConstants.tabBarBottomPadding)
        }
        .refreshable {
            await viewModel.refreshData()
            let didInvest = await coordinator.checkAndAutoInvestAvailableCash()
            if didInvest {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: WalletConstants.fadeInDuration)) {
                contentAppeared = true
            }
        }
    }

    // MARK: - Balance Header (Simplified)

    private var balanceHeader: some View {
        VStack(spacing: 8) {
            Text(WalletStrings.availableBalance)
                .font(.caption)
                .foregroundColor(.textSecondary)

            Text(viewModel.cashAccount.formattedBalance)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.primaryPurple)
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(WalletStrings.availableBalance): \(viewModel.cashAccount.formattedBalance)")
    }

    // MARK: - Action Buttons (Equal Width)

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Deposit Button
            Button(action: {
                if !isDemoAccount {
                    viewModel.showDepositFlow()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(WalletStrings.depositFunds)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isDemoAccount ? .textTertiary : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isDemoAccount ? Color.backgroundSecondary : Color.primaryPurple)
                .cornerRadius(12)
            }
            .disabled(isDemoAccount)
            .accessibilityLabel(WalletStrings.depositButtonAccessibility)
            .accessibilityHint(isDemoAccount ? WalletStrings.disabledInDemo : "")

            // Withdraw Button
            Button(action: {
                viewModel.showWithdrawFlow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle")
                    Text(WalletStrings.withdraw)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primaryPurple)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primaryPurple, lineWidth: 1.5)
                )
            }
            .accessibilityLabel(WalletStrings.withdrawButtonAccessibility)
        }
    }

    // MARK: - Pending Banner (Compact)

    private var pendingBanner: some View {
        PendingTransactionsBanner(
            count: viewModel.pendingTransactions.count,
            totalAmount: viewModel.formattedPendingAmount,
            expectedDate: viewModel.pendingTransactions.first?.estimatedSettlementTime ?? "1-2 days"
        )
    }

    // MARK: - Account Stats (Flat Rows)

    private var accountStats: some View {
        VStack(spacing: 4) {
            AccountStatRow(
                icon: "bolt.circle.fill",
                iconColor: .primaryBlue,
                title: WalletStrings.buyingPower,
                value: "$\(String(format: "%.2f", viewModel.buyingPower))"
            )

            AccountStatRow(
                icon: "arrow.down.circle.fill",
                iconColor: .primaryGreen,
                title: WalletStrings.totalDeposited,
                value: "$\(String(format: "%.2f", viewModel.cashAccount.totalDeposited))"
            )

            AccountStatRow(
                icon: "arrow.up.circle.fill",
                iconColor: .primaryOrange,
                title: WalletStrings.totalWithdrawn,
                value: "$\(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))"
            )
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(WalletStrings.recentTransactions)
                .font(.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(viewModel.recentTransactions) { transaction in
                    CleanTransactionRow(transaction: transaction)

                    if transaction.id != viewModel.recentTransactions.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.backgroundCard)
            .cornerRadius(12)

            // View All Button (Centered)
            NavigationLink {
                TransactionHistoryView(transactions: viewModel.allTransactions)
            } label: {
                Text(WalletStrings.viewAll)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .accessibilityLabel("View all transactions")
        }
    }
}

// MARK: - Supporting Views

struct BalanceBreakdownItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct WalletErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.errorRed)

            Text(message)
                .font(.caption)
                .foregroundColor(.errorRed)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.errorRed.opacity(0.7))
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding()
        .background(Color.errorRed.opacity(0.1))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    WalletView()
        .environmentObject(AppCoordinator())
}
