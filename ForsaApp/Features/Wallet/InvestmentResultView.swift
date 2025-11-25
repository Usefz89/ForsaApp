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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Summary Card
                    summaryCard
                    
                    // Order Details
                    orderDetailsCard
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Investment Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
            .safeAreaInset(edge: .bottom) {
                ForsaButton("View Portfolio", style: .primary, size: .large) {
                    onDismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(Color.backgroundPrimary)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(result.isFullySuccessful ? Color.successGreen.opacity(0.2) : Color.warningYellow.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: result.isFullySuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(result.isFullySuccessful ? .successGreen : .warningYellow)
            }
            
            Text(result.isFullySuccessful ? "Investment Complete!" : "Investment Partially Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text("$\(String(format: "%.2f", result.totalInvested)) invested")
                .font(.title3)
                .foregroundColor(.primaryPurple)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        ForsaCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Investment Summary")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    Text("Deposited")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", depositAmount))")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                }
                
                HStack {
                    Text("Invested")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", result.totalInvested))")
                        .font(.calloutMedium)
                        .foregroundColor(.successGreen)
                }
                
                HStack {
                    Text("Successful Orders")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(result.successCount)")
                        .font(.calloutMedium)
                        .foregroundColor(.successGreen)
                }
                
                if result.failedCount > 0 {
                    HStack {
                        Text("Failed Orders")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("\(result.failedCount)")
                            .font(.calloutMedium)
                            .foregroundColor(.errorRed)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Order Details Card
    
    private var orderDetailsCard: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Order Details")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                ForEach(result.orderResults) { order in
                    HStack {
                        Image(systemName: orderStatusIcon(order.status))
                            .font(.caption)
                            .foregroundColor(orderStatusColor(order.status))
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.symbol)
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            if let message = order.message {
                                Text(message)
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", order.requestedAmount))")
                            .font(.calloutMedium)
                            .foregroundColor(orderStatusColor(order.status))
                    }
                    
                    if order.id != result.orderResults.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helpers
    
    private func orderStatusIcon(_ status: OrderResultStatus) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
    
    private func orderStatusColor(_ status: OrderResultStatus) -> Color {
        switch status {
        case .success: return .successGreen
        case .failed: return .errorRed
        case .skipped: return .textSecondary
        }
    }
}

