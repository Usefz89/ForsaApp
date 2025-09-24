//
//  PieChartView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct PieChartView: View {
    let allocations: [PieAllocation]
    let isInteractive: Bool
    let onAllocationTapped: ((PieAllocation) -> Void)?

    @State private var selectedAllocation: PieAllocation?
    @State private var animateChart: Bool = false

    private let chartSize: CGFloat = 200
    private let strokeWidth: CGFloat = 40

    init(allocations: [PieAllocation], isInteractive: Bool = false, onAllocationTapped: ((PieAllocation) -> Void)? = nil) {
        self.allocations = allocations
        self.isInteractive = isInteractive
        self.onAllocationTapped = onAllocationTapped
    }

    var body: some View {
        VStack(spacing: 20) {
            // Donut Chart
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.borderPrimary, lineWidth: strokeWidth)
                    .frame(width: chartSize, height: chartSize)

                // Chart segments
                ForEach(Array(allocations.enumerated()), id: \.element.stockId) { index, allocation in
                    PieSegmentView(
                        allocation: allocation,
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        color: colorForIndex(index),
                        strokeWidth: strokeWidth,
                        isSelected: selectedAllocation?.stockId == allocation.stockId,
                        animationProgress: animateChart ? 1.0 : 0.0
                    )
                    .frame(width: chartSize, height: chartSize)
                    .onTapGesture {
                        if isInteractive {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedAllocation = selectedAllocation?.stockId == allocation.stockId ? nil : allocation
                            }
                            onAllocationTapped?(allocation)
                        }
                    }
                }

                // Center content
                VStack(spacing: 4) {
                    if let selected = selectedAllocation {
                        Text(selected.symbol)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        Text("\(String(format: "%.1f", selected.percentage))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryPurple)
                    } else {
                        Text("Portfolio")
                            .font(.callout)
                            .foregroundColor(.textSecondary)

                        Text("\(allocations.count) stocks")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                    }
                }
                .frame(width: chartSize - strokeWidth - 20, height: chartSize - strokeWidth - 20)
                .contentTransition(.identity)
                .animation(.easeInOut(duration: 0.3), value: selectedAllocation?.stockId)
            }

            // Legend
            if !allocations.isEmpty {
                chartLegend
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateChart = true
            }
        }
    }

    private var chartLegend: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(Array(allocations.enumerated()), id: \.element.stockId) { index, allocation in
                HStack(spacing: 8) {
                    Circle()
                        .fill(colorForIndex(index))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(allocation.symbol)
                            .font(.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        Text("\(String(format: "%.1f", allocation.percentage))%")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selectedAllocation?.stockId == allocation.stockId ?
                    Color.primaryPurple.opacity(0.1) :
                    Color.backgroundSecondary
                )
                .cornerRadius(8)
                .scaleEffect(selectedAllocation?.stockId == allocation.stockId ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedAllocation?.stockId)
                .onTapGesture {
                    if isInteractive {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedAllocation = selectedAllocation?.stockId == allocation.stockId ? nil : allocation
                        }
                        onAllocationTapped?(allocation)
                    }
                }
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = allocations.prefix(index).reduce(0) { $0 + $1.percentage }
        return Angle.degrees(-90 + (previousPercentages / 100) * 360)
    }

    private func endAngle(for index: Int) -> Angle {
        let previousPercentages = allocations.prefix(index + 1).reduce(0) { $0 + $1.percentage }
        return Angle.degrees(-90 + (previousPercentages / 100) * 360)
    }

    private func colorForIndex(_ index: Int) -> Color {
        let colors = Color.chartColors
        return colors[index % colors.count]
    }
}

struct PieSegmentView: View {
    let allocation: PieAllocation
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let strokeWidth: CGFloat
    let isSelected: Bool
    let animationProgress: Double

    var body: some View {
        ZStack {
            // Main segment
            Circle()
                .trim(from: 0, to: animationProgress * (endAngle.degrees - startAngle.degrees) / 360)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(startAngle)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isSelected)

            // Selection highlight
            if isSelected {
                Circle()
                    .trim(from: 0, to: (endAngle.degrees - startAngle.degrees) / 360)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: strokeWidth + 4,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(startAngle)
                    .opacity(0.3)
                    .scaleEffect(1.05)
            }
        }
    }
}

// MARK: - Compact Pie Chart for smaller spaces
struct CompactPieChartView: View {
    let allocations: [PieAllocation]
    let size: CGFloat

    private var strokeWidth: CGFloat {
        size * 0.15
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.borderPrimary, lineWidth: strokeWidth)
                .frame(width: size, height: size)

            // Chart segments
            ForEach(Array(allocations.enumerated()), id: \.element.stockId) { index, allocation in
                Circle()
                    .trim(from: trimFrom(for: index), to: trimTo(for: index))
                    .stroke(
                        colorForIndex(index),
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(Angle.degrees(-90))
                    .frame(width: size, height: size)
            }

            // Center content
            VStack(spacing: 2) {
                Text("\(allocations.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("stocks")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private func trimFrom(for index: Int) -> CGFloat {
        let previousPercentages = allocations.prefix(index).reduce(0) { $0 + $1.percentage }
        return previousPercentages / 100
    }

    private func trimTo(for index: Int) -> CGFloat {
        let previousPercentages = allocations.prefix(index + 1).reduce(0) { $0 + $1.percentage }
        return previousPercentages / 100
    }

    private func colorForIndex(_ index: Int) -> Color {
        let colors = Color.chartColors
        return colors[index % colors.count]
    }
}

// MARK: - Preview
#Preview {
    let sampleAllocations = [
        PieAllocation(stockId: UUID(), symbol: "AAPL", name: "Apple Inc.", percentage: 35.0),
        PieAllocation(stockId: UUID(), symbol: "MSFT", name: "Microsoft Corp.", percentage: 25.0),
        PieAllocation(stockId: UUID(), symbol: "GOOGL", name: "Alphabet Inc.", percentage: 20.0),
        PieAllocation(stockId: UUID(), symbol: "NVDA", name: "NVIDIA Corp.", percentage: 15.0),
        PieAllocation(stockId: UUID(), symbol: "AMZN", name: "Amazon.com Inc.", percentage: 5.0)
    ]

    return VStack(spacing: 40) {
        Text("Interactive Pie Chart")
            .font(.title2)
            .fontWeight(.bold)

        PieChartView(
            allocations: sampleAllocations,
            isInteractive: true
        ) { allocation in
            print("Tapped: \(allocation.symbol)")
        }

        HStack(spacing: 20) {
            CompactPieChartView(allocations: sampleAllocations, size: 80)
            CompactPieChartView(allocations: sampleAllocations, size: 120)
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}