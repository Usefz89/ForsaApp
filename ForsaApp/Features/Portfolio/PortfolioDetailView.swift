//
//  PortfolioDetailView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI
import Charts

struct PortfolioDetailView: View {
    let risk: RiskLevel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.backgroundSecondary)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "chart.pie.fill") // Placeholder icon
                                    .font(.title2)
                                    .foregroundColor(.primaryPurple)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(risk.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                
                                HStack {
                                    Text("Risk level:")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                    // Simple meter
                                    Capsule()
                                        .fill(Color.primaryGreen)
                                        .frame(width: 60, height: 6)
                                }
                            }
                            Spacer()
                            
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                        
                        Text(risk.description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .padding(.top, 8)
                            .lineLimit(nil)
                        
                        // Stats Rows
                        VStack(spacing: 12) {
                            HStack {
                                Text("Average Return : \(risk.averageReturn)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(8)
                            
                            HStack {
                                Text("Average Standard Deviation : \(risk.standardDeviation)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Image(systemName: "info.circle")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(8)
                        }
                        .padding(.top, 16)
                    }
                    .padding()
                    
                    // Asset Allocation (Donut)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Portfolio's Historical Performance")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal)
                        
                        Text("Based on a simulated investment of SAR 1,000")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(mockPerformanceData) { point in
                                AreaMark(
                                    x: .value("Year", point.date),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primaryPurple.opacity(0.6), .primaryPurple.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                LineMark(
                                    x: .value("Year", point.date),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(Color.primaryPurple)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            PerformanceStatCard(title: "Max historical annual return", value: "19.5%")
                            PerformanceStatCard(title: "Min historical annual return", value: "-16.1%")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Asset Allocation (Donut)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Asset Allocation")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ZStack {
                            Chart(risk.allocations) { allocation in
                                SectorMark(
                                    angle: .value("Percentage", allocation.percentage),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Asset", allocation.name))
                            }
                            .frame(height: 250)
                            .chartLegend(position: .bottom, spacing: 20)
                            
                            VStack {
                                Text("Stocks")
                                    .font(.headline)
                                    .foregroundColor(.textSecondary)
                                Text("40.00%") // Dynamic based on selection would be better
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Fund Distribution
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fund Distribution")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(risk.allocations) { allocation in
                                FundRow(allocation: allocation)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Top Companies (Logos)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Portfolio's Top Companies")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("This portfolio covers 1040+ companies, 17 sectors, Sukuk, real estate and gold.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                            ForEach(mockTopCompanies, id: \.self) { company in
                                VStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(height: 50)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                                        .overlay(
                                            Image(systemName: company.icon)
                                                .font(.title2)
                                                .foregroundColor(company.color)
                                        )
                                    
                                    Text(company.name)
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Map
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Portfolio Coverage")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("Portfolio coverage of 55 countries")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(height: 220)
                                .shadow(color: Color.black.opacity(0.05), radius: 4)
                            
                            Image(systemName: "globe.asia.australia.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 180)
                                .foregroundColor(.primaryPurple.opacity(0.8))
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Circle()
                                        .fill(Color.primaryPurple)
                                        .frame(width: 8, height: 8)
                                    Text("Developed Markets")
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                    
                                    Circle()
                                        .fill(Color.primaryGreen)
                                        .frame(width: 8, height: 8)
                                    Text("Emerging Markets")
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.bottom, 16)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Confirm Button
                    Button(action: {
                        // Logic to confirm
                    }) {
                        Text("Create your wallet now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryGreen)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

struct PerformanceStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

struct FundRow: View {
    let allocation: AssetAllocation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(allocation.name) (\(allocation.ticker))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(allocation.name) // Description placeholder
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: allocation.percentage)
                    .stroke(Color.primaryPurple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 32, height: 32)
                
                Text("\(Int(allocation.percentage * 100))%")
                    .font(.system(size: 8))
                    .bold()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.shadowLight, radius: 2, x: 0, y: 1)
    }
}

// Mock Data for Charts
struct PerformancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

let mockPerformanceData: [PerformancePoint] = {
    let calendar = Calendar.current
    let now = Date()
    return (0..<10).map { i in
        let date = calendar.date(byAdding: .year, value: -9 + i, to: now)!
        let value = 1000.0 * pow(1.08, Double(i)) // 8% growth
        return PerformancePoint(date: date, value: value)
    }
}()

