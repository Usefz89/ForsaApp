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
            let chartWidth = geometry.size.width
            let chartHeight = geometry.size.height
            let maxValue = projection.projectedValue
            let _ = projection.totalContributions

            ZStack {
                // Grid lines (horizontal)
                ForEach(0..<5) { index in
                    let y = chartHeight - (chartHeight * Double(index) / 4)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: chartWidth, y: chartWidth))
                    }
                    .stroke(Color.borderPrimary, lineWidth: 0.5)
                }

                // Contributions bars (grey)
                contributionsBars(projection: projection, width: chartWidth, height: chartHeight, maxValue: maxValue)

                // Projected value area (blue)
                projectedValueArea(projection: projection, width: chartWidth, height: chartHeight, maxValue: maxValue)

                // Y-axis labels
                yAxisLabels(maxValue: maxValue, height: chartHeight)

                // X-axis labels
                xAxisLabels(projection: projection, width: chartWidth, height: chartHeight)
            }
        }
    }

    private func contributionsBars(projection: InvestmentProjection, width: CGFloat, height: CGFloat, maxValue: Double) -> some View {
        let barWidth = width / CGFloat(projection.monthlyProjections.count)

        return ForEach(Array(projection.monthlyProjections.enumerated()), id: \.offset) { index, monthlyProjection in
            let barHeight = height * (monthlyProjection.totalContributions / maxValue)
            let xPosition = CGFloat(index) * barWidth

            Rectangle()
                .fill(Color.borderSecondary)
                .frame(width: max(barWidth - 2, 1), height: animateChart ? barHeight : 0)
                .position(
                    x: xPosition + barWidth / 2,
                    y: height - (animateChart ? barHeight / 2 : 0)
                )
                .animation(.easeOut(duration: 1.0).delay(Double(index) * 0.02), value: animateChart)
        }
    }

    private func projectedValueArea(projection: InvestmentProjection, width: CGFloat, height: CGFloat, maxValue: Double) -> some View {
        let points = projection.monthlyProjections.enumerated().map { index, monthlyProjection in
            let x = width * (Double(index) / Double(projection.monthlyProjections.count - 1))
            let y = height - (height * (monthlyProjection.projectedValue / maxValue))
            return CGPoint(x: x, y: y)
        }

        return ZStack {
            // Area fill
            if animateChart {
                Path { path in
                    guard let firstPoint = points.first else { return }

                    path.move(to: CGPoint(x: firstPoint.x, y: height))
                    path.addLine(to: firstPoint)

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
                            Color.primaryPurple.opacity(0.1),
                            Color.primaryPurple.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(.easeOut(duration: 1.5), value: animateChart)
            }

            // Line
            if animateChart {
                Path { path in
                    guard let firstPoint = points.first else { return }
                    path.move(to: firstPoint)

                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.primaryPurple, lineWidth: 3)
                .animation(.easeOut(duration: 1.2), value: animateChart)
            }
        }
    }

    private func yAxisLabels(maxValue: Double, height: CGFloat) -> some View {
        VStack {
            ForEach(0..<5) { index in
                let value = maxValue * Double(4 - index) / 4
                let formattedValue = formatCurrency(value)

                HStack {
                    Text(formattedValue)
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                        .frame(width: 60, alignment: .trailing)

                    Spacer()
                }
                .frame(height: height / 4)
            }
        }
        .offset(x: -70)
    }

    private func xAxisLabels(projection: InvestmentProjection, width: CGFloat, height: CGFloat) -> some View {
        let yearsToShow = min(projection.investmentDuration, 5)
        let interval = projection.investmentDuration / yearsToShow

        return HStack {
            ForEach(0..<yearsToShow + 1, id: \.self) { index in
                let year = index * interval
                Text("\(year)y")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)

                if index < yearsToShow {
                    Spacer()
                }
            }
        }
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
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Contributions")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Text(projection.formattedTotalContributions)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Projected Growth")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Text(projection.formattedTotalGains)
                    .font(.calloutMedium)
                    .foregroundColor(.gainGreen)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Final Value")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Text(projection.formattedProjectedValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryPurple)
            }
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