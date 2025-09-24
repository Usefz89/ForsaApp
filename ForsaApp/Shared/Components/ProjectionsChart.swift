//
//  ProjectionsChart.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct ProjectionsChart: View {
    let projections: [InvestmentProjection]
    let selectedScenario: ProjectionScenario
    @State private var animateChart: Bool = false

    private var selectedProjection: InvestmentProjection? {
        projections.first { $0.scenario == selectedScenario }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let projection = selectedProjection {
                chartContent(for: projection)
            } else {
                emptyState
            }
        }
    }

    private func chartContent(for projection: InvestmentProjection) -> some View {
        VStack(spacing: 16) {
            // Chart area
            chartView(for: projection)
                .frame(height: 200)
                .padding(.horizontal, 20)

            // Legend
            chartLegend
                .padding(.horizontal, 20)

            // Key metrics
            metricsView(for: projection)
                .padding(.horizontal, 20)
        }
    }

    private func chartView(for projection: InvestmentProjection) -> some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width - 70 // Leave space for Y-axis labels
            let chartHeight = geometry.size.height - 30 // Leave space for X-axis labels
            let maxValue = projection.projectedValue

            ZStack {
                // Clean white background
                Color.backgroundCard
                    .cornerRadius(12)

                // Subtle grid lines (horizontal)
                ForEach(0..<5) { index in
                    let y = chartHeight - (chartHeight * Double(index) / 4)
                    Path { path in
                        path.move(to: CGPoint(x: 50, y: y))
                        path.addLine(to: CGPoint(x: chartWidth + 50, y: y))
                    }
                    .stroke(Color.borderPrimary.opacity(0.3), lineWidth: 0.5)
                    .opacity(animateChart ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateChart)
                }

                // Contributions bars (simplified)
                contributionsBars(projection: projection, width: chartWidth, height: chartHeight, maxValue: maxValue)

                // Projected value area (clean design matching reference)
                projectedValueArea(projection: projection, width: chartWidth, height: chartHeight, maxValue: maxValue)

                // Y-axis labels (cleaner positioning)
                yAxisLabels(maxValue: maxValue, height: chartHeight)

                // X-axis labels (simpler design)
                xAxisLabels(projection: projection, width: chartWidth, height: chartHeight)
            }
            .clipped()
        }
    }

    private func contributionsBars(projection: InvestmentProjection, width: CGFloat, height: CGFloat, maxValue: Double) -> some View {
        let barWidth = width / CGFloat(projection.monthlyProjections.count)
        let barSpacing: CGFloat = 1

        return ForEach(Array(projection.monthlyProjections.enumerated()), id: \.offset) { index, monthlyProjection in
            let barHeight = height * (monthlyProjection.totalContributions / maxValue)
            let xPosition = 50 + CGFloat(index) * barWidth

            Rectangle()
                .fill(Color.borderSecondary.opacity(0.6))
                .frame(width: max(barWidth - barSpacing, 1), height: animateChart ? barHeight : 0)
                .position(
                    x: xPosition + barWidth / 2,
                    y: height - (animateChart ? barHeight / 2 : 0)
                )
                .cornerRadius(1)
                .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.02), value: animateChart)
        }
    }

    private func projectedValueArea(projection: InvestmentProjection, width: CGFloat, height: CGFloat, maxValue: Double) -> some View {
        let points = projection.monthlyProjections.enumerated().map { index, monthlyProjection in
            let x = 50 + width * (Double(index) / max(Double(projection.monthlyProjections.count - 1), 1))
            let y = height - (height * (monthlyProjection.projectedValue / maxValue))
            return CGPoint(x: x, y: y)
        }

        return ZStack {
            // Clean area fill matching reference image
            if animateChart && !points.isEmpty {
                Path { path in
                    guard let firstPoint = points.first else { return }

                    path.move(to: CGPoint(x: firstPoint.x, y: height))
                    path.addLine(to: firstPoint)

                    // Simple linear connections for clarity
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }

                    if let lastPoint = points.last {
                        path.addLine(to: CGPoint(x: lastPoint.x, y: height))
                    }

                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color.primaryPurple.opacity(0.3),
                            Color.primaryPurple.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(.easeOut(duration: 1.0), value: animateChart)
            }

            // Clean line matching reference
            if animateChart && !points.isEmpty {
                Path { path in
                    guard let firstPoint = points.first else { return }
                    path.move(to: firstPoint)

                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.primaryPurple, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .animation(.easeOut(duration: 1.0), value: animateChart)
            }
        }
    }

    private func yAxisLabels(maxValue: Double, height: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(0..<5) { index in
                let value = maxValue * Double(4 - index) / 4
                let formattedValue = formatCurrency(value)

                HStack {
                    Text(formattedValue)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .frame(width: 45, alignment: .trailing)

                    Spacer()
                }
                .frame(height: height / 4)
            }
        }
        .padding(.trailing, 5)
    }


    private func xAxisLabels(projection: InvestmentProjection, width: CGFloat, height: CGFloat) -> some View {
        let yearsToShow = min(projection.investmentDuration, 5)
        let interval = max(1, projection.investmentDuration / (yearsToShow - 1))

        return HStack(alignment: .center, spacing: 0) {
            ForEach(0..<yearsToShow, id: \.self) { index in
                let year = index * interval

                Text(year == 0 ? "Now" : "\(year)y")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)

                if index < yearsToShow - 1 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 50)
        .offset(y: height + 8)
    }

    private var chartLegend: some View {
        HStack(spacing: 24) {
            // Contributions legend
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.borderSecondary)
                    .frame(width: 16, height: 12)
                    .cornerRadius(2)

                Text("Contributions")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }

            // Projected value legend
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.primaryPurple)
                    .frame(width: 16, height: 12)
                    .cornerRadius(2)

                Text("Projected Value")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
    }

    private func metricsView(for projection: InvestmentProjection) -> some View {
        VStack(spacing: 12) {
            // Total Contributions - Single Line
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption1)
                    .foregroundColor(.borderSecondary)

                Text("Contributions:")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text(projection.formattedTotalContributions)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.backgroundSecondary)
            .cornerRadius(8)

            // Projected Growth - Single Line
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption1)
                    .foregroundColor(.gainGreen)

                Text("Growth:")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text(projection.formattedTotalGains)
                    .font(.calloutMedium)
                    .foregroundColor(.gainGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gainGreen.opacity(0.05))
            .cornerRadius(8)

            // Final Value - Single Line
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.caption1)
                    .foregroundColor(.primaryPurple)

                Text("Final Value:")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text(projection.formattedProjectedValue)
                    .font(.calloutMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryPurple)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primaryPurple.opacity(0.08))
            .cornerRadius(8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.textMuted)

            Text("No projection data available")
                .font(.callout)
                .foregroundColor(.textSecondary)
        }
        .frame(height: 200)
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000000 {
            return "\(String(format: "%.1f", value / 1000000))M"
        } else if value >= 1000 {
            return "\(String(format: "%.0f", value / 1000))K"
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Scenario Toggle
struct ProjectionScenarioToggle: View {
    @Binding var selectedScenario: ProjectionScenario

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProjectionScenario.allCases, id: \.self) { scenario in
                Button(action: {
                    selectedScenario = scenario
                }) {
                    VStack(spacing: 4) {
                        Text(scenario.displayName)
                            .font(.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(selectedScenario == scenario ? .primaryPurple : .textSecondary)

                        Text(getScenarioReturn(scenario))
                            .font(.caption2)
                            .foregroundColor(selectedScenario == scenario ? .primaryPurple : .textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedScenario == scenario ?
                        Color.primaryPurple.opacity(0.1) :
                        Color.clear
                    )
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
    }

    private func getScenarioReturn(_ scenario: ProjectionScenario) -> String {
        // Mock returns - in real app would come from actual data
        switch scenario {
        case .conservative: return "6.5%"
        case .expected: return "8.5%"
        case .optimistic: return "10.5%"
        }
    }
}

// MARK: - Preview
#Preview {
    let mockProjections = [
        InvestmentProjection(
            pieId: UUID(),
            scenario: .conservative,
            initialDeposit: 1000,
            monthlyContribution: 200,
            investmentDuration: 5,
            pieAAR: 8.5
        ),
        InvestmentProjection(
            pieId: UUID(),
            scenario: .expected,
            initialDeposit: 1000,
            monthlyContribution: 200,
            investmentDuration: 5,
            pieAAR: 8.5
        ),
        InvestmentProjection(
            pieId: UUID(),
            scenario: .optimistic,
            initialDeposit: 1000,
            monthlyContribution: 200,
            investmentDuration: 5,
            pieAAR: 8.5
        )
    ]

    return VStack(spacing: 24) {
        ProjectionScenarioToggle(selectedScenario: .constant(.expected))

        ProjectionsChart(
            projections: mockProjections,
            selectedScenario: .expected
        )
        .onAppear {
            // Trigger animation
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}