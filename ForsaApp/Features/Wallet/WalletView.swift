//
//  WalletView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = CashReserveViewModel()
    
    /// Check if user is using a demo account (not a real signed-up user)
    private var isDemoAccount: Bool {
        coordinator.currentUser?.isDemoAccount ?? false
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Wallet")
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
                WithdrawFlowView()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Loading Wallet")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Fetching your account data...")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryPurple))
                .scaleEffect(1.2)
            
            Spacer()
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
                
                balanceHeader
                actionButtons
                accountOverview
                
                if !viewModel.pendingTransactions.isEmpty {
                    pendingTransactionsSection
                }
                
                if viewModel.hasTransactions {
                    recentTransactionsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.errorRed)
            Text(message)
                .font(.caption)
                .foregroundColor(.errorRed)
            Spacer()
        }
        .padding()
        .background(Color.errorRed.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Balance Header
    
    private var balanceHeader: some View {
        ForsaCard {
            VStack(spacing: 20) {
                // Available Balance
                VStack(spacing: 4) {
                    Text("Available Balance")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text(viewModel.cashAccount.formattedBalance)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryPurple)
                }
                
                // Balance Breakdown
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.primaryBlue)
                            Text("Buying Power")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Text("$\(String(format: "%.2f", viewModel.buyingPower))")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryBlue)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 40)
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.successGreen)
                            Text("Deposited")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Text("$\(String(format: "%.2f", viewModel.cashAccount.totalDeposited))")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.successGreen)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 40)
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.warningYellow)
                            Text("Withdrawn")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Text("$\(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.warningYellow)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .background(Color.backgroundSecondary)
                .cornerRadius(10)

                // Pending Transfers Alert
                if viewModel.pendingAmount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.warningYellow)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Funds Processing")
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
                }
                
                // Demo Account Notice
                if isDemoAccount {
                    HStack(spacing: 8) {
                        Image(systemName: "testtube.2")
                            .foregroundColor(.primaryOrange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Demo Account")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            Text("This is a sandbox environment for testing")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.primaryOrange.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Account Status
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.callout)
                        .foregroundColor(.halalGreen)

                    Text("Account Verified")
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
            }
        }
    }

    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Deposit button - disabled for demo accounts
            VStack(spacing: 4) {
                Button(action: {
                    if !isDemoAccount {
                        viewModel.showDepositFlow()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Deposit Funds")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isDemoAccount ? .textTertiary : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isDemoAccount ? Color.backgroundSecondary : Color.primaryPurple)
                    .cornerRadius(12)
                }
                .disabled(isDemoAccount)
                
                if isDemoAccount {
                    Text("Disabled in Demo")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)

            ForsaButton("Withdraw", style: .outline, size: .large) {
                viewModel.showWithdrawFlow()
            }
        }
    }
    
    // MARK: - Account Overview
    
    private var accountOverview: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Account Overview")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                VStack(spacing: 12) {
                    AccountOverviewRow(
                        title: "Total Deposited",
                        value: "$\(String(format: "%.2f", viewModel.cashAccount.totalDeposited))",
                        icon: "arrow.down.circle.fill",
                        color: .primaryGreen
                    )

                    AccountOverviewRow(
                        title: "Total Withdrawn",
                        value: "$\(String(format: "%.2f", viewModel.cashAccount.totalWithdrawn))",
                        icon: "arrow.up.circle.fill",
                        color: .primaryBlue
                    )

                    if viewModel.availableBalance != viewModel.cashAccount.balance {
                        AccountOverviewRow(
                            title: "Available Balance",
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Transactions")
                .font(.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: 12) {
                ForEach(viewModel.pendingTransactions) { transaction in
                    PendingTransactionCard(transaction: transaction)
                }
            }
        }
    }

    // MARK: - Recent Transactions
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink("View All") {
                    TransactionHistoryView(transactions: viewModel.allTransactions)
                }
                .font(.callout)
                .foregroundColor(.primaryPurple)
            }

            VStack(spacing: 12) {
                ForEach(viewModel.recentTransactions) { transaction in
                    CashTransactionRowView(transaction: transaction)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WalletView()
        .environmentObject(AppCoordinator())
}

