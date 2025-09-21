//
//  MockDataService.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import Foundation

class MockDataService {
    static let shared = MockDataService()

    private init() {}

    // MARK: - Users
    lazy var demoUsers: [User] = [
        User(
            email: "ahmed.mansouri@example.com",
            firstName: "Ahmed",
            lastName: "Al-Mansouri",
            isVerified: true,
            totalPortfolioValue: 25420.50,
            totalGainLoss: 2840.30,
            totalGainLossPercentage: 12.6,
            followersCount: 128,
            followingCount: 45,
            isPublicProfile: true
        ),
        User(
            email: "sara.khalil@example.com",
            firstName: "Sara",
            lastName: "Khalil",
            isVerified: true,
            totalPortfolioValue: 45780.25,
            totalGainLoss: 5420.80,
            totalGainLossPercentage: 13.4,
            followersCount: 256,
            followingCount: 78,
            isPublicProfile: true
        ),
        User(
            email: "omar.hassan@example.com",
            firstName: "Omar",
            lastName: "Hassan",
            isVerified: false,
            totalPortfolioValue: 12350.75,
            totalGainLoss: -850.25,
            totalGainLossPercentage: -6.4,
            followersCount: 45,
            followingCount: 23,
            isPublicProfile: true
        )
    ]

    // MARK: - Stocks
    lazy var halalStocks: [Stock] = [
        // GCC Stocks
        Stock(
            symbol: "KFH",
            name: "Kuwait Finance House",
            market: .kse,
            assetType: .stock,
            currentPrice: 0.92,
            previousClose: 0.89,
            marketCap: 8_500_000_000,
            volume: 2_500_000,
            sector: "Financial Services",
            industry: "Islamic Banking",
            description: "Kuwait's largest Islamic bank and a leading Islamic financial institution globally.",
            shariaCompliance: .compliant,
            currency: "KWD",
            dividendYield: 4.2,
            peRatio: 12.5,
            week52High: 1.05,
            week52Low: 0.78
        ),
        Stock(
            symbol: "2222.SR",
            name: "Saudi Aramco",
            market: .tadawul,
            assetType: .stock,
            currentPrice: 28.45,
            previousClose: 28.20,
            marketCap: 1_800_000_000_000,
            volume: 15_000_000,
            sector: "Energy",
            industry: "Oil & Gas",
            description: "World's largest oil company and most valuable company by market capitalization.",
            shariaCompliance: .compliant,
            currency: "SAR",
            dividendYield: 3.8,
            peRatio: 15.2,
            week52High: 35.50,
            week52Low: 25.80
        ),

        // US Tech Stocks (Halal-screened)
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            market: .nasdaq,
            assetType: .stock,
            currentPrice: 175.43,
            previousClose: 172.80,
            marketCap: 2_750_000_000_000,
            volume: 45_000_000,
            sector: "Technology",
            industry: "Consumer Electronics",
            description: "Multinational technology company that designs and manufactures consumer electronics.",
            shariaCompliance: .compliant,
            currency: "USD",
            dividendYield: 0.5,
            peRatio: 28.5,
            week52High: 198.23,
            week52Low: 124.17
        ),
        Stock(
            symbol: "MSFT",
            name: "Microsoft Corporation",
            market: .nasdaq,
            assetType: .stock,
            currentPrice: 298.75,
            previousClose: 295.20,
            marketCap: 2_240_000_000_000,
            volume: 28_000_000,
            sector: "Technology",
            industry: "Software",
            description: "Multinational technology corporation that develops software, services, and solutions.",
            shariaCompliance: .compliant,
            currency: "USD",
            dividendYield: 0.8,
            peRatio: 25.3,
            week52High: 348.10,
            week52Low: 213.43
        ),
        Stock(
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            market: .nasdaq,
            assetType: .stock,
            currentPrice: 132.45,
            previousClose: 130.80,
            marketCap: 1_650_000_000_000,
            volume: 32_000_000,
            sector: "Technology",
            industry: "Internet Services",
            description: "Multinational technology conglomerate holding company for Google and its subsidiaries.",
            shariaCompliance: .underReview,
            currency: "USD",
            dividendYield: 0.0,
            peRatio: 22.1,
            week52High: 151.55,
            week52Low: 83.34
        ),
        Stock(
            symbol: "NVDA",
            name: "NVIDIA Corporation",
            market: .nasdaq,
            assetType: .stock,
            currentPrice: 445.20,
            previousClose: 438.75,
            marketCap: 1_100_000_000_000,
            volume: 25_000_000,
            sector: "Technology",
            industry: "Semiconductors",
            description: "Multinational technology company that designs graphics processing units for gaming and AI.",
            shariaCompliance: .compliant,
            currency: "USD",
            dividendYield: 0.1,
            peRatio: 45.8,
            week52High: 502.66,
            week52Low: 108.13
        ),

