//
//  TradingViewChart.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI
import Charts

struct TradingViewChart: View {
    let chartData: [ChartDataPoint]
    let selectedTimeframe: TimeFrame
    let isPositive: Bool
    var isFullWidth: Bool = false

    @State private var selectedDataPoint: ChartDataPoint?

    private var chartColor: Color {
        isPositive ? .gainGreen : .lossRed
    }

    /// Stable Y-domain so 1D doesn't look "zoomed in" when the value range is tiny.
    /// Uses range-based padding with a minimum relative padding around the midpoint.
    private var yDomain: ClosedRange<Double> {
        guard let rawMin = chartData.map({ $0.value }).min(),
              let rawMax = chartData.map({ $0.value }).max() else {
            return 0...1
        }

        let range = rawMax - rawMin
        let mid = (rawMax + rawMin) / 2

        // If range is very small (common in 1D), the chart looks overly "zoomed".
        // Add a minimum padding relative to the current value.
        let minRelativePadding = max(abs(mid) * 0.005, 1) // ~0.5% of value, at least $1
        let rangePadding = max(range * 0.15, minRelativePadding)

        // If all points are identical, create a minimal visible domain.
        if range == 0 {
            return (mid - minRelativePadding)...(mid + minRelativePadding)
        }

        return (rawMin - rangePadding)...(rawMax + rangePadding)
    }

    private var currentPrice: Double {
        chartData.last?.value ?? 0
    }

    private var highPrice: Double {
        chartData.map { $0.value }.max() ?? 0
    }

    private var lowPrice: Double {
        chartData.map { $0.value }.min() ?? 0
    }

    private var openPrice: Double {
        chartData.first?.value ?? 0
    }

    var body: some View {
        VStack(spacing: 8) {
            // OHLC-style info bar (like TradingView top bar) - only show if not full width mode
            if !isFullWidth {
                ohlcInfoBar
            }

            // Crosshair overlay for full-width mode
            if isFullWidth, let selected = selectedDataPoint {
                crosshairOverlay(selected: selected)
            }

            // Main Chart
            if isFullWidth {
                fullWidthChart
            } else {
                mainChart
            }
        }
        // Charts can sometimes render marks slightly outside their bounds during layout changes.
        // Clipping prevents the 1D chart from visually bleeding into the timeframe selector.
        .clipped()
    }

    // MARK: - Crosshair Overlay (for full-width mode)

    private func crosshairOverlay(selected: ChartDataPoint) -> some View {
        HStack {
            Text(formatCompactPrice(selected.value))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(chartColor)

            Text(formatCrosshairDate(selected.date))
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .padding(.horizontal, DashboardConstants.horizontalPadding)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - OHLC Info Bar

    private var ohlcInfoBar: some View {
        HStack(spacing: 16) {
            // Open
            VStack(alignment: .leading, spacing: 2) {
                Text("O")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.textTertiary)
                Text(formatCompactPrice(openPrice))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.textSecondary)
            }

            // High
            VStack(alignment: .leading, spacing: 2) {
                Text("H")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.textTertiary)
                Text(formatCompactPrice(highPrice))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gainGreen)
            }

            // Low
            VStack(alignment: .leading, spacing: 2) {
                Text("L")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.textTertiary)
                Text(formatCompactPrice(lowPrice))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.lossRed)
            }

            // Close/Current
            VStack(alignment: .leading, spacing: 2) {
                Text("C")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.textTertiary)
                Text(formatCompactPrice(currentPrice))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(chartColor)
            }

            Spacer()

            // Crosshair date display
            if let selected = selectedDataPoint {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCompactPrice(selected.value))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(chartColor)
                    Text(formatCrosshairDate(selected.date))
                        .font(.system(size: 9))
                        .foregroundColor(.textSecondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Full Width Chart (Trading 212 style - no axes)

    private var fullWidthChart: some View {
        Chart {
            // Main line
            ForEach(chartData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            // Area gradient
            ForEach(chartData) { data in
                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [chartColor.opacity(0.3), chartColor.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Crosshair vertical line & point
            if let selected = selectedDataPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(Color.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(.white)
                .symbolSize(60)

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(chartColor)
                .symbolSize(35)
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .frame(height: 200)
        .contentShape(Rectangle())
        .chartOverlay { proxy in
            GeometryReader { _ in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let date: Date = proxy.value(atX: x) {
                                    let closest = chartData.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                    withAnimation(.easeInOut(duration: 0.08)) {
                                        selectedDataPoint = closest
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedDataPoint = nil
                                }
                            }
                    )
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selectedDataPoint?.id)
    }

    // MARK: - Main Chart (Original with axes)

    private var mainChart: some View {
        Chart {
            // Current price reference line (horizontal dashed line)
            RuleMark(y: .value("Current", currentPrice))
                .foregroundStyle(chartColor.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

            // Main line
            ForEach(chartData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            // Area gradient
            ForEach(chartData) { data in
                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [chartColor.opacity(0.25), chartColor.opacity(0.08), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Crosshair vertical line & point
            if let selected = selectedDataPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(Color.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(.white)
                .symbolSize(60)

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(chartColor)
                .symbolSize(35)
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.borderLight.opacity(0.4))
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatAxisPrice(doubleValue))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: getAxisValues()) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.borderLight.opacity(0.25))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisLabel(date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }
        }
        .frame(height: 180)
        .contentShape(Rectangle())
        .chartOverlay { proxy in
            GeometryReader { _ in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let date: Date = proxy.value(atX: x) {
                                    let closest = chartData.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                    withAnimation(.easeInOut(duration: 0.08)) {
                                        selectedDataPoint = closest
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedDataPoint = nil
                                }
                            }
                    )
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selectedDataPoint?.id)
    }
    
    // MARK: - Axis Value Calculations
    
    private func getAxisValues() -> AxisMarkValues {
        switch selectedTimeframe {
        case .oneDay:
            return .automatic(desiredCount: 6)
        case .oneWeek:
            return .automatic(desiredCount: 7)
        case .oneMonth:
            return .automatic(desiredCount: 5)
        case .threeMonths:
            return .automatic(desiredCount: 4)
        case .oneYear:
            return .automatic(desiredCount: 6)
        }
    }
    
    // MARK: - Formatting Functions
    
    private func formatAxisLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeframe {
        case .oneDay:
            formatter.dateFormat = "ha"
            return formatter.string(from: date).lowercased()
        case .oneWeek:
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        case .oneMonth:
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        case .threeMonths:
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        case .oneYear:
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }
    
    private func formatCrosshairDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeframe {
        case .oneDay:
            formatter.dateFormat = "h:mm a"
        case .oneWeek:
            formatter.dateFormat = "EEEE, h:mm a"
        case .oneMonth:
            formatter.dateFormat = "MMM d, h:mm a"
        case .threeMonths, .oneYear:
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatCompactPrice(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: "$%.1fK", value / 1000)
        } else if value >= 1000 {
            return String(format: "$%.2fK", value / 1000)
        } else {
            return String(format: "$%.2f", value)
        }
    }
    
    private func formatAxisPrice(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: "$%.0fK", value / 1000)
        } else if value >= 1000 {
            return String(format: "$%.1fK", value / 1000)
        } else if value >= 100 {
            return String(format: "$%.0f", value)
        } else {
            return String(format: "$%.1f", value)
        }
    }
}


