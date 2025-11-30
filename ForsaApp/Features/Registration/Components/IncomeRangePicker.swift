//
//  IncomeRangePicker.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Income range picker component
struct IncomeRangePicker: View {
    @Binding var selectedRange: IncomeRange?
    var label: String = "Annual Income"
    var subtitle: String? = "Select your approximate annual income"
    
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
            
            Button(action: { showPicker = true }) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primaryPurple)
                    
                    Text(selectedRange?.displayName ?? "Select income range")
                        .font(.inputText)
                        .foregroundColor(selectedRange == nil ? .textTertiary : .textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderPrimary, lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            IncomeRangePickerSheet(selectedRange: $selectedRange)
        }
    }
}

// MARK: - Income Range Picker Sheet

struct IncomeRangePickerSheet: View {
    @Binding var selectedRange: IncomeRange?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(IncomeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedRange = range
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(range.displayName)
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Spacer()
                            
                            if range == selectedRange {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Annual Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Income Range Card Selector

/// Card-based income range selector for visual selection
struct IncomeRangeCardSelector: View {
    @Binding var selectedRange: IncomeRange?
    var label: String = "Annual Income"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(IncomeRange.allCases, id: \.self) { range in
                    IncomeRangeCard(
                        range: range,
                        isSelected: range == selectedRange,
                        action: { selectedRange = range }
                    )
                }
            }
        }
    }
}

struct IncomeRangeCard: View {
    let range: IncomeRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.primaryPurple)
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text(range.displayName)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Visual indicator
                IncomeBarIndicator(range: range)
            }
            .padding(16)
            .background(isSelected ? Color.primaryPurple.opacity(0.05) : Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct IncomeBarIndicator: View {
    let range: IncomeRange
    
    private var fillLevel: CGFloat {
        switch range {
        case .under25k: return 0.14
        case .from25kTo50k: return 0.28
        case .from50kTo100k: return 0.42
        case .from100kTo200k: return 0.56
        case .from200kTo500k: return 0.70
        case .from500kTo1m: return 0.85
        case .over1m: return 1.0
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(CGFloat(index) < fillLevel * 7 ? Color.primaryPurple : Color.backgroundTertiary)
                    .frame(width: 4, height: 12)
            }
        }
    }
}

// MARK: - Net Worth Range Picker

struct NetWorthRangePicker: View {
    @Binding var selectedRange: NetWorthRange?
    var label: String = "Total Net Worth"
    var subtitle: String? = "Include all assets minus debts"
    
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
            
            Button(action: { showPicker = true }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primaryGreen)
                    
                    Text(selectedRange?.displayName ?? "Select net worth range")
                        .font(.inputText)
                        .foregroundColor(selectedRange == nil ? .textTertiary : .textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderPrimary, lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            NetWorthRangePickerSheet(selectedRange: $selectedRange)
        }
    }
}

struct NetWorthRangePickerSheet: View {
    @Binding var selectedRange: NetWorthRange?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info header
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primaryBlue)
                    
                    Text("Net worth = Total assets (property, investments, savings) minus total debts (loans, mortgages)")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
                .background(Color.primaryBlue.opacity(0.08))
                
                List {
                    ForEach(NetWorthRange.allCases, id: \.self) { range in
                        Button(action: {
                            selectedRange = range
                            dismiss()
                        }) {
                            HStack {
                                Text(range.displayName)
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                if range == selectedRange {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.body)
                                        .foregroundColor(.primaryPurple)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Net Worth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Previews

#Preview("Income Range Picker") {
    VStack(spacing: 24) {
        IncomeRangePicker(selectedRange: .constant(nil))
        IncomeRangePicker(selectedRange: .constant(.from100kTo200k))
    }
    .padding()
}

#Preview("Income Range Cards") {
    ScrollView {
        IncomeRangeCardSelector(selectedRange: .constant(.from50kTo100k))
            .padding()
    }
}

#Preview("Net Worth Picker") {
    VStack(spacing: 24) {
        NetWorthRangePicker(selectedRange: .constant(nil))
        NetWorthRangePicker(selectedRange: .constant(.from250kTo500k))
    }
    .padding()
}


