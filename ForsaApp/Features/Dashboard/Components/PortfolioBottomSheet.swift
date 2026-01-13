//
//  PortfolioBottomSheet.swift
//  ForsaApp
//
//  Trading 212-style slide-up bottom sheet for holdings and orders
//

import SwiftUI

struct PortfolioBottomSheet: View {
    let positions: [AlpacaPosition]
    let pendingOrders: [OpenOrder]
    let pendingOrdersSummary: PendingOrdersSummary
    let portfolioType: RiskLevel
    var onCancelAllOrders: (() -> Void)? = nil
    var onPortfolioTap: (() -> Void)? = nil

    @State private var currentHeight: CGFloat
    @State private var dragStartHeight: CGFloat = 0
    @State private var isExpandedState: Bool = false

    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat

    private var isExpanded: Bool {
        currentHeight > (collapsedHeight + expandedHeight) / 2
    }

    init(
        positions: [AlpacaPosition],
        pendingOrders: [OpenOrder],
        pendingOrdersSummary: PendingOrdersSummary,
        portfolioType: RiskLevel,
        onCancelAllOrders: (() -> Void)? = nil,
        onPortfolioTap: (() -> Void)? = nil,
        collapsedHeight: CGFloat = 280,
        expandedHeight: CGFloat = 600
    ) {
        self.positions = positions
        self.pendingOrders = pendingOrders
        self.pendingOrdersSummary = pendingOrdersSummary
        self.portfolioType = portfolioType
        self.onCancelAllOrders = onCancelAllOrders
        self.onPortfolioTap = onPortfolioTap
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        self._currentHeight = State(initialValue: collapsedHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle area
            dragHandleArea

            // Portfolio Type Header
            portfolioTypeHeader
                .padding(.horizontal, DashboardConstants.horizontalPadding)
                .padding(.bottom, 16)

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Pending Orders Section
                    if !pendingOrders.isEmpty {
                        pendingOrdersSection
                    }

                    // Asset Allocation / Treemap Section
                    if !positions.isEmpty {
                        treemapSection
                    }

                    // Empty state
                    if positions.isEmpty && pendingOrders.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, DashboardConstants.horizontalPadding)
                .padding(.bottom, 100)
            }
            .scrollDisabled(!isExpandedState)
        }
        .frame(height: currentHeight)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
    }

    // MARK: - Drag Handle Area

    private var dragHandleArea: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.textTertiary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // Hint text - use stable state to avoid layout jumps during drag
            Text(isExpandedState ? "Swipe down to collapse" : "Swipe up for more")
                .font(.caption2)
                .foregroundColor(.textTertiary)
                .padding(.bottom, 8)
                .animation(nil, value: isExpandedState)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.backgroundPrimary)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onChanged { value in
                    if dragStartHeight == 0 {
                        dragStartHeight = currentHeight
                    }
                    // Calculate new height from the starting position
                    let newHeight = dragStartHeight - value.translation.height
                    currentHeight = max(collapsedHeight, min(expandedHeight, newHeight))
                }
                .onEnded { value in
                    let velocity = value.predictedEndTranslation.height - value.translation.height

                    var targetExpanded: Bool

                    // Snap to expanded or collapsed based on position and velocity
                    if velocity < -150 {
                        // Fast swipe up -> expand
                        targetExpanded = true
                    } else if velocity > 150 {
                        // Fast swipe down -> collapse
                        targetExpanded = false
                    } else {
                        // Snap to nearest
                        let midpoint = (collapsedHeight + expandedHeight) / 2
                        targetExpanded = currentHeight > midpoint
                    }

                    let targetHeight = targetExpanded ? expandedHeight : collapsedHeight

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentHeight = targetHeight
                        isExpandedState = targetExpanded
                    }

                    // Reset drag start height
                    dragStartHeight = 0
                }
        )
    }

    // MARK: - Portfolio Type Header

    private var portfolioTypeHeader: some View {
        Button(action: { onPortfolioTap?() }) {
            HStack(spacing: 12) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(portfolioType.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: portfolioType.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(portfolioType.color)
                }

                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(portfolioType.title + " Portfolio")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)

                        if onPortfolioTap != nil {
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textTertiary)
                        }
                    }

                    Text(portfolioType.shortDescription)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Change button indicator
                if onPortfolioTap != nil {
                    Text("Change")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(portfolioType.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(portfolioType.color.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Pending Orders Section

    private var pendingOrdersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WAITING ORDERS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)

                Spacer()

                Text("\(pendingOrders.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.warningYellow)
                    .clipShape(Capsule())
            }

            ForsaCard(padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
                VStack(spacing: 0) {
                    ForEach(Array(pendingOrders.enumerated()), id: \.element.id) { index, order in
                        PendingOrderSheetRow(order: order)

                        if index < pendingOrders.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }

                    if onCancelAllOrders != nil {
                        Divider()
                            .padding(.vertical, 8)

                        Button(action: { onCancelAllOrders?() }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Cancel All")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.errorRed)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    // MARK: - Treemap Section

    private var treemapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ASSET ALLOCATION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)

                Spacer()

                Text("\(positions.count) assets")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            AssetAllocationTreemapView(positions: positions)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: positions.count)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)

            Text("No holdings yet")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("Your portfolio is empty. Start investing to see your holdings here.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Pending Order Sheet Row

private struct PendingOrderSheetRow: View {
    let order: OpenOrder

    var body: some View {
        HStack(spacing: 12) {
            // Symbol Badge
            ZStack {
                Circle()
                    .fill(Color.warningYellow.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(String(order.symbol.prefix(2)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.warningYellow)
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
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Pending")
                        .font(.caption)
                }
                .foregroundColor(.warningYellow)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rounded Corner Helper

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color.backgroundSecondary.ignoresSafeArea()

        VStack {
            Spacer()
            PortfolioBottomSheet(
                positions: [],
                pendingOrders: [],
                pendingOrdersSummary: .empty,
                portfolioType: .growth,
                collapsedHeight: 280,
                expandedHeight: 600
            )
        }
    }
}
