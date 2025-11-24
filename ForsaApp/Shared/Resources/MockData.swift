//
//  MockData.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct CompanyInfo: Hashable {
    let name: String
    let icon: String
    let color: Color
}

let mockTopCompanies: [CompanyInfo] = [
    CompanyInfo(name: "Microsoft", icon: "desktopcomputer", color: .blue),
    CompanyInfo(name: "Apple", icon: "apple.logo", color: .black),
    CompanyInfo(name: "Tesla", icon: "car.fill", color: .red),
    CompanyInfo(name: "Nvidia", icon: "cpu", color: .green),
    CompanyInfo(name: "Exxon", icon: "fuelpump.fill", color: .orange),
    CompanyInfo(name: "J&J", icon: "cross.case.fill", color: .red),
    CompanyInfo(name: "Pfizer", icon: "pills.fill", color: .blue),
    CompanyInfo(name: "Google", icon: "magnifyingglass", color: .blue)
]

