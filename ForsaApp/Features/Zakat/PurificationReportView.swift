//
//  PurificationReportView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct PurificationReportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Mock data for purification
    let totalDividends: Double = 485.75
    let purificationRate: Double = 0.045 // 4.5% average
    
    var purificationAmount: Double {
        totalDividends * purificationRate
    }
    
    let purificationItems: [PurificationItem] = [
        PurificationItem(symbol: "AAPL", name: "Apple Inc.", dividendAmount: 125.50, purificationRate: 0.02, purificationAmount: 2.51),
        PurificationItem(symbol: "MSFT", name: "Microsoft Corp.", dividendAmount: 210.25, purificationRate: 0.05, purificationAmount: 10.51),
        PurificationItem(symbol: "GOOGL", name: "Alphabet Inc.", dividendAmount: 150.00, purificationRate: 0.06, purificationAmount: 9.00)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    ForsaCard {
                        VStack(spacing: 16) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.primaryPurple)
                                .padding(.bottom, 8)
                            
                            Text("Dividend Purification")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Purification is the process of donating the small percentage of income derived from non-compliant sources (like interest) to charity.")
                                .font(.callout)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 16)
                    }
                    
                    // Summary Card
                    ForsaCard {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Total Dividends")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("$\(String(format: "%.2f", totalDividends))")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Purification Due")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text("$\(String(format: "%.2f", purificationAmount))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primaryPurple)
                            }
                            
                            Text("Based on an average rate of \(String(format: "%.1f", purificationRate * 100))%")
                                .font(.caption1)
                                .foregroundColor(.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    
                    // Breakdown Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Breakdown by Holding")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 4)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(purificationItems) { item in
                                PurificationItemRow(item: item)
                            }
                        }
                    }
                    
                    // Action Button
                    ForsaButton("Donate Purification Amount") {
                        // Action to donate
                    }
                    .padding(.top, 16)
                }
                .padding(20)
            }
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct PurificationItem: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let dividendAmount: Double
    let purificationRate: Double
    let purificationAmount: Double
}

struct PurificationItemRow: View {
    let item: PurificationItem
    
    var body: some View {
        ForsaCard(padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.symbol)
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                    
                    Text(item.name)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", item.purificationAmount))")
                        .font(.calloutMedium)
                        .foregroundColor(.primaryPurple)
                    
                    Text("\(String(format: "%.1f", item.purificationRate * 100))% Rate")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }
        }
    }
}

#Preview {
    PurificationReportView()
}
