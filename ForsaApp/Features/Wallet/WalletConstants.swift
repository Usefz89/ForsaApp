//
//  WalletConstants.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

enum WalletConstants {
    // MARK: - Layout
    static let horizontalPadding: CGFloat = 20
    static let tabBarBottomPadding: CGFloat = 100
    static let cardSpacing: CGFloat = 24
    static let sectionSpacing: CGFloat = 16
    static let contentTopPadding: CGFloat = 10
    
    // MARK: - Balance Card
    static let balanceFontSize: CGFloat = 36
    static let breakdownDividerHeight: CGFloat = 40
    static let breakdownVerticalPadding: CGFloat = 12
    
    // MARK: - Icons
    static let loadingIconSize: CGFloat = 100
    static let loadingIconInnerSize: CGFloat = 40
    static let transactionIconSize: CGFloat = 24
    static let pendingIconSize: CGFloat = 32
    
    // MARK: - Buttons
    static let actionButtonHeight: CGFloat = 52
    static let actionButtonSpacing: CGFloat = 12
    static let actionButtonCornerRadius: CGFloat = 12
    
    // MARK: - Input
    static let amountInputFontSize: CGFloat = 36
    static let currencyLabelFontSize: CGFloat = 24
    static let quickSelectButtonHeight: CGFloat = 50
    
    // MARK: - Animation
    static let cardAppearanceDelay: Double = 0.05
    static let springResponse: Double = 0.5
    static let springDamping: Double = 0.8
    static let fadeInDuration: Double = 0.5
    
    // MARK: - Deposit/Withdraw
    static let minimumDepositKWD: Double = 10
    static let minimumWithdrawal: Double = 1.0
    static let quickSelectAmountsKWD: [Int] = [50, 100, 250, 500]
    static let quickSelectAmountsUSD: [Double] = [50, 100, 250, 500]
    
    // MARK: - Info Card
    static let infoCardCornerRadius: CGFloat = 12
    static let infoCardPadding: CGFloat = 16
    
    // MARK: - Result View
    static let successIconSize: CGFloat = 80
    static let successIconInnerSize: CGFloat = 40
    
    // MARK: - Payment Method Tabs
    static let tabIndicatorHeight: CGFloat = 3
    static let tabHeight: CGFloat = 48
    static let tabCornerRadius: CGFloat = 10
    static let paymentMethodIconSize: CGFloat = 28
    
    // MARK: - KNET Colors
    static let knetBlue = "#0066B3"
    static let knetGold = "#D4AF37"
    
    // MARK: - Processing Fees
    static let knetFeePercentage: Double = 0.0
    static let creditCardFeePercentage: Double = 2.5
    static let wireTransferFee: Double = 5.0  // KWD flat fee
}

// MARK: - Wallet Strings (Localization Ready)

enum WalletStrings {
    // Navigation
    static let walletTitle = String(localized: "Wallet")
    static let depositTitle = String(localized: "Deposit Funds")
    static let withdrawTitle = String(localized: "Withdraw Funds")
    static let transactionHistoryTitle = String(localized: "Transaction History")
    static let investmentResultTitle = String(localized: "Investment Result")
    
    // Loading
    static let loadingWallet = String(localized: "Loading Wallet")
    static let fetchingData = String(localized: "Fetching your account data...")
    
    // Balance
    static let availableBalance = String(localized: "Available Balance")
    static let buyingPower = String(localized: "Buying Power")
    static let deposited = String(localized: "Deposited")
    static let withdrawn = String(localized: "Withdrawn")
    
    // Status
    static let fundsProcessing = String(localized: "Funds Processing")
    static let demoAccount = String(localized: "Demo Account")
    static let demoAccountDescription = String(localized: "This is a sandbox environment for testing")
    static let accountVerified = String(localized: "Account Verified")
    static let disabledInDemo = String(localized: "Disabled in Demo")
    
