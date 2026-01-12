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

// MARK: - Treemap View

struct TreemapView: View {
    let positions: [AlpacaPosition]
    let spacing: CGFloat = 6

    private var items: [TreemapItem] {
        let totalValue = positions.reduce(0) { $0 + $1.marketValueValue }
        return positions
            .map { TreemapItem(from: $0, totalValue: totalValue) }
            .sorted { $0.marketValue > $1.marketValue }
    }

    var body: some View {
        GeometryReader { geometry in
            let layoutRects = calculateTreemapLayout(
                items: items,
                in: CGRect(origin: .zero, size: geometry.size)
            )

            ZStack(alignment: .topLeading) {
                ForEach(Array(zip(items.indices, items)), id: \.1.id) { index, item in
                    if index < layoutRects.count {
                        let rect = layoutRects[index]
                        // Inset each tile by half spacing on all sides to create gaps
                        let insetRect = rect.insetBy(dx: spacing / 2, dy: spacing / 2)

                        TreemapTile(
                            symbol: item.symbol,
                            allocationPercentage: item.allocationPercentage,
                            changePercentage: item.changePercentage,
                            marketValue: item.marketValue
                        )
                        .frame(
                            width: max(0, insetRect.width),
                            height: max(0, insetRect.height)
                        )
                        .offset(
                            x: insetRect.minX,
                            y: insetRect.minY
                        )
                    }
                }
            }
        }
        .frame(height: calculateHeight(for: positions.count))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: positions.count)
    }

    // MARK: - Layout Calculation

    private func calculateHeight(for count: Int) -> CGFloat {
        switch count {
        case 0: return 0
        case 1: return 120
        case 2...4: return 220
        case 5...6: return 320
        default: return min(CGFloat(((count + 1) / 2) * 110), 450)
        }
    }

    private func calculateTreemapLayout(items: [TreemapItem], in rect: CGRect) -> [CGRect] {
        guard !items.isEmpty else { return [] }

        let count = items.count

        // Simple grid layouts for small counts
        switch count {
        case 1:
            return [rect]

        case 2:
            return layoutTwoItems(items: items, in: rect)

        case 3:
            return layoutThreeItems(items: items, in: rect)

        case 4:
            return layoutFourItems(items: items, in: rect)

        case 5:
            return layoutFiveItems(items: items, in: rect)

        case 6:
            return layoutSixItems(items: items, in: rect)

        default:
            return squarifiedLayout(items: items, in: rect)
        }
    }

    // Two items: side by side proportionally
    private func layoutTwoItems(items: [TreemapItem], in rect: CGRect) -> [CGRect] {
        let total = items.reduce(0) { $0 + $1.marketValue }
        guard total > 0 else { return [rect, rect] }

        let ratio1 = items[0].marketValue / total
        let width1 = rect.width * ratio1

        return [
            CGRect(x: rect.minX, y: rect.minY, width: width1, height: rect.height),
            CGRect(x: rect.minX + width1, y: rect.minY, width: rect.width - width1, height: rect.height)
        ]
    }

    // Three items: one large on left, two stacked on right
    private func layoutThreeItems(items: [TreemapItem], in rect: CGRect) -> [CGRect] {
        let total = items.reduce(0) { $0 + $1.marketValue }
        guard total > 0 else {
            let w = rect.width / 2
            let h = rect.height / 2
            return [
                CGRect(x: rect.minX, y: rect.minY, width: w, height: rect.height),
                CGRect(x: rect.minX + w, y: rect.minY, width: w, height: h),
                CGRect(x: rect.minX + w, y: rect.minY + h, width: w, height: h)
            ]
        }

        let ratio1 = items[0].marketValue / total
        let leftWidth = max(rect.width * 0.4, min(rect.width * ratio1 * 1.2, rect.width * 0.65))

        let rightTotal = items[1].marketValue + items[2].marketValue
        let ratio2 = rightTotal > 0 ? items[1].marketValue / rightTotal : 0.5
        let topHeight = rect.height * ratio2

        return [
            CGRect(x: rect.minX, y: rect.minY, width: leftWidth, height: rect.height),
            CGRect(x: rect.minX + leftWidth, y: rect.minY, width: rect.width - leftWidth, height: topHeight),
            CGRect(x: rect.minX + leftWidth, y: rect.minY + topHeight, width: rect.width - leftWidth, height: rect.height - topHeight)
        ]
    }

    // Four items: 2x2 grid with proportional sizing
    private func layoutFourItems(items: [TreemapItem], in rect: CGRect) -> [CGRect] {
        let total = items.reduce(0) { $0 + $1.marketValue }
        guard total > 0 else {
            let halfWidth = rect.width / 2
            let halfHeight = rect.height / 2
            return [
                CGRect(x: rect.minX, y: rect.minY, width: halfWidth, height: halfHeight),
                CGRect(x: rect.minX + halfWidth, y: rect.minY, width: halfWidth, height: halfHeight),
                CGRect(x: rect.minX, y: rect.minY + halfHeight, width: halfWidth, height: halfHeight),
                CGRect(x: rect.minX + halfWidth, y: rect.minY + halfHeight, width: halfWidth, height: halfHeight)
            ]
        }

        // Top row: items[0] and items[1]
        let topTotal = items[0].marketValue + items[1].marketValue
        let bottomTotal = items[2].marketValue + items[3].marketValue
        let topRatio = topTotal / total
        let topHeight = rect.height * topRatio
        let bottomHeight = rect.height - topHeight

        // Top row proportions
        let topLeftRatio = topTotal > 0 ? items[0].marketValue / topTotal : 0.5
        let topLeftWidth = rect.width * topLeftRatio
        let topRightWidth = rect.width - topLeftWidth

        // Bottom row proportions
        let bottomLeftRatio = bottomTotal > 0 ? items[2].marketValue / bottomTotal : 0.5
        let bottomLeftWidth = rect.width * bottomLeftRatio
        let bottomRightWidth = rect.width - bottomLeftWidth

        return [
            CGRect(x: rect.minX, y: rect.minY, width: topLeftWidth, height: topHeight),
            CGRect(x: rect.minX + topLeftWidth, y: rect.minY, width: topRightWidth, height: topHeight),
            CGRect(x: rect.minX, y: rect.minY + topHeight, width: bottomLeftWidth, height: bottomHeight),
            CGRect(x: rect.minX + bottomLeftWidth, y: rect.minY + topHeight, width: bottomRightWidth, height: bottomHeight)
        ]
    }

    // Five items: one large on top, four below in 2x2 with proportional sizing
    private func layoutFiveItems(items: [TreemapItem], in rect: CGRect) -> [CGRect] {
        let total = items.reduce(0) { $0 + $1.marketValue }
        guard total > 0 else {
            let topHeight = rect.height * 0.45
            let bottomHeight = rect.height - topHeight
            let halfWidth = rect.width / 2
            return [
                CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: topHeight),
                CGRect(x: rect.minX, y: rect.minY + topHeight, width: halfWidth, height: bottomHeight / 2),
                CGRect(x: rect.minX + halfWidth, y: rect.minY + topHeight, width: halfWidth, height: bottomHeight / 2),
                CGRect(x: rect.minX, y: rect.minY + topHeight + bottomHeight / 2, width: halfWidth, height: bottomHeight / 2),
                CGRect(x: rect.minX + halfWidth, y: rect.minY + topHeight + bottomHeight / 2, width: halfWidth, height: bottomHeight / 2)
            ]
        }

        // Top item takes proportional height based on its value
        let topRatio = items[0].marketValue / total
        let topHeight = max(rect.height * 0.3, min(rect.height * topRatio * 1.5, rect.height * 0.55))
        let bottomHeight = rect.height - topHeight

        // Bottom 4 items in 2x2 grid with proportional sizing
        let bottomItems = Array(items[1...4])
        let bottomTotal = bottomItems.reduce(0) { $0 + $1.marketValue }

        // Row 1 (items[1], items[2])
        let row1Total = items[1].marketValue + items[2].marketValue
        let row2Total = items[3].marketValue + items[4].marketValue
        let row1Ratio = bottomTotal > 0 ? row1Total / bottomTotal : 0.5
        let row1Height = bottomHeight * row1Ratio
        let row2Height = bottomHeight - row1Height

        let item1Ratio = row1Total > 0 ? items[1].marketValue / row1Total : 0.5
        let item1Width = rect.width * item1Ratio
        let item2Width = rect.width - item1Width

        let item3Ratio = row2Total > 0 ? items[3].marketValue / row2Total : 0.5
        let item3Width = rect.width * item3Ratio
        let item4Width = rect.width - item3Width

        return [
            CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: topHeight),
            CGRect(x: rect.minX, y: rect.minY + topHeight, width: item1Width, height: row1Height),
            CGRect(x: rect.minX + item1Width, y: rect.minY + topHeight, width: item2Width, height: row1Height),
            CGRect(x: rect.minX, y: rect.minY + topHeight + row1Height, width: item3Width, height: row2Height),
            CGRect(x: rect.minX + item3Width, y: rect.minY + topHeight + row1Height, width: item4Width, height: row2Height)
        ]
    }

    // Six items: 3x2 grid with proportional sizing
    private func layoutSixItems(items: [TreemapItem], in rect: CGRect) -> [CGRect] {
        let total = items.reduce(0) { $0 + $1.marketValue }
        guard total > 0 else {
            let colWidth = rect.width / 2
            let rowHeight = rect.height / 3
            return [
                CGRect(x: rect.minX, y: rect.minY, width: colWidth, height: rowHeight),
                CGRect(x: rect.minX + colWidth, y: rect.minY, width: colWidth, height: rowHeight),
                CGRect(x: rect.minX, y: rect.minY + rowHeight, width: colWidth, height: rowHeight),
                CGRect(x: rect.minX + colWidth, y: rect.minY + rowHeight, width: colWidth, height: rowHeight),
                CGRect(x: rect.minX, y: rect.minY + rowHeight * 2, width: colWidth, height: rowHeight),
                CGRect(x: rect.minX + colWidth, y: rect.minY + rowHeight * 2, width: colWidth, height: rowHeight)
            ]
        }

        // Calculate row totals
        let row1Total = items[0].marketValue + items[1].marketValue
        let row2Total = items[2].marketValue + items[3].marketValue
        let row3Total = items[4].marketValue + items[5].marketValue

        // Calculate row heights proportionally
        let row1Ratio = row1Total / total
        let row2Ratio = row2Total / total
        let row3Ratio = row3Total / total

        let row1Height = rect.height * row1Ratio
        let row2Height = rect.height * row2Ratio
        let row3Height = rect.height * row3Ratio

        // Calculate widths within each row
        let item0Ratio = row1Total > 0 ? items[0].marketValue / row1Total : 0.5
        let item0Width = rect.width * item0Ratio
        let item1Width = rect.width - item0Width

        let item2Ratio = row2Total > 0 ? items[2].marketValue / row2Total : 0.5
        let item2Width = rect.width * item2Ratio
        let item3Width = rect.width - item2Width

        let item4Ratio = row3Total > 0 ? items[4].marketValue / row3Total : 0.5
        let item4Width = rect.width * item4Ratio
        let item5Width = rect.width - item4Width

        let y1 = rect.minY
        let y2 = y1 + row1Height
        let y3 = y2 + row2Height

        return [
            CGRect(x: rect.minX, y: y1, width: item0Width, height: row1Height),
            CGRect(x: rect.minX + item0Width, y: y1, width: item1Width, height: row1Height),
            CGRect(x: rect.minX, y: y2, width: item2Width, height: row2Height),
            CGRect(x: rect.minX + item2Width, y: y2, width: item3Width, height: row2Height),
            CGRect(x: rect.minX, y: y3, width: item4Width, height: row3Height),
            CGRect(x: rect.minX + item4Width, y: y3, width: item5Width, height: row3Height)
        ]
    }

    // Squarified treemap algorithm for 7+ items
    private func squarifiedLayout(items: [TreemapItem], in rect: CGRect) -> [CGRect] {
        guard !items.isEmpty else { return [] }

        var results: [CGRect] = []
        var remainingRect = rect
        var remainingItems = items

        let totalValue = items.reduce(0) { $0 + $1.marketValue }
        guard totalValue > 0 else {
            // Equal distribution fallback
            let cols = 2
            let rows = (items.count + cols - 1) / cols
            let cellWidth = rect.width / CGFloat(cols)
            let cellHeight = rect.height / CGFloat(rows)

            for i in 0..<items.count {
                let row = i / cols
                let col = i % cols
                results.append(CGRect(
                    x: rect.minX + CGFloat(col) * cellWidth,
                    y: rect.minY + CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                ))
            }
            return results
        }

        while !remainingItems.isEmpty {
            let rowItems = getNextRow(
                items: remainingItems,
                totalValue: remainingItems.reduce(0) { $0 + $1.marketValue },
                containerRect: remainingRect
            )

            let rowRects = layoutRow(
                items: rowItems,
                totalValue: remainingItems.reduce(0) { $0 + $1.marketValue },
                containerRect: remainingRect
            )

            results.append(contentsOf: rowRects)
            remainingItems.removeFirst(rowItems.count)

            // Update remaining rect
            if !rowRects.isEmpty {
                let isHorizontal = remainingRect.width >= remainingRect.height
                if isHorizontal {
                    let usedWidth = rowRects.reduce(0) { $0 + $1.width }
                    remainingRect = CGRect(
                        x: remainingRect.minX + usedWidth,
                        y: remainingRect.minY,
                        width: remainingRect.width - usedWidth,
                        height: remainingRect.height
                    )
                } else {
                    let usedHeight = rowRects.first?.height ?? 0
                    remainingRect = CGRect(
                        x: remainingRect.minX,
                        y: remainingRect.minY + usedHeight,
                        width: remainingRect.width,
                        height: remainingRect.height - usedHeight
                    )
                }
            }
        }

        return results
    }

    private func getNextRow(items: [TreemapItem], totalValue: Double, containerRect: CGRect) -> [TreemapItem] {
        guard !items.isEmpty else { return [] }

        var row: [TreemapItem] = []
        var bestAspectRatio = CGFloat.infinity

        for item in items {
            let testRow = row + [item]
            let worstRatio = worstAspectRatio(for: testRow, totalValue: totalValue, containerRect: containerRect)

            if worstRatio < bestAspectRatio || row.isEmpty {
                row = testRow
                bestAspectRatio = worstRatio
            } else {
                break
            }
        }

        return row.isEmpty ? [items[0]] : row
    }

    private func worstAspectRatio(for items: [TreemapItem], totalValue: Double, containerRect: CGRect) -> CGFloat {
        guard !items.isEmpty, totalValue > 0 else { return .infinity }

        let rowValue = items.reduce(0) { $0 + $1.marketValue }
        let rowFraction = rowValue / totalValue
        let isHorizontal = containerRect.width >= containerRect.height

        let rowSize = isHorizontal
            ? containerRect.width * rowFraction
            : containerRect.height * rowFraction

        var worstRatio: CGFloat = 0

        for item in items {
            let itemFraction = item.marketValue / rowValue
            let itemSize = isHorizontal
                ? containerRect.height * itemFraction
                : containerRect.width * itemFraction

            let ratio = max(rowSize / itemSize, itemSize / rowSize)
            worstRatio = max(worstRatio, ratio)
        }

        return worstRatio
    }

    private func layoutRow(items: [TreemapItem], totalValue: Double, containerRect: CGRect) -> [CGRect] {
        guard !items.isEmpty, totalValue > 0 else { return [] }

        let rowValue = items.reduce(0) { $0 + $1.marketValue }
        let rowFraction = rowValue / totalValue
        let isHorizontal = containerRect.width >= containerRect.height

        var rects: [CGRect] = []
        var offset: CGFloat = 0

        if isHorizontal {
            let rowWidth = containerRect.width * rowFraction

            for item in items {
                let itemFraction = item.marketValue / rowValue
                let itemHeight = containerRect.height * itemFraction

                rects.append(CGRect(
                    x: containerRect.minX,
                    y: containerRect.minY + offset,
                    width: rowWidth,
                    height: itemHeight
                ))

                offset += itemHeight
            }
        } else {
            let rowHeight = containerRect.height * rowFraction

            for item in items {
                let itemFraction = item.marketValue / rowValue
                let itemWidth = containerRect.width * itemFraction

                rects.append(CGRect(
                    x: containerRect.minX + offset,
                    y: containerRect.minY,
                    width: itemWidth,
                    height: rowHeight
                ))

                offset += itemWidth
            }
        }

        return rects
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("2 Assets")
            .font(.caption)
        TreemapView(positions: [])
            .frame(height: 200)

        Text("4 Assets")
            .font(.caption)
        TreemapView(positions: [])
            .frame(height: 220)
    }
    .padding()
    .background(Color.backgroundSecondary)
}
