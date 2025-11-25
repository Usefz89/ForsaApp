//
//  WithdrawFlowView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/25/25.
//

import SwiftUI

struct WithdrawFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    private var isValidAmount: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        return true
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Amount Input
                    VStack(spacing: 12) {
                        Text("Enter Amount to Withdraw")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            Text("$")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primaryPurple)
                            
                            TextField("0.00", text: $amount)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primaryPurple)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.backgroundCard)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Withdraw Button
                    ForsaButton(
                        "Withdraw Funds",
                        style: .primary,
                        size: .large,
                        isDisabled: !isValidAmount,
                        isLoading: isProcessing
                    ) {
                        Task { await processWithdrawal() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Withdraw Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your withdrawal of $\(amount) has been initiated.")
            }
        }
    }
    
    private func processWithdrawal() async {
        guard let amountValue = Double(amount) else { return }
        
        isProcessing = true
        
        do {
            guard let accountId = UserDefaults.standard.string(forKey: "alpaca_account_id") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No account found"])
            }
            
            try await AlpacaTradingService.shared.withdrawFunds(accountId: accountId, amount: amountValue)
            showSuccess = true
        } catch {
            errorMessage = "Withdrawal failed: \(error.localizedDescription)"
            showError = true
        }
        
        isProcessing = false
    }
}

