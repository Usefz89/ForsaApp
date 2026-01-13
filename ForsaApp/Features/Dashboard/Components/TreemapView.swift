//
//  TreemapView.swift
//  ForsaApp
//
//  Trading 212-style treemap layout for portfolio asset allocation
//

import SwiftUI

// MARK: - Treemap Data Model

struct TreemapItem: Identifiable {
    let id: String
    let symbol: String
    let marketValue: Double
    let allocationPercentage: Double
    let changePercentage: Double

    init(from position: AlpacaPosition, totalValue: Double) {
        self.id = position.id
        self.symbol = position.symbol
        self.marketValue = position.marketValueValue
        self.allocationPercentage = totalValue > 0 ? (position.marketValueValue / totalValue) * 100 : 0

        // Calculate gain/loss percentage
        let costBasis = Double(position.costBasis) ?? 0
        if costBasis > 0 {
            self.changePercentage = ((position.marketValueValue - costBasis) / costBasis) * 100
        } else {
            self.changePercentage = 0
        }
    }
}

// MARK: - Treemap Layout View (Grid-based, non-overlapping)

// MARK: - Treemap Layout View

// MARK: - Treemap Root View

private struct TreemapRootView: View {
    let items: [TreemapItem]
    let spacing: CGFloat

    var body: some View {
        GeometryReader { geometry in
            TreemapRecursiveView(items: items, canvasSize: geometry.size, spacing: spacing)
                .onAppear {
                    print("DEBUG: TreemapRecursiveView loaded with \(items.count) items")
                }
        }
    }
}

// MARK: - Recursive Treemap Splitter

private struct TreemapRecursiveView: View {
    let items: [TreemapItem]
    let canvasSize: CGSize
    let spacing: CGFloat

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else if items.count == 1, let item = items.first {
            // Leaf Node
            TreemapTile(
                symbol: item.symbol,
                allocationPercentage: item.allocationPercentage,
                changePercentage: item.changePercentage,
                marketValue: item.marketValue
            )
            .padding(spacing / 2) // Inner padding to create the gap
            .frame(width: canvasSize.width, height: canvasSize.height)
            .clipped() // CRITICAL: Prevents content from bleeding out of small tiles
            .contentShape(Rectangle())
            .onAppear { print("DEBUG: Leaf node for \(item.symbol) size: \(canvasSize)") }
        } else {
            // Branch Node - Perform Split
            let split = calculateSplit(items: items, size: canvasSize)
            
            if split.isHorizontalSplit {
                // Split Horizontally (Top / Bottom) - VStack
                VStack(spacing: 0) {
                    TreemapRecursiveView(
                        items: split.group1,
                        canvasSize: CGSize(width: canvasSize.width, height: split.size1),
                        spacing: spacing
                    )
                    TreemapRecursiveView(
                        items: split.group2,
                        canvasSize: CGSize(width: canvasSize.width, height: split.size2),
                        spacing: spacing
                    )
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
            } else {
                // Split Vertically (Left | Right) - HStack
                HStack(spacing: 0) {
                    TreemapRecursiveView(
                        items: split.group1,
                        canvasSize: CGSize(width: split.size1, height: canvasSize.height),
                        spacing: spacing
                    )
                    TreemapRecursiveView(
                        items: split.group2,
                        canvasSize: CGSize(width: split.size2, height: canvasSize.height),
                        spacing: spacing
                    )
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
            }
        }
    }
    
    // MARK: - Split Logic
    
    struct SplitResult {
        let group1: [TreemapItem]
        let group2: [TreemapItem]
        let size1: CGFloat
        let size2: CGFloat
        let isHorizontalSplit: Bool
    }
    
    private func calculateSplit(items: [TreemapItem], size: CGSize) -> SplitResult {
        let totalValue = items.reduce(0) { $0 + $1.marketValue }
        
        // Find best split index
        let halfValue = totalValue / 2
        var currentSum: Double = 0
        var splitIndex = 0
        
        for (i, item) in items.enumerated() {
            if currentSum + item.marketValue > halfValue {
                let diffInclude = abs((currentSum + item.marketValue) - halfValue)
                let diffExclude = abs(currentSum - halfValue)
                
                if diffInclude < diffExclude {
                    splitIndex = i + 1
                } else {
                    splitIndex = i
                }
                break
            }
            currentSum += item.marketValue
            splitIndex = i + 1
        }
        
        splitIndex = max(1, min(items.count - 1, splitIndex))
        
        let group1 = Array(items[0..<splitIndex])
        let group2 = Array(items[splitIndex..<items.count])
        
        let value1 = group1.reduce(0) { $0 + $1.marketValue }
        let fraction = totalValue > 0 ? CGFloat(value1 / totalValue) : 0.5
        
        // Decide split direction based on current aspect ratio
        // If width >= height, split vertical (HStack) to make children squarer
        // If width < height, split horizontal (VStack) to make children squarer
        let isHorizontalSplit = size.width < size.height
        
        let size1: CGFloat
        let size2: CGFloat
        
        if isHorizontalSplit {
            // Splitting Height (VStack)
            size1 = size.height * fraction
            size2 = max(0, size.height - size1)
        } else {
            // Splitting Width (HStack)
            size1 = size.width * fraction
            size2 = max(0, size.width - size1)
        }
        
        return SplitResult(
            group1: group1,
            group2: group2,
            size1: size1,
            size2: size2,
            isHorizontalSplit: isHorizontalSplit
        )
    }
}

// MARK: - Treemap View

// MARK: - Treemap View

struct AssetAllocationTreemapView: View {
    let positions: [AlpacaPosition]
    let spacing: CGFloat = 4 // Small spacing as requested

    private var items: [TreemapItem] {
        let totalValue = positions.reduce(0) { $0 + $1.marketValueValue }
        return positions
            .map { TreemapItem(from: $0, totalValue: totalValue) }
            .sorted { $0.marketValue > $1.marketValue }
    }

    var body: some View {
        TreemapRootView(items: items, spacing: spacing)
            .frame(height: 300) // Fixed height to ensure visibility in scrollviews
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: positions.count)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("2 Assets")
            .font(.caption)
        AssetAllocationTreemapView(positions: [])
            .frame(height: 200)

        Text("4 Assets")
            .font(.caption)
        AssetAllocationTreemapView(positions: [])
            .frame(height: 220)
    }
    .padding()
    .background(Color.backgroundSecondary)
}
