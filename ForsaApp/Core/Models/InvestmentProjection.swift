//
//  InvestmentProjection.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import Foundation

struct InvestmentProjection: Identifiable, Codable {
    let id: UUID
    let pieId: UUID
    let scenario: ProjectionScenario
    let initialDeposit: Double
    let monthlyContribution: Double
    let investmentDuration: Int // years
    let expectedReturn: Double // percentage
    let projectedValue: Double
    let totalContributions: Double
    let totalGains: Double
    let monthlyProjections: [MonthlyProjection]

    var formattedProjectedValue: String {
        "KWD \(String(format: "%.0f", projectedValue))"
    }

    var formattedTotalContributions: String {
        "KWD \(String(format: "%.0f", totalContributions))"
    }

    var formattedTotalGains: String {
        "KWD \(String(format: "%.0f", totalGains))"
    }

    var formattedTotalGainsPercentage: String {
        let percentage = totalContributions > 0 ? (totalGains / totalContributions) * 100 : 0
        return "+\(String(format: "%.1f", percentage))%"
    }

    init(pieId: UUID, scenario: ProjectionScenario, initialDeposit: Double, monthlyContribution: Double, investmentDuration: Int, pieAAR: Double) {
        self.id = UUID()
        self.pieId = pieId
        self.scenario = scenario
        self.initialDeposit = initialDeposit
        self.monthlyContribution = monthlyContribution
        self.investmentDuration = investmentDuration

        // Calculate expected return based on scenario
        switch scenario {
        case .conservative:
            self.expectedReturn = max(pieAAR - 2.0, 1.0) // Don't go below 1%
        case .expected:
            self.expectedReturn = pieAAR
        case .optimistic:
            self.expectedReturn = pieAAR + 2.0
        }

        // Calculate totals
        self.totalContributions = initialDeposit + (monthlyContribution * Double(investmentDuration * 12))

        // Calculate compound growth
        let monthlyRate = expectedReturn / 100 / 12
        let totalMonths = Double(investmentDuration * 12)

        // Future value of initial deposit
        let initialValue = initialDeposit * pow(1 + monthlyRate, totalMonths)

        // Future value of monthly contributions (annuity)
        let monthlyValue = monthlyContribution * ((pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate)

        self.projectedValue = initialValue + monthlyValue
        self.totalGains = projectedValue - totalContributions

        // Generate monthly projections
        var projections: [MonthlyProjection] = []
        var currentValue = initialDeposit
        var totalContributed = initialDeposit

        for month in 1...(investmentDuration * 12) {
            totalContributed += monthlyContribution
            currentValue = (currentValue + monthlyContribution) * (1 + monthlyRate)

            projections.append(MonthlyProjection(
                month: month,
                totalContributions: totalContributed,
                projectedValue: currentValue
            ))
        }

        self.monthlyProjections = projections
    }
}

struct MonthlyProjection: Identifiable, Codable {
    let id: UUID
    let month: Int
    let totalContributions: Double
    let projectedValue: Double

    init(month: Int, totalContributions: Double, projectedValue: Double) {
        self.id = UUID()
        self.month = month
        self.totalContributions = totalContributions
        self.projectedValue = projectedValue
    }
}

enum ProjectionScenario: String, CaseIterable, Codable {
    case conservative = "conservative"
    case expected = "expected"
    case optimistic = "optimistic"

    var displayName: String {
        switch self {
        case .conservative: return "Conservative"
        case .expected: return "Expected"
        case .optimistic: return "Optimistic"
        }
    }

    var description: String {
        switch self {
        case .conservative: return "Lower risk, steady growth"
        case .expected: return "Balanced risk and return"
        case .optimistic: return "Higher potential returns"
        }
    }

    var isDefault: Bool {
        self == .expected
    }
}

struct InvestmentGoal: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let suggestedDuration: Int // years
    let category: GoalCategory

    init(name: String, description: String, iconName: String, suggestedDuration: Int, category: GoalCategory) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.iconName = iconName
        self.suggestedDuration = suggestedDuration
        self.category = category
    }
}

enum GoalCategory: String, CaseIterable, Codable {
    case retirement = "retirement"
    case homeOwnership = "home_ownership"
    case emergency = "emergency"
    case travel = "travel"
    case education = "education"
    case general = "general"

    var displayName: String {
        switch self {
        case .retirement: return "Retirement"
        case .homeOwnership: return "Home Ownership"
        case .emergency: return "Emergency Fund"
        case .travel: return "Travel & Leisure"
        case .education: return "Education"
        case .general: return "General Investment"
        }
    }
}

// MARK: - Mock Data
extension InvestmentGoal {
    static let presetGoals: [InvestmentGoal] = [
        InvestmentGoal(
            name: "Retirement Fund",
            description: "Build wealth for your golden years",
            iconName: "figure.walk",
            suggestedDuration: 25,
            category: .retirement
        ),
        InvestmentGoal(
            name: "House Down Payment",
            description: "Save for your dream home",
            iconName: "house.fill",
            suggestedDuration: 5,
            category: .homeOwnership
        ),
        InvestmentGoal(
            name: "Emergency Fund",
            description: "Build a financial safety net",
            iconName: "shield.fill",
            suggestedDuration: 2,
            category: .emergency
        ),
        InvestmentGoal(
            name: "Vacation Fund",
            description: "Plan your next adventure",
            iconName: "airplane",
            suggestedDuration: 2,
            category: .travel
        ),
        InvestmentGoal(
            name: "Children's Education",
            description: "Invest in your children's future",
            iconName: "graduationcap.fill",
            suggestedDuration: 15,
            category: .education
        ),
        InvestmentGoal(
            name: "General Investment",
            description: "Build wealth over time",
            iconName: "chart.line.uptrend.xyaxis",
            suggestedDuration: 10,
            category: .general
        )
    ]
}

// MARK: - Update Portfolio Model
extension Portfolio {
    var averageAnnualReturn: Double {
        // Mock AAR calculation - in real app would be calculated from historical data
        switch name.lowercased() {
        case let name where name.contains("tech"):
            return 12.5
        case let name where name.contains("growth"):
            return 8.5
        case let name where name.contains("conservative"):
            return 6.5
        case let name where name.contains("sharia"):
            return 7.2
        default:
            return 8.0
        }
    }
}