//
//  Step5_TaxInfoView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 5: Tax Information - SSN (masked), country of tax residence
struct Step5_TaxInfoView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showSSN = false
    @State private var showTaxIdTypePicker = false
    @State private var showCountryPicker = false
    @FocusState private var ssnFocused: Bool
    
    var body: some View {
        RegistrationStepContainer(
            buttonTitle: "Continue",
            isButtonDisabled: !isFormValid,
            onPrimaryTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.nextStep()
                }
            }
        ) {
            VStack(spacing: 28) {
                // Header
                taxHeader
                
                // Tax ID Type
                taxIdTypeSection
                
                // SSN Input
                ssnInputSection
                
                // Tax Residence
                taxResidenceSection
                
                // Security notice
                securityNotice
            }
        }
    }
    
    // MARK: - Header
    
    private var taxHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Tax Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Required by law for tax reporting.\nYour information is encrypted and secure.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Tax ID Type Section
    
    private var taxIdTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tax ID Type")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showTaxIdTypePicker = true }) {
                HStack {
                    Text(viewModel.registrationData.taxIdType.displayName)
                        .font(.inputText)
                        .foregroundColor(.textPrimary)
                    
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
        .sheet(isPresented: $showTaxIdTypePicker) {
            TaxIdTypePickerSheet(selectedType: $viewModel.registrationData.taxIdType)
        }
    }
    
    // MARK: - SSN Input Section
    
    private var ssnInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.registrationData.taxIdType.displayName)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: { showSSN.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showSSN ? "eye.slash.fill" : "eye.fill")
                            .font(.caption)
                        Text(showSSN ? "Hide" : "Show")
                            .font(.caption1)
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryPurple)
                
                if showSSN {
                    TextField(viewModel.registrationData.taxIdType.placeholder, text: Binding(
                        get: { viewModel.formatTaxId(viewModel.registrationData.taxId) },
                        set: { viewModel.registrationData.taxId = $0.filter { $0.isNumber || $0 == "-" } }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .keyboardType(.numberPad)
                    .focused($ssnFocused)
                } else {
                    Text(maskedSSN)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        showSSN = true
                        ssnFocused = true
                    }) {
                        Text("Edit")
                            .font(.caption1Medium)
                            .foregroundColor(.primaryPurple)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ssnFocused ? Color.primaryPurple : Color.borderPrimary, lineWidth: ssnFocused ? 2 : 1)
            )
            
            // SSN validation feedback
            if !viewModel.registrationData.taxId.isEmpty {
                let digits = viewModel.registrationData.taxId.filter { $0.isNumber }
                if digits.count == 9 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption1)
                        Text("Valid format")
                            .font(.caption1)
                    }
                    .foregroundColor(.successGreen)
                } else {
                    Text("\(9 - digits.count) more digits needed")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
        }
    }
    
    // MARK: - Tax Residence Section
    
    private var taxResidenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Country of Tax Residence")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showCountryPicker = true }) {
                HStack {
                    Text(taxResidenceFlag)
                        .font(.title3)
                    
                    Text(taxResidenceName)
                        .font(.inputText)
                        .foregroundColor(.textPrimary)
                    
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
            
            Text("Where you file your taxes annually")
                .font(.caption1)
                .foregroundColor(.textTertiary)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountrySelectionSheet(
                selectedCountryCode: $viewModel.registrationData.countryOfTaxResidence,
                title: "Tax Residence"
            )
        }
    }
    
    // MARK: - Security Notice
    
    private var securityNotice: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 24))
                    .foregroundColor(.successGreen)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("256-bit Encryption")
                        .font(.calloutMedium)
                        .foregroundColor(.textPrimary)
                    
                    Text("Your SSN is encrypted immediately and never stored in plain text. We use the same security standards as major banks.")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(16)
            .background(Color.successGreen.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.successGreen.opacity(0.2), lineWidth: 1)
            )
            
            // IRS disclosure
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.textTertiary)
                
                Text("We're required by the IRS to collect this information for tax reporting (Form 1099-B).")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var maskedSSN: String {
        let taxId = viewModel.registrationData.taxId
        let digits = taxId.filter { $0.isNumber }
        
        if digits.isEmpty {
            return "•••-••-••••"
        }
        
        let masked = "•••-••-" + String(digits.suffix(4))
        return masked
    }
    
    private var taxResidenceFlag: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfTaxResidence }?.flag ?? "🇺🇸"
    }
    
    private var taxResidenceName: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfTaxResidence }?.name ?? "United States"
    }
    
    private var isFormValid: Bool {
        let digits = viewModel.registrationData.taxId.filter { $0.isNumber }
        switch viewModel.registrationData.taxIdType {
        case .ssn, .itin:
            return digits.count == 9
        case .foreignPassport, .foreignId:
            return digits.count >= 5
        }
    }
}

// MARK: - Tax ID Type Picker Sheet

struct TaxIdTypePickerSheet: View {
    @Binding var selectedType: TaxIdType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(TaxIdType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                
                                Text("Format: \(type.placeholder)")
                                    .font(.caption1)
                                    .foregroundColor(.textTertiary)
                            }
                            
                            Spacer()
                            
                            if type == selectedType {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select ID Type")
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

// MARK: - Preview

#Preview {
    Step5_TaxInfoView(viewModel: RegistrationViewModel())
}

