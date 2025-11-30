//
//  InvestmentResultView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct InvestmentResultView: View {
    let result: PortfolioInvestmentResult
    let depositAmount: Double
    let onDismiss: () -> Void
    
    // MARK: - State
    @State private var contentAppeared = false
    @State private var headerAnimated = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: WalletConstants.cardSpacing) {
                    // Header
                    headerSection
                        .scaleEffect(headerAnimated ? 1 : 0.8)
                        .opacity(headerAnimated ? 1 : 0)
                    
                    // Summary Card
                    summaryCard
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: WalletConstants.springResponse,
                                           dampingFraction: WalletConstants.springDamping)
                                   .delay(WalletConstants.cardAppearanceDelay),
                                   value: contentAppeared)
                    
                    // Order Details
                    orderDetailsCard
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.spring(response: WalletConstants.springResponse,
                                           dampingFraction: WalletConstants.springDamping)
                                   .delay(WalletConstants.cardAppearanceDelay * 2),
                                   value: contentAppeared)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(WalletStrings.investmentResultTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(WalletStrings.done) { onDismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
            .safeAreaInset(edge: .bottom) {
                ForsaButton(WalletStrings.viewPortfolio, style: .primary, size: .large) {
                    onDismiss()
                }
                .padding(.horizontal, WalletConstants.horizontalPadding)
                .padding(.bottom, 20)
                .background(Color.backgroundPrimary)
                .accessibilityLabel(WalletStrings.viewPortfolio)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    headerAnimated = true
                }
                withAnimation(.easeOut(duration: WalletConstants.fadeInDuration).delay(0.3)) {
                    contentAppeared = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        WalletSuccessHeader(
            isFullySuccessful: result.isFullySuccessful,
            title: result.isFullySuccessful ? WalletStrings.investmentComplete : WalletStrings.investmentPartialComplete,
            subtitle: "$\(String(format: "%.2f", result.totalInvested)) \(WalletStrings.invested)"
        )
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        ForsaCard {
            VStack(spacing: WalletConstants.sectionSpacing) {
                HStack {
                    Text(WalletStrings.investmentSummary)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                
                Divider()
                
                InvestmentSummaryRow(
                    label: WalletStrings.deposited,
                    value: "$\(String(format: "%.2f", depositAmount))",
                    valueColor: .textPrimary
                )
                
                InvestmentSummaryRow(
                    label: WalletStrings.invested,
                    value: "$\(String(format: "%.2f", result.totalInvested))",
                    valueColor: .successGreen
                )
                
                InvestmentSummaryRow(
                    label: WalletStrings.successfulOrders,
                    value: "\(result.successCount)",
                    valueColor: .successGreen
                )
                
                if result.failedCount > 0 {
                    InvestmentSummaryRow(
                        label: WalletStrings.failedOrders,
                        value: "\(result.failedCount)",
                        valueColor: .errorRed
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, WalletConstants.horizontalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(WalletStrings.investmentSummary)
    }
    
    // MARK: - Order Details Card
    
    private var orderDetailsCard: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: WalletConstants.sectionSpacing) {
                Text(WalletStrings.orderDetails)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                ForEach(Array(result.orderResults.enumerated()), id: \.element.id) { index, order in
                    OrderResultRow(order: order)
                    
                    if index < result.orderResults.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, WalletConstants.horizontalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(WalletStrings.orderDetails)
    }
}

// MARK: - Investment Summary Row

private struct InvestmentSummaryRow: View {
    let label: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.calloutMedium)
                .foregroundColor(valueColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Order Result Row

private struct OrderResultRow: View {
    let order: OrderResult
    
    private var statusIcon: String {
        switch order.status {
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch order.status {
        case .success: return .successGreen
        case .failed: return .errorRed
        case .skipped: return .textSecondary
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.caption)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(order.symbol)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                if let message = order.message {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", order.requestedAmount))")
                .font(.calloutMedium)
                .foregroundColor(statusColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(order.symbol): $\(String(format: "%.2f", order.requestedAmount)), \(order.status == .success ? "successful" : order.status == .failed ? "failed" : "skipped")")
    }
}

// MARK: - Preview

#Preview {
    InvestmentResultView(
        result: PortfolioInvestmentResult(
            totalInvested: 250,
            orderResults: [
                OrderResult(symbol: "AAPL", requestedAmount: 100, status: .success, message: nil, orderId: "order-1"),
                OrderResult(symbol: "MSFT", requestedAmount: 150, status: .success, message: nil, orderId: "order-2"),
                OrderResult(symbol: "AMZN", requestedAmount: 50, status: .failed, message: "Insufficient funds", orderId: nil)
            ],
            successCount: 2,
            failedCount: 1
        ),
        depositAmount: 300
    ) {
        print("Dismissed")
    }
}
