//
//  PortfolioPerformanceCard.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

struct PortfolioPerformanceCard: View {
    let portfolioValue: String
    let isPositive: Bool
    let changeText: String
    let totalInvested: Double
    let totalGainLossText: String
    let availableBalanceText: String
    let chartData: [ChartDataPoint]
    let selectedTimeframe: TimeFrame
    let onTimeframeChanged: (TimeFrame) -> Void
    
    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 20) {
                valueSection
                statsSection
                chartSection
                TimeframeSelector(
                    selectedTimeframe: selectedTimeframe,
                    isPositive: isPositive,
                    onSelect: onTimeframeChanged
                )
            }
            .padding(4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Portfolio performance")
    }
    
    // MARK: - Value Section
    
    private var valueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Portfolio Value")
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            Text(portfolioValue)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .contentTransition(.numericText())
                .accessibilityLabel("Portfolio value: \(portfolioValue)")
            
            changeIndicator
        }
    }
    
    private var changeIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isPositive ? .gainGreen : .lossRed)
                .accessibilityHidden(true)
            
            Text(changeText)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .gainGreen : .lossRed)
            
            Text("All time")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Change: \(changeText), all time")
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatItem(
                title: "Invested",
                value: "$\(String(format: "%.2f", totalInvested))",
                valueColor: .textPrimary
            )
            
            StatItem(
                title: "Gain/Loss",
                value: totalGainLossText,
                valueColor: isPositive ? .gainGreen : .lossRed
            )
            
            StatItem(
                title: "Available Balance",
                value: availableBalanceText,
                valueColor: .textPrimary
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        if !chartData.isEmpty {
            TradingViewChart(
                chartData: chartData,
                selectedTimeframe: selectedTimeframe,
                isPositive: isPositive
            )
            // Keep the chart area consistent across timeframes (1D labels/data shouldn't
            // change layout height or bleed into the selector).
            .frame(height: DashboardConstants.chartHeight)
            .clipped()
            // Bring back a smooth transition without animating the chart domain (which causes zoom glitches).
            .id(selectedTimeframe)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.22), value: selectedTimeframe)
            .accessibilityLabel("Portfolio performance chart for \(selectedTimeframe.displayName)")
        } else {
            emptyChartPlaceholder
        }
    }
    
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.textTertiary)
            Text("No chart data available")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(height: DashboardConstants.emptyChartHeight)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
        .accessibilityLabel("No chart data available")
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Timeframe Selector

struct TimeframeSelector: View {
    let selectedTimeframe: TimeFrame
    let isPositive: Bool
    let onSelect: (TimeFrame) -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                TimeframeButton(
                    timeframe: timeframe,
                    isSelected: selectedTimeframe == timeframe,
                    isPositive: isPositive,
                    onTap: { onSelect(timeframe) }
                )
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: selectedTimeframe)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Timeframe selector")
    }
}

private struct TimeframeButton: View {
    let timeframe: TimeFrame
    let isSelected: Bool
    let isPositive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(timeframe.displayName)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isPositive ? Color.gainGreen : Color.lossRed)
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : .textSecondary)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(timeframe.displayName) timeframe")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        PortfolioPerformanceCard(
            portfolioValue: "$25,420.50",
            isPositive: true,
            changeText: "+$2,840.30 (+12.6%)",
            totalInvested: 22580.20,
            totalGainLossText: "+$2,840.30",
            availableBalanceText: "$500.00",
            chartData: [],
            selectedTimeframe: .oneWeek,
            onTimeframeChanged: { _ in }
        )
        .padding()
    }
}

