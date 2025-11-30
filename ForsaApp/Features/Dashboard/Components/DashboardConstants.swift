//
//  DashboardConstants.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

enum DashboardConstants {
    // MARK: - Investment Thresholds
    static let minimumInvestmentAmount: Double = 1.0
    
    // MARK: - Layout
    static let horizontalPadding: CGFloat = 20
    static let tabBarBottomPadding: CGFloat = 100
    static let cardSpacing: CGFloat = 24
    static let sectionSpacing: CGFloat = 16
    
    // MARK: - Avatar & Icons
    static let avatarSize: CGFloat = 40
    static let loadingIconSize: CGFloat = 100
    static let portfolioIconSize: CGFloat = 50
    static let symbolBadgeSize: CGFloat = 44
    
    // MARK: - Risk Level Indicators
    static let riskIndicatorWidth: CGFloat = 16
    static let riskIndicatorHeight: CGFloat = 4
    static let maxRiskLevel: Int = 4
    
    // MARK: - Animation
    static let cardAppearanceDelay: Double = 0.05
    static let springResponse: Double = 0.5
    static let springDamping: Double = 0.8
    
    // MARK: - Chart
    static let chartHeight: CGFloat = 240
    static let emptyChartHeight: CGFloat = 240
}

// MARK: - Greeting Helper
enum TimeBasedGreeting {
    static var current: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return String(localized: "Good morning,")
        case 12..<17:
            return String(localized: "Good afternoon,")
        case 17..<21:
            return String(localized: "Good evening,")
        default:
            return String(localized: "Good night,")
        }
    }
}