        // Healthcare
        Stock(
            symbol: "JNJ",
            name: "Johnson & Johnson",
            market: .nyse,
            assetType: .stock,
            currentPrice: 162.35,
            previousClose: 161.20,
            marketCap: 425_000_000_000,
            volume: 8_500_000,
            sector: "Healthcare",
            industry: "Pharmaceuticals",
            description: "Multinational corporation that develops medical devices, pharmaceuticals, and consumer goods.",
            shariaCompliance: .nonCompliant,
            currency: "USD",
            dividendYield: 2.9,
            peRatio: 24.7,
            week52High: 181.83,
            week52Low: 143.13
        )
    ]

    // MARK: - ETFs
    lazy var halalETFs: [Stock] = [
        Stock(
            symbol: "HLAL",
            name: "Wahed FTSE USA Shariah ETF",
            market: .nasdaq,
            assetType: .etf,
            currentPrice: 45.80,
            previousClose: 45.20,
            marketCap: 250_000_000,
            volume: 125_000,
            sector: "Diversified",
            industry: "Sharia-Compliant ETF",
            description: "Tracks the performance of large and mid-cap US stocks that comply with Islamic investment principles.",
            shariaCompliance: .compliant,
            currency: "USD",
            dividendYield: 1.2,
            peRatio: nil,
            week52High: 52.45,
            week52Low: 38.90
        ),
        Stock(
            symbol: "SPUS",
            name: "SPDR Portfolio S&P 500 ETF",
            market: .nasdaq,
            assetType: .etf,
            currentPrice: 42.15,
            previousClose: 41.85,
            marketCap: 15_000_000_000,
            volume: 2_500_000,
            sector: "Diversified",
            industry: "Equity ETF",
            description: "Tracks the S&P 500 index with Sharia-compliant screening methodology.",
            shariaCompliance: .compliant,
            currency: "USD",
            dividendYield: 1.8,
            peRatio: nil,
            week52High: 48.90,
            week52Low: 35.20
        ),
        Stock(
            symbol: "IEMG",
            name: "iShares Core MSCI EM IMI ETF",
            market: .nasdaq,
            assetType: .etf,
            currentPrice: 48.95,
            previousClose: 48.40,
            marketCap: 45_000_000_000,
            volume: 8_750_000,
            sector: "Diversified",
            industry: "Emerging Markets ETF",
            description: "Provides exposure to emerging market equities with Islamic investment guidelines.",
            shariaCompliance: .compliant,
            currency: "USD",
            dividendYield: 2.4,
            peRatio: nil,
            week52High: 55.80,
            week52Low: 42.10
        )
    ]

    // MARK: - Portfolios
    lazy var communityPortfolios: [Portfolio] = [
        Portfolio(
            name: "Halal Tech Growth",
            description: "Focused on Sharia-compliant technology companies with strong growth potential",
            totalValue: 15_420.50,
            totalInvested: 12_500.00,
            holdings: [
                Holding(stockId: halalStocks[2].id, symbol: "AAPL", name: "Apple Inc.", shares: 25.5, averagePrice: 165.30, currentPrice: 175.43, allocation: 40.0),
                Holding(stockId: halalStocks[3].id, symbol: "MSFT", name: "Microsoft Corporation", shares: 12.8, averagePrice: 285.50, currentPrice: 298.75, allocation: 35.0),
                Holding(stockId: halalStocks[5].id, symbol: "NVDA", name: "NVIDIA Corporation", shares: 5.2, averagePrice: 380.20, currentPrice: 445.20, allocation: 25.0)
            ],
            isPublic: true,
            creatorId: demoUsers[0].id,
            likesCount: 89,
            copyCount: 23,
            autoInvestEnabled: true,
            autoInvestAmount: 500.0
        ),
        Portfolio(
            name: "GCC Dividend Kings",
            description: "High-yield dividend stocks from the Gulf region",
            totalValue: 8_750.25,
            totalInvested: 8_200.00,
            holdings: [
                Holding(stockId: halalStocks[0].id, symbol: "KFH", name: "Kuwait Finance House", shares: 5000, averagePrice: 0.85, currentPrice: 0.92, allocation: 50.0),
                Holding(stockId: halalStocks[1].id, symbol: "2222.SR", name: "Saudi Aramco", shares: 120, averagePrice: 26.80, currentPrice: 28.45, allocation: 50.0)
            ],
            isPublic: true,
            creatorId: demoUsers[1].id,
            likesCount: 156,
            copyCount: 67,
            autoInvestEnabled: true,
            autoInvestAmount: 300.0
        ),
        Portfolio(
            name: "Balanced Islamic",
            description: "Diversified portfolio across sectors following Islamic principles",
            totalValue: 22_180.75,
            totalInvested: 20_000.00,
            holdings: [
                Holding(stockId: halalStocks[2].id, symbol: "AAPL", name: "Apple Inc.", shares: 15.0, averagePrice: 170.00, currentPrice: 175.43, allocation: 20.0),
                Holding(stockId: halalStocks[3].id, symbol: "MSFT", name: "Microsoft Corporation", shares: 8.5, averagePrice: 290.00, currentPrice: 298.75, allocation: 20.0),
                Holding(stockId: halalStocks[0].id, symbol: "KFH", name: "Kuwait Finance House", shares: 2500, averagePrice: 0.88, currentPrice: 0.92, allocation: 15.0),
                Holding(stockId: halalETFs[0].id, symbol: "HLAL", name: "Wahed FTSE USA Shariah ETF", shares: 200, averagePrice: 42.50, currentPrice: 45.80, allocation: 25.0),
                Holding(stockId: halalETFs[2].id, symbol: "IEMG", name: "iShares Core MSCI EM IMI ETF", shares: 150, averagePrice: 46.00, currentPrice: 48.95, allocation: 20.0)
            ],
            isPublic: true,
            creatorId: demoUsers[2].id,
            likesCount: 234,
            copyCount: 89,
            autoInvestEnabled: false
        )
    ]

    // MARK: - Investment Pies
    lazy var investmentPies: [InvestmentPie] = [
        InvestmentPie(
            name: "Tech Leaders",
            description: "Top technology companies following Sharia principles",
            allocations: [
                PieAllocation(stockId: halalStocks[2].id, symbol: "AAPL", name: "Apple Inc.", percentage: 40.0),
                PieAllocation(stockId: halalStocks[3].id, symbol: "MSFT", name: "Microsoft Corporation", percentage: 35.0),
                PieAllocation(stockId: halalStocks[5].id, symbol: "NVDA", name: "NVIDIA Corporation", percentage: 25.0)
            ],
            totalInvested: 5000.0,
            autoInvestEnabled: true,
            autoInvestAmount: 250.0,
            rebalanceFrequency: .monthly
        ),
        InvestmentPie(
            name: "Regional Focus",
            description: "Focus on GCC market leaders",
            allocations: [
                PieAllocation(stockId: halalStocks[0].id, symbol: "KFH", name: "Kuwait Finance House", percentage: 60.0),
                PieAllocation(stockId: halalStocks[1].id, symbol: "2222.SR", name: "Saudi Aramco", percentage: 40.0)
            ],
            totalInvested: 3000.0,
            autoInvestEnabled: false,
            rebalanceFrequency: .quarterly
        )
    ]

    // MARK: - Helper Methods
    func getAllStocks() -> [Stock] {
        return halalStocks + halalETFs
    }

    func getHalalStocks() -> [Stock] {
        return getAllStocks().filter { $0.shariaCompliance == .compliant }
    }

    func getStocksByMarket(_ market: Market) -> [Stock] {
        return getAllStocks().filter { $0.market == market }
    }

    func getStocksByAssetType(_ assetType: AssetType) -> [Stock] {
        return getAllStocks().filter { $0.assetType == assetType }
    }

    func searchStocks(_ query: String) -> [Stock] {
        let lowercasedQuery = query.lowercased()
        return getAllStocks().filter { stock in
            stock.symbol.lowercased().contains(lowercasedQuery) ||
            stock.name.lowercased().contains(lowercasedQuery)
        }
    }
}