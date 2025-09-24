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
            let chartWidth = geometry.size.width - 80 // Leave space for Y-axis labels
            let chartHeight = geometry.size.height - 40 // Leave space for X-axis labels
            let maxValue = projection.projectedValue

            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.backgroundCard,
                        Color.backgroundSecondary.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)

                // Grid lines (horizontal)
                ForEach(0..<5) { index in
                    let y = chartHeight - (chartHeight * Double(index) / 4)
                    Path { path in
                        path.move(to: CGPoint(x: 60, y: y))
                        path.addLine(to: CGPoint(x: chartWidth + 60, y: y)) // Fixed the bug - was using chartWidth as y
                    }
                    .stroke(Color.borderPrimary.opacity(0.5), lineWidth: 1)
                    .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.1), value: animateChart)
                }

                // Contributions bars (grey)
                contributionsBars(projection: projection, width: chartWidth, height: chartHeight, maxValue: maxValue)

                // Projected value area (purple gradient)
                projectedValueArea(projection: projection, width: chartWidth, height: chartHeight, maxValue: maxValue)

                // Y-axis labels
                yAxisLabels(maxValue: maxValue, height: chartHeight)

                // X-axis labels
                xAxisLabels(projection: projection, width: chartWidth, height: chartHeight)

                // Interactive elements
                if animateChart {
                    interactiveLayer(projection: projection, width: chartWidth, height: chartHeight, maxValue: maxValue)
                }
            }
            .clipped()
        }
    }

    private func contributionsBars(projection: InvestmentProjection, width: CGFloat, height: CGFloat, maxValue: Double) -> some View {
        let barWidth = width / CGFloat(projection.monthlyProjections.count)
        let barSpacing: CGFloat = 2

        return ForEach(Array(projection.monthlyProjections.enumerated()), id: \.offset) { index, monthlyProjection in
            let barHeight = height * (monthlyProjection.totalContributions / maxValue)
            let xPosition = 60 + CGFloat(index) * barWidth

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.borderSecondary.opacity(0.8),
                            Color.borderSecondary.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: max(barWidth - barSpacing, 1), height: animateChart ? barHeight : 0)
                .position(
                    x: xPosition + barWidth / 2,
                    y: height - (animateChart ? barHeight / 2 : 0)
                )
                .cornerRadius(2)
                .animation(.easeOut(duration: 1.2).delay(Double(index) * 0.03), value: animateChart)
        }
    }

    private func projectedValueArea(projection: InvestmentProjection, width: CGFloat, height: CGFloat, maxValue: Double) -> some View {
        let points = projection.monthlyProjections.enumerated().map { index, monthlyProjection in
            let x = 60 + width * (Double(index) / max(Double(projection.monthlyProjections.count - 1), 1))
            let y = height - (height * (monthlyProjection.projectedValue / maxValue))
            return CGPoint(x: x, y: y)
        }

        return ZStack {
            // Area fill with enhanced gradient
            if animateChart && !points.isEmpty {
                Path { path in
                    guard let firstPoint = points.first else { return }

                    path.move(to: CGPoint(x: firstPoint.x, y: height))
                    path.addLine(to: firstPoint)

                    // Use smooth curves instead of straight lines
                    if points.count > 1 {
                        for i in 1..<points.count {
                            let currentPoint = points[i]
                            if i == 1 {
                                path.addLine(to: currentPoint)
                            } else {
                                let previousPoint = points[i-1]
                                let controlPoint = CGPoint(
                                    x: (previousPoint.x + currentPoint.x) / 2,
                                    y: (previousPoint.y + currentPoint.y) / 2
                                )
                                path.addQuadCurve(to: currentPoint, control: controlPoint)
                            }
                        }
                    }

                    if let lastPoint = points.last {
                        path.addLine(to: CGPoint(x: lastPoint.x, y: height))
                    }

                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color.primaryPurple.opacity(0.4),
                            Color.primaryPurple.opacity(0.2),
                            Color.primaryPurple.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(.easeOut(duration: 1.8), value: animateChart)
            }

            // Enhanced line with glow effect
            if animateChart && !points.isEmpty {
                Path { path in
                    guard let firstPoint = points.first else { return }
                    path.move(to: firstPoint)

                    if points.count > 1 {
                        for i in 1..<points.count {
                            let currentPoint = points[i]
                            if i == 1 {
                                path.addLine(to: currentPoint)
                            } else {
                                let previousPoint = points[i-1]
                                let controlPoint = CGPoint(
                                    x: (previousPoint.x + currentPoint.x) / 2,
                                    y: (previousPoint.y + currentPoint.y) / 2
                                )
                                path.addQuadCurve(to: currentPoint, control: controlPoint)
                            }
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.primaryPurple,
                            Color.primaryPurpleDark
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: Color.primaryPurple.opacity(0.4), radius: 8, x: 0, y: 0)
                .animation(.easeOut(duration: 1.5), value: animateChart)
            }

            // Data points
            if animateChart {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(Color.primaryPurple)
                        .frame(width: 8, height: 8)
                        .position(point)
                        .scaleEffect(animateChart ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(1.0 + Double(index) * 0.05), value: animateChart)
                }
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
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                        .frame(width: 50, alignment: .trailing)

                    Spacer()
                }
                .frame(height: height / 4)
            }
        }
        .padding(.trailing, 10)
    }

    private func interactiveLayer(projection: InvestmentProjection, width: CGFloat, height: CGFloat, maxValue: Double) -> some View {
        // Milestone markers
        let milestones = [1, 5, 10, 15, 20, 25]
        let duration = projection.investmentDuration

        return ForEach(milestones.filter { $0 <= duration }, id: \.self) { year in
            let xPosition = 60 + width * (Double(year * 12) / Double(projection.monthlyProjections.count))
            let monthIndex = min(year * 12 - 1, projection.monthlyProjections.count - 1)
            let monthlyProjection = projection.monthlyProjections[monthIndex]
            let yPosition = height - (height * (monthlyProjection.projectedValue / maxValue))

            VStack(spacing: 4) {
                // Milestone line
                Path { path in
                    path.move(to: CGPoint(x: xPosition, y: 0))
                    path.addLine(to: CGPoint(x: xPosition, y: height))
                }
                .stroke(Color.primaryPurple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

                // Value tooltip at the milestone
                VStack(spacing: 2) {
                    Text(formatCurrency(monthlyProjection.projectedValue))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryPurple)

                    Text("\(year)y")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.backgroundCard)
                .cornerRadius(6)
                .shadow(color: Color.shadowLight, radius: 4, x: 0, y: 2)
                .position(x: xPosition, y: max(yPosition - 25, 25))
                .scaleEffect(animateChart ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.3).delay(2.0 + Double(year) * 0.1), value: animateChart)
            }
        }
    }

    private func xAxisLabels(projection: InvestmentProjection, width: CGFloat, height: CGFloat) -> some View {
        let yearsToShow = min(projection.investmentDuration, 6)
        let actualInterval = projection.investmentDuration <= 5 ? 1 : projection.investmentDuration / 5

        return HStack(alignment: .center, spacing: 0) {
            ForEach(0..<yearsToShow, id: \.self) { index in
                let year = index * actualInterval

                HStack {
                    Text(year == 0 ? "Now" : "\(year)y")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)

                    if index < yearsToShow - 1 {
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 60)
        .offset(y: height + 12)
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            // Total Contributions
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption1)
                            .foregroundColor(.borderSecondary)

                        Text("Contributions")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Spacer()
                    }

                    HStack {
                        Text(projection.formattedTotalContributions)
                            .font(.calloutMedium)
                            .foregroundColor(.textPrimary)

                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.backgroundSecondary)
                .cornerRadius(8)
            }

            // Projected Growth
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption1)
                            .foregroundColor(.gainGreen)

                        Text("Growth")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Spacer()
                    }

                    HStack {
                        Text(projection.formattedTotalGains)
                            .font(.calloutMedium)
                            .foregroundColor(.gainGreen)

                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.gainGreen.opacity(0.05))
                .cornerRadius(8)
            }

            // Final Value
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.caption1)
                            .foregroundColor(.primaryPurple)

                        Text("Final Value")
                            .font(.caption1)
                            .foregroundColor(.textSecondary)

                        Spacer()
                    }

                    HStack {
                        Text(projection.formattedProjectedValue)
                            .font(.calloutMedium)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryPurple)

                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.primaryPurple.opacity(0.08))
                .cornerRadius(8)
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