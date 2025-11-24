//
//  User.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let profileImageURL: String?
    let isVerified: Bool
    let createdAt: Date
    let totalPortfolioValue: Double
    let totalGainLoss: Double
    let totalGainLossPercentage: Double
    let followersCount: Int
    let followingCount: Int
    let isPublicProfile: Bool
    
    // Onboarding & KYC
    let hasCompletedKYC: Bool
    let psychologicalRiskScore: Int?
    let goals: [Goal]

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }

    init(id: UUID = UUID(), email: String, firstName: String, lastName: String, profileImageURL: String? = nil, isVerified: Bool = false, createdAt: Date = Date(), totalPortfolioValue: Double = 0, totalGainLoss: Double = 0, totalGainLossPercentage: Double = 0, followersCount: Int = 0, followingCount: Int = 0, isPublicProfile: Bool = false, hasCompletedKYC: Bool = false, psychologicalRiskScore: Int? = nil, goals: [Goal] = []) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageURL = profileImageURL
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.totalPortfolioValue = totalPortfolioValue
        self.totalGainLoss = totalGainLoss
        self.totalGainLossPercentage = totalGainLossPercentage
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.isPublicProfile = isPublicProfile
        self.hasCompletedKYC = hasCompletedKYC
        self.psychologicalRiskScore = psychologicalRiskScore
        self.goals = goals
    }
}

extension User {
    static let demo = User(
        email: "demo@forsa.app",
        firstName: "Ahmed",
        lastName: "Al-Mansouri",
        isVerified: true,
        totalPortfolioValue: 0,
        totalGainLoss: 0,
        totalGainLossPercentage: 0,
        followersCount: 128,
        followingCount: 45,
        isPublicProfile: true,
        hasCompletedKYC: false,
        psychologicalRiskScore: nil,
        goals: []
    )
}