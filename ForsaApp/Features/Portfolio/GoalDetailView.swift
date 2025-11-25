import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    @State private var showAddFundsSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    Text(goal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 4) {
                        Text("Current Value")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("$0.00") // Placeholder for real value
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                    }
                    
                    HStack {
                        Label("\(goal.durationYears) Years", systemImage: "hourglass")
                        Spacer()
                        Label(goal.assignedPortfolio.title, systemImage: "chart.pie")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                
                // Portfolio Composition
                VStack(alignment: .leading, spacing: 16) {
                    Text("Portfolio Composition")
                        .font(.headline)
                    
                    ForEach(goal.assignedPortfolio.allocations) { allocation in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(allocation.ticker)
                                    .font(.headline)
                                Text(allocation.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0f%%", allocation.percentage * 100))
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showAddFundsSheet = true
                }) {
                    Text("Add Funds")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddFundsSheet) {
            AddFundsView(portfolio: goal.assignedPortfolio)
        }
    }
}

struct AddFundsView: View {
    let portfolio: RiskLevel
    @Environment(\.presentationMode) var presentationMode
    @State private var amountString = ""
    @State private var isProcessing = false
    @StateObject private var tradingService = AlpacaTradingService.shared
    
    var amount: Double {
        Double(amountString) ?? 0
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("How much to invest?")
                        .font(.headline)
                    
                    TextField("$0", text: $amountString)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .bold))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                if amount > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Investment Breakdown")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(portfolio.allocations) { allocation in
                            HStack {
                                Text(allocation.ticker)
                                Spacer()
                                Text("$\(String(format: "%.2f", amount * allocation.percentage))")
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        isProcessing = true
                        if let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") {
                            try? await tradingService.placeBasketOrder(accountId: accountId, amount: amount, portfolio: portfolio)
                        }
                        isProcessing = false
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Confirm Investment")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(amount > 0 ? Color.green : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(amount <= 0 || isProcessing)
            }
            .padding()
            .navigationTitle("Add Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
