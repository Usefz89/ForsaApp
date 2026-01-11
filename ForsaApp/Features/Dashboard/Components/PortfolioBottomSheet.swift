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
    var onCancelAllOrders: (() -> Void)? = nil

    @State private var searchText = ""
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
        onCancelAllOrders: (() -> Void)? = nil,
        collapsedHeight: CGFloat = 280,
        expandedHeight: CGFloat = 600
    ) {
        self.positions = positions
        self.pendingOrders = pendingOrders
        self.pendingOrdersSummary = pendingOrdersSummary
        self.onCancelAllOrders = onCancelAllOrders
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        self._currentHeight = State(initialValue: collapsedHeight)
    }

    private var filteredPositions: [AlpacaPosition] {
        if searchText.isEmpty {
            return positions
        }
        return positions.filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle area
            dragHandleArea

            // Search bar
            searchBar

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Pending Orders Section
                    if !pendingOrders.isEmpty {
                        pendingOrdersSection
                    }

                    // Asset Allocation / Holdings Section
                    if !positions.isEmpty {
                        holdingsSection
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


    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textTertiary)

            TextField("Search portfolio", text: $searchText)
                .font(.body)
                .foregroundColor(.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal, DashboardConstants.horizontalPadding)
        .padding(.bottom, 16)
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

    // MARK: - Holdings Section

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ASSET ALLOCATION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)

                Spacer()

                Text("\(filteredPositions.count) assets")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            ForsaCard(padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
                VStack(spacing: 0) {
                    ForEach(Array(filteredPositions.enumerated()), id: \.element.id) { index, position in
                        HoldingSheetRow(position: position)

                        if index < filteredPositions.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
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

// MARK: - Holding Sheet Row

private struct HoldingSheetRow: View {
    let position: AlpacaPosition

    private var gainLoss: Double {
        position.marketValueValue - (Double(position.costBasis) ?? 0)
    }

    private var gainLossPercentage: Double {
        let costBasis = Double(position.costBasis) ?? 0
        guard costBasis > 0 else { return 0 }
        return (gainLoss / costBasis) * 100
    }

    private var isPositive: Bool {
        gainLoss >= 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Symbol Badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text(String(position.symbol.prefix(2)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryPurple)
            }

            // Symbol & Quantity
            VStack(alignment: .leading, spacing: 2) {
                Text(position.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text("\(String(format: "%.4f", position.qtyValue)) shares")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Value & Change
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", position.marketValueValue))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 2) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)

                    Text("\(isPositive ? "+" : "")\(String(format: "%.2f", gainLossPercentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(isPositive ? .gainGreen : .lossRed)
            }
        }
        .padding(.vertical, 4)
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
                collapsedHeight: 280,
                expandedHeight: 600
            )
        }
    }
}