    // Actions
    static let depositFunds = String(localized: "Deposit Funds")
    static let withdraw = String(localized: "Withdraw")
    static let cancel = String(localized: "Cancel")
    static let done = String(localized: "Done")
    static let viewAll = String(localized: "View All")
    static let viewPortfolio = String(localized: "View Portfolio")
    
    // Sections
    static let accountOverview = String(localized: "Account Overview")
    static let pendingTransactions = String(localized: "Pending Transactions")
    static let recentTransactions = String(localized: "Recent Transactions")
    static let totalDeposited = String(localized: "Total Deposited")
    static let totalWithdrawn = String(localized: "Total Withdrawn")
    
    // Deposit Flow
    static let enterAmountKWD = String(localized: "Enter Amount in KWD")
    static let quickSelectKWD = String(localized: "Quick Select (KWD)")
    static let autoInvestFunds = String(localized: "Auto-Invest Funds")
    static let investmentBreakdown = String(localized: "Investment Breakdown")
    static let depositInformation = String(localized: "Deposit Information")
    static let processingTime = String(localized: "Processing Time")
    static let minimumDeposit = String(localized: "Minimum Deposit")
    static let fee = String(localized: "Fee")
    static let free = String(localized: "Free")
    static let depositAndInvest = String(localized: "Deposit & Invest")
    
    // Withdraw Flow
    static let enterWithdrawAmount = String(localized: "Enter Amount to Withdraw")
    static let quickSelectUSD = String(localized: "Quick Select (USD)")
    static let withdrawFunds = String(localized: "Withdraw Funds")
    static let withdrawalInformation = String(localized: "Withdrawal Information")
    static let availableToWithdraw = String(localized: "Available to Withdraw")
    static let estimatedArrival = String(localized: "Estimated Arrival")
    static let businessDays = String(localized: "1-3 Business Days")
    
    // Results
    static let investmentComplete = String(localized: "Investment Complete!")
    static let investmentPartialComplete = String(localized: "Investment Partially Complete")
    static let invested = String(localized: "invested")
    static let investmentSummary = String(localized: "Investment Summary")
    static let successfulOrders = String(localized: "Successful Orders")
    static let failedOrders = String(localized: "Failed Orders")
    static let orderDetails = String(localized: "Order Details")
    
    // Errors
    static let error = String(localized: "Error")
    static let noAccountFound = String(localized: "No account found. Please sign up first.")
    static let failedToLoadData = String(localized: "Failed to load account data")
    
    // Accessibility
    static let balanceCardAccessibility = String(localized: "Your wallet balance information")
    static let depositButtonAccessibility = String(localized: "Deposit funds into your account")
    static let withdrawButtonAccessibility = String(localized: "Withdraw funds from your account")
    static let transactionAccessibility = String(localized: "Transaction details")
    
    // Payment Methods
    static let knetTitle = String(localized: "KNET")
    static let creditCardTitle = String(localized: "Credit Card")
    static let bankWireTitle = String(localized: "Bank Wire")
    static let knetDescription = String(localized: "Instant • No Fees")
    static let creditCardDescription = String(localized: "Instant • 2.5% Fee")
    static let bankWireDescription = String(localized: "1-3 Days • KWD 5 Fee")
    static let selectPaymentMethod = String(localized: "Select Payment Method")
    static let payWithKnet = String(localized: "Pay with KNET")
    static let payWithCard = String(localized: "Pay with Card")
    static let initiateTransfer = String(localized: "Initiate Transfer")
    static let processingPayment = String(localized: "Processing Payment...")
    static let redirectingToKnet = String(localized: "Redirecting to KNET...")
    static let knetSecurePayment = String(localized: "Secure payment via Kuwait's trusted payment gateway")
    static let cardSecurePayment = String(localized: "Secure payment via encrypted card processing")
    static let wireTransferInstructions = String(localized: "Transfer funds directly from your bank account")
    static let popularInKuwait = String(localized: "Popular in Kuwait")
    static let instantDeposit = String(localized: "Instant Deposit")
}

