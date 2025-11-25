//
//  HoldingRow.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct HoldingRow: View {
    let position: AlpacaPosition
    
    private var gainLoss: Double {
        position.marketValueValue - (Double(position.costBasis) ?? 0)
    }
    
    private var gainLossPercentage: Double {
        let costBasis = Double(position.costBasis) ?? 0
        guard costBasis > 0 else { return 0 }
        return (gainLoss / costBasis) * 100
    }
    
    private var isPositive: Bool {
        gainLoss >= 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Symbol Badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(String(position.symbol.prefix(2)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryPurple)
            }
            
            // Symbol & Quantity
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("\(String(format: "%.4f", position.qtyValue)) shares")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Value & Change
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", position.marketValueValue))")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 2) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    
                    Text("\(isPositive ? "+" : "")\(String(format: "%.2f", gainLossPercentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(isPositive ? .gainGreen : .lossRed)
            }
        }
        .padding(.vertical, 4)
    }
}

