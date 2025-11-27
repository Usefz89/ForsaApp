//
//  Step5_TaxInfoView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 5: Tax Information - Civil ID (Kuwait) or SSN (US), country of tax residence
/// Optimized for Kuwait customers
/// Security: Auto-masks ID after 2 seconds of inactivity, stores to Keychain immediately
struct Step5_TaxInfoView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showId = false
    @State private var showIdTypePicker = false
    @State private var showCountryPicker = false
    @FocusState private var idFocused: Bool
    
    /// Timer for auto-masking after inactivity
    @State private var autoMaskTimer: Timer?
    
    /// Auto-mask delay in seconds (for security)
    private let autoMaskDelay: TimeInterval = 2.0
    
    /// Whether the user is from Kuwait
    private var isKuwait: Bool {
        viewModel.registrationData.country == "KWT"
    }
    
    /// The appropriate ID type options based on country
    private var availableIdTypes: [TaxIdType] {
        isKuwait ? TaxIdType.kuwaitOptions : TaxIdType.usOptions
    }
    
    /// Expected digit count for current ID type
    private var expectedDigitCount: Int {
        switch viewModel.registrationData.taxIdType {
        case .kuwaitCivilId: return 12
        case .ssn, .itin: return 9
        case .foreignPassport, .foreignId: return 5  // minimum
        }
    }
    
    // MARK: - Security: Auto-mask Timer
    
    /// Reset the auto-mask timer when user types
    private func resetAutoMaskTimer() {
        autoMaskTimer?.invalidate()
        autoMaskTimer = Timer.scheduledTimer(withTimeInterval: autoMaskDelay, repeats: false) { _ in
            // Auto-hide after inactivity
            withAnimation(.easeOut(duration: 0.2)) {
                showId = false
            }
        }
    }
    
    /// Store ID securely and reset timer
    private func onIdChanged(_ newValue: String) {
        // Store to Keychain immediately for security
        viewModel.storeSSNSecurely(newValue)
        // Reset auto-mask timer
        resetAutoMaskTimer()
    }
    
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
                
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text(isKuwait ? "Identity Verification" : "Tax Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(isKuwait 
                    ? "Your Civil ID is required for account verification.\nYour information is encrypted and secure."
                    : "Required by law for tax reporting.\nYour information is encrypted and secure.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - ID Type Section
    
    private var taxIdTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isKuwait ? "ID Type" : "Tax ID Type")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showIdTypePicker = true }) {
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
        .sheet(isPresented: $showIdTypePicker) {
            TaxIdTypePickerSheet(
                selectedType: $viewModel.registrationData.taxIdType,
                availableTypes: availableIdTypes
            )
        }
    }
    
    // MARK: - ID Input Section
    
    private var ssnInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.registrationData.taxIdType.displayName)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: { showId.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showId ? "eye.slash.fill" : "eye.fill")
                            .font(.caption)
                        Text(showId ? "Hide" : "Show")
                            .font(.caption1)
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryPurple)
                
                if showId {
                    TextField(viewModel.registrationData.taxIdType.placeholder, text: Binding(
                        get: { formatIdNumber(viewModel.registrationData.taxId) },
                        set: { newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == "-" }
                            viewModel.registrationData.taxId = filtered
                            // Security: Store to Keychain immediately and reset auto-mask timer
                            onIdChanged(filtered)
                        }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($idFocused)
                    .onAppear {
                        // Start auto-mask timer when field becomes visible
                        resetAutoMaskTimer()
                    }
                } else {
                    Text(viewModel.registrationData.taxId.isEmpty 
                        ? viewModel.registrationData.taxIdType.placeholder 
                        : maskedId)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(viewModel.registrationData.taxId.isEmpty ? .textTertiary : .textPrimary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(idFocused ? Color.primaryPurple : Color.borderPrimary, lineWidth: idFocused ? 2 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                showId = true
                idFocused = true
            }
            
            // ID validation feedback
            if !viewModel.registrationData.taxId.isEmpty {
                let digits = viewModel.registrationData.taxId.filter { $0.isNumber }
                if digits.count >= expectedDigitCount {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption1)
                        Text("Valid format")
                            .font(.caption1)
                    }
                    .foregroundColor(.successGreen)
                } else {
                    let remaining = expectedDigitCount - digits.count
                    Text("\(remaining) more digit\(remaining == 1 ? "" : "s") needed")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
        }
    }
    
    /// Format ID number based on type
    private func formatIdNumber(_ input: String) -> String {
        switch viewModel.registrationData.taxIdType {
        case .ssn, .itin:
            return viewModel.formatTaxId(input)
        case .kuwaitCivilId:
            // Kuwait Civil ID: show as-is (12 digits)
            return input.filter { $0.isNumber }
        case .foreignPassport, .foreignId:
            return input
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
                    
                    Text(isKuwait 
                        ? "Your Civil ID is encrypted immediately and never stored in plain text. We use the same security standards as major banks."
                        : "Your SSN is encrypted immediately and never stored in plain text. We use the same security standards as major banks.")
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
            
            // Regulatory disclosure
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.textTertiary)
                
                Text(isKuwait
                    ? "Your Civil ID is required by financial regulations to verify your identity and comply with anti-money laundering laws."
                    : "We're required by the IRS to collect this information for tax reporting (Form 1099-B).")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var maskedId: String {
        let taxId = viewModel.registrationData.taxId
        let digits = taxId.filter { $0.isNumber }
        
        switch viewModel.registrationData.taxIdType {
        case .kuwaitCivilId:
            // Kuwait Civil ID: show last 4 digits
            if digits.isEmpty {
                return "••••••••••••"
            }
            return "••••••••" + String(digits.suffix(4))
            
        case .ssn, .itin:
            // US SSN/ITIN: show last 4 digits
            if digits.isEmpty {
                return "•••-••-••••"
            }
            return "•••-••-" + String(digits.suffix(4))
            
        case .foreignPassport, .foreignId:
            if digits.isEmpty {
                return "••••••••"
            }
            return "••••" + String(digits.suffix(4))
        }
    }
    
    private var taxResidenceFlag: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfTaxResidence }?.flag ?? "🇰🇼"
    }
    
    private var taxResidenceName: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfTaxResidence }?.name ?? "Kuwait"
    }
    
    private var isFormValid: Bool {
        let digits = viewModel.registrationData.taxId.filter { $0.isNumber }
        switch viewModel.registrationData.taxIdType {
        case .kuwaitCivilId:
            return digits.count == 12
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
    var availableTypes: [TaxIdType] = TaxIdType.kuwaitOptions  // Default to Kuwait options
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableTypes, id: \.self) { type in
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

