//
//  PendingOrdersCard.swift
//  ForsaApp
//
//  Displays pending orders that are waiting for market to open
//  Helps users understand why their funds appear "locked"
//

import SwiftUI

struct PendingOrdersCard: View {
    let summary: PendingOrdersSummary
    var onCancelAllTapped: (() -> Void)? = nil
    
    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerSection
                
                // Status message
                statusSection
                
                // Order list (if expanded)
                if !summary.orders.isEmpty {
                    orderListSection
                }
                
                // Cancel button (optional)
                if onCancelAllTapped != nil && !summary.orders.isEmpty {
                    cancelButton
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundColor(.warningYellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Orders Processing")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text(summary.formattedTotalAmount + " reserved")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Badge showing count
            Text("\(summary.pendingCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.warningYellow)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundColor(.infoBlue)
            
            Text("These orders will be executed when the market opens. Your funds are reserved until then.")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.infoBlue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Order List Section
    
    private var orderListSection: some View {
        VStack(spacing: 8) {
            ForEach(summary.orders) { order in
                PendingOrderRow(order: order)
            }
        }
    }
    
    // MARK: - Cancel Button
    
    private var cancelButton: some View {
        Button(action: { onCancelAllTapped?() }) {
            HStack {
                Image(systemName: "xmark.circle")
                Text("Cancel All Orders")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.errorRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.errorRed.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Pending Order Row

struct PendingOrderRow: View {
    let order: OpenOrder
    
    var body: some View {
        HStack(spacing: 12) {
            // Symbol icon
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Text(String(order.symbol.prefix(2)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryPurple)
            }
            
            // Order details
            VStack(alignment: .leading, spacing: 2) {
                Text(order.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(order.isBuyOrder ? "Buy Order" : "Sell Order")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Amount and status
            VStack(alignment: .trailing, spacing: 2) {
                Text(order.displayAmount)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: order.statusIcon)
                        .font(.caption2)
                    Text(order.statusDisplayName)
                        .font(.caption)
                }
                .foregroundColor(statusColor(for: order.orderStatus))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private func statusColor(for status: AlpacaOrderStatus) -> Color {
        switch status {
        case .new, .pendingNew, .accepted, .acceptedForBidding:
            return .warningYellow
        case .partiallyFilled:
            return .primaryPurple
        case .filled:
            return .successGreen
        case .canceled, .expired, .rejected:
            return .errorRed
        default:
            return .textSecondary
        }
    }
}

// MARK: - Compact Pending Orders Banner

/// A compact banner that can be shown at the top of the dashboard
struct PendingOrdersBanner: View {
    let summary: PendingOrdersSummary
    var onTapped: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTapped?() }) {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.warningYellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.statusMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(summary.formattedTotalAmount) reserved for orders")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.warningYellow.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.warningYellow.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Create sample orders for preview
        let sampleOrders = [
            OpenOrder(
                id: "1",
                clientOrderId: nil,
                symbol: "SPUS",
                qty: nil,
                notional: "130.00",
                filledQty: "0",
                filledAvgPrice: nil,
                side: "buy",
                type: "market",
                timeInForce: "day",
                status: "accepted",
                createdAt: "2025-11-27T11:01:00Z",
                updatedAt: nil,
                submittedAt: nil,
                assetClass: "us_equity"
            ),
            OpenOrder(
                id: "2",
                clientOrderId: nil,
                symbol: "UMMA",
                qty: nil,
                notional: "81.25",
                filledQty: "0",
                filledAvgPrice: nil,
                side: "buy",
                type: "market",
                timeInForce: "day",
                status: "accepted",
                createdAt: "2025-11-27T11:01:00Z",
                updatedAt: nil,
                submittedAt: nil,
                assetClass: "us_equity"
            )
        ]
        
        let summary = PendingOrdersSummary(orders: sampleOrders)
        
        PendingOrdersCard(summary: summary) {
            print("Cancel all tapped")
        }
        
        PendingOrdersBanner(summary: summary) {
            print("Banner tapped")
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}



