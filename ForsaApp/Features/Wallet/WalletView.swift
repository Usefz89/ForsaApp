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
            // Check for uninvested cash and auto-invest if available
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
            VStack(spacing: WalletConstants.cardSpacing) {
                if let error = viewModel.errorMessage {
                    WalletErrorBanner(message: error) {
                        viewModel.clearError()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                balanceHeader
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                
                actionButtons
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: WalletConstants.springResponse,
                                       dampingFraction: WalletConstants.springDamping)
                               .delay(WalletConstants.cardAppearanceDelay),
                               value: contentAppeared)
                
                accountOverview
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: WalletConstants.springResponse,
                                       dampingFraction: WalletConstants.springDamping)
                               .delay(WalletConstants.cardAppearanceDelay * 2),
                               value: contentAppeared)
                
                if viewModel.hasPendingTransactions {
                    pendingTransactionsSection
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: WalletConstants.springResponse,
                                           dampingFraction: WalletConstants.springDamping)
                                   .delay(WalletConstants.cardAppearanceDelay * 3),
                                   value: contentAppeared)
                }
                
                if viewModel.hasTransactions {
                    recentTransactionsSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: WalletConstants.springResponse,
                                           dampingFraction: WalletConstants.springDamping)
                                   .delay(WalletConstants.cardAppearanceDelay * 4),
                                   value: contentAppeared)
                }
            }
            .padding(.horizontal, WalletConstants.horizontalPadding)
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

    // MARK: - Balance Header
    
    private var balanceHeader: some View {
        ForsaCard {
            VStack(spacing: 20) {
                // Available Balance
                VStack(spacing: 4) {
                    Text(WalletStrings.availableBalance)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text(viewModel.cashAccount.formattedBalance)
                        .font(.system(size: WalletConstants.balanceFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryPurple)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(WalletStrings.availableBalance): \(viewModel.cashAccount.formattedBalance)")
                
                // Balance Breakdown
                balanceBreakdown
                
                // Pending Transfers Alert
                if viewModel.pendingAmount > 0 {
                    pendingFundsAlert
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Demo Account Notice
                if isDemoAccount {
                    demoAccountNotice
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Account Status
                accountStatusBadge
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(WalletStrings.balanceCardAccessibility)
    }
    
    private var balanceBreakdown: some View {
        HStack(spacing: 0) {
            BalanceBreakdownItem(
                icon: "bolt.circle.fill",
                label: WalletStrings.buyingPower,
                value: "$\(String(format: "%.2f", viewModel.buyingPower))",
                color: .primaryBlue
            )
            
            Divider().frame(height: WalletConstants.breakdownDividerHeight)
            
            BalanceBreakdownItem(
                icon: "arrow.down.circle.fill",
                label: WalletStrings.deposited,
                value: "$\(String(format: "%.2f", viewModel.cashAccount.totalDeposited))",
                color: .successGreen
            )
            
            Divider().frame(height: WalletConstants.breakdownDividerHeight)
            
            BalanceBreakdownItem(
                icon: "arrow.up.circle.fill",
                label: WalletStrings.withdrawn,
                value: "$\(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))",
                color: .warningYellow
            )
        }
        .padding(.vertical, WalletConstants.breakdownVerticalPadding)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
    }
    
    private var pendingFundsAlert: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.warningYellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(WalletStrings.fundsProcessing)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                Text("\(viewModel.formattedPendingAmount) will be available within 1-2 business days")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.warningYellow.opacity(0.1))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(WalletStrings.fundsProcessing): \(viewModel.formattedPendingAmount) pending")
    }
    
    private var demoAccountNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "testtube.2")
                .foregroundColor(.primaryOrange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(WalletStrings.demoAccount)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                Text(WalletStrings.demoAccountDescription)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.primaryOrange.opacity(0.1))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(WalletStrings.demoAccount)
    }
    
    private var accountStatusBadge: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill")
                .font(.callout)
                .foregroundColor(.halalGreen)

            Text(WalletStrings.accountVerified)
                .font(.callout)
                .foregroundColor(.halalGreen)

            Spacer()

            Text(viewModel.cashAccount.verificationLevel.displayName)
                .font(.caption1)
                .fontWeight(.medium)
                .foregroundColor(.primaryPurple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primaryPurple.opacity(0.1))
                .cornerRadius(4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(WalletStrings.accountVerified), \(viewModel.cashAccount.verificationLevel.displayName)")
    }

    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: WalletConstants.actionButtonSpacing) {
            // Deposit button
            VStack(spacing: 4) {
                Button(action: {
                    if !isDemoAccount {
                        viewModel.showDepositFlow()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(WalletStrings.depositFunds)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isDemoAccount ? .textTertiary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: WalletConstants.actionButtonHeight)
                    .background(isDemoAccount ? Color.backgroundSecondary : Color.primaryPurple)
                    .cornerRadius(WalletConstants.actionButtonCornerRadius)
                }
                .disabled(isDemoAccount)
                .accessibilityLabel(WalletStrings.depositButtonAccessibility)
                .accessibilityHint(isDemoAccount ? WalletStrings.disabledInDemo : "")
                
                if isDemoAccount {
                    Text(WalletStrings.disabledInDemo)
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)

            ForsaButton(WalletStrings.withdraw, style: .outline, size: .large) {
                viewModel.showWithdrawFlow()
            }
            .accessibilityLabel(WalletStrings.withdrawButtonAccessibility)
        }
    }
    
    // MARK: - Account Overview
    
    private var accountOverview: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: WalletConstants.sectionSpacing) {
                Text(WalletStrings.accountOverview)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 12) {
                    AccountOverviewRow(
                        title: WalletStrings.totalDeposited,
                        value: "$\(String(format: "%.2f", viewModel.cashAccount.totalDeposited))",
                        icon: "arrow.down.circle.fill",
                        color: .primaryGreen
                    )

                    AccountOverviewRow(
                        title: WalletStrings.totalWithdrawn,
                        value: "$\(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))",
                        icon: "arrow.up.circle.fill",
                        color: .primaryBlue
                    )

                    if viewModel.availableBalance != viewModel.cashAccount.balance {
                        AccountOverviewRow(
                            title: WalletStrings.availableBalance,
                            value: viewModel.formattedAvailableBalance,
                            icon: "dollarsign.circle.fill",
                            color: .primaryPurple
                        )
                    }
                }
            }
        }
    }

    // MARK: - Pending Transactions
    
    private var pendingTransactionsSection: some View {
        VStack(alignment: .leading, spacing: WalletConstants.sectionSpacing) {
            Text(WalletStrings.pendingTransactions)
                .font(.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: 12) {
                ForEach(viewModel.pendingTransactions) { transaction in
                    PendingTransactionCard(transaction: transaction)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Pending deposit of \(transaction.formattedAmount)")
                }
            }
        }
    }

    // MARK: - Recent Transactions
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: WalletConstants.sectionSpacing) {
            HStack {
                Text(WalletStrings.recentTransactions)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink(WalletStrings.viewAll) {
                    TransactionHistoryView(transactions: viewModel.allTransactions)
                }
                .font(.callout)
                .foregroundColor(.primaryPurple)
                .accessibilityLabel("View all transactions")
            }

            VStack(spacing: 12) {
                ForEach(viewModel.recentTransactions) { transaction in
                    CashTransactionRowView(transaction: transaction)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(WalletStrings.transactionAccessibility)
                }
            }
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
