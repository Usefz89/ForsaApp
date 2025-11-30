//
//  FundingSourceSelector.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Multi-select funding source selector
struct FundingSourceSelector: View {
    @Binding var selectedSources: [FundingSource]
    var label: String = "Funding Sources"
    var subtitle: String? = "Where will your investment funds come from?"
    var allowMultiple: Bool = true
    var minimumSelection: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    if allowMultiple {
                        Text("Select all that apply")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)
                    }
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Funding source grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(FundingSource.allCases) { source in
                    FundingSourceCard(
                        source: source,
                        isSelected: selectedSources.contains(source),
                        action: { toggleSource(source) }
                    )
                }
            }
            
            // Validation message
            if selectedSources.count < minimumSelection {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption1)
                    Text("Please select at least \(minimumSelection) source\(minimumSelection == 1 ? "" : "s")")
                        .font(.caption1)
                }
                .foregroundColor(.warningYellow)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption1)
                    Text("\(selectedSources.count) source\(selectedSources.count == 1 ? "" : "s") selected")
                        .font(.caption1)
                }
                .foregroundColor(.successGreen)
            }
        }
    }
    
    private func toggleSource(_ source: FundingSource) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selectedSources.contains(source) {
                selectedSources.removeAll { $0 == source }
            } else {
                if allowMultiple {
                    selectedSources.append(source)
                } else {
                    selectedSources = [source]
                }
            }
        }
    }
}

// MARK: - Funding Source Card

struct FundingSourceCard: View {
    let source: FundingSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.primaryPurple.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: source.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : .primaryPurple)
                }
                
                // Label
                Text(source.displayName)
                    .font(.caption1Medium)
                    .foregroundColor(isSelected ? .white : .textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.primaryPurple : Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.primaryPurple.opacity(0.2) : Color.clear, radius: 8, y: 4)
        }
        .buttonStyle(FundingSourceButtonStyle())
    }
}

struct FundingSourceButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Funding Source Selector

/// Chip-based compact funding source selector
struct CompactFundingSourceSelector: View {
    @Binding var selectedSources: [FundingSource]
    var label: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(FundingSource.allCases) { source in
                    FundingSourceChip(
                        source: source,
                        isSelected: selectedSources.contains(source),
                        action: { toggleSource(source) }
                    )
                }
            }
        }
    }
    
    private func toggleSource(_ source: FundingSource) {
        withAnimation(.spring(response: 0.2)) {
            if selectedSources.contains(source) {
                selectedSources.removeAll { $0 == source }
            } else {
                selectedSources.append(source)
            }
        }
    }
}

struct FundingSourceChip: View {
    let source: FundingSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: source.icon)
                    .font(.system(size: 12))
                
                Text(source.displayName)
                    .font(.caption1Medium)
            }
            .foregroundColor(isSelected ? .white : .textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primaryPurple : Color.backgroundCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: 1)
            )
        }
    }
}

// MARK: - Flow Layout (for chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, row) in result.rows.enumerated() {
            for item in row {
                let x = bounds.minX + item.x
                let y = bounds.minY + result.rowOffsets[index]
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }
    
    struct FlowResult {
        var rows: [[Item]] = []
        var rowOffsets: [CGFloat] = []
        var height: CGFloat = 0
        
        struct Item {
            var index: Int
            var size: CGSize
            var x: CGFloat
        }
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentRow: [Item] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > width && !currentRow.isEmpty {
                    rows.append(currentRow)
                    rowOffsets.append(currentY)
                    currentY += maxHeight + spacing
                    currentRow = []
                    currentX = 0
                    maxHeight = 0
                }
                
                currentRow.append(Item(index: index, size: size, x: currentX))
                currentX += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            if !currentRow.isEmpty {
                rows.append(currentRow)
                rowOffsets.append(currentY)
                currentY += maxHeight
            }
            
            height = currentY
        }
    }
}

// MARK: - List Style Funding Source Selector

/// List-style funding source selector with checkmarks
struct FundingSourceList: View {
    @Binding var selectedSources: [FundingSource]
    var label: String = "Funding Sources"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(Array(FundingSource.allCases.enumerated()), id: \.element.id) { index, source in
                    FundingSourceListRow(
                        source: source,
                        isSelected: selectedSources.contains(source),
                        action: { toggleSource(source) }
                    )
                    
                    if index < FundingSource.allCases.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
        }
    }
    
    private func toggleSource(_ source: FundingSource) {
        withAnimation(.spring(response: 0.2)) {
            if selectedSources.contains(source) {
                selectedSources.removeAll { $0 == source }
            } else {
                selectedSources.append(source)
            }
        }
    }
}

struct FundingSourceListRow: View {
    let source: FundingSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: source.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primaryPurple)
                    .frame(width: 32)
                
                // Label
                Text(source.displayName)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primaryPurple)
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Funding Source Grid") {
    ScrollView {
        FundingSourceSelector(
            selectedSources: .constant([.employmentIncome, .savings])
        )
        .padding()
    }
}

#Preview("Compact Chips") {
    CompactFundingSourceSelector(
        selectedSources: .constant([.employmentIncome]),
        label: "Funding Sources"
    )
    .padding()
}

#Preview("List Style") {
    ScrollView {
        FundingSourceList(
            selectedSources: .constant([.employmentIncome, .investments])
        )
        .padding()
    }
}



