//
//  Step6_FinancialProfileView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 6: Financial Profile - Tax ID, Employment, income, net worth, funding sources
/// Collects financial information for KYC compliance and investment suitability
struct Step6_FinancialProfileView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showEmploymentPicker = false
    @State private var showIncomePicker = false
    @State private var showNetWorthPicker = false
    @State private var showIdTypePicker = false
    @State private var showCountryPicker = false
    @State private var showId = false
    @FocusState private var focusedField: Field?
    
    /// Timer for auto-masking Civil ID after inactivity
    @State private var autoMaskTimer: Timer?
    private let autoMaskDelay: TimeInterval = 2.0
    
    // MARK: - Animation & Feedback
    private let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    enum Field: Hashable {
        case employer, jobTitle, civilId
    }
    
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
        case .foreignPassport, .foreignId: return 5
        }
    }
    
    var body: some View {
        RegistrationStepContainer(
            buttonTitle: "Continue",
            isButtonDisabled: !isFormValid,
            onPrimaryTap: {
                impactFeedback.impactOccurred()
                withAnimation(springAnimation) {
                    viewModel.nextStep()
                }
            }
        ) {
            VStack(spacing: 28) {
                // Header
                financialHeader
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Financial Profile. Help us understand your financial situation to provide better investment recommendations.")
                
                // Tax ID Section (Civil ID for Kuwait)
                taxIdSection
                
                // Employment Section
                employmentSection
                
                // Income Section
                incomeSection
                
                // Funding Sources
                fundingSourcesSection
            }
        }
    }
    
    // MARK: - Header
    
    private var financialHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Financial Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Help us understand your financial situation\nto provide better investment recommendations")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Tax ID Section
    
    private var taxIdSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            RegistrationSectionHeader(
                isKuwait ? "Identity Verification" : "Tax Information",
                subtitle: isKuwait ? "Your Civil ID is required for verification" : "Required for tax reporting",
                icon: "person.text.rectangle.fill"
            )
            
            // ID Type Picker
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
            
            // ID Input
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
                                .font(.caption)
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
                                viewModel.storeSSNSecurely(filtered)
                                resetAutoMaskTimer()
                            }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .civilId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onAppear { resetAutoMaskTimer() }
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
                        .stroke(focusedField == .civilId ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .civilId ? 2 : 1)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    showId = true
                    focusedField = .civilId
                }
                
                // Validation feedback
                if !viewModel.registrationData.taxId.isEmpty {
                    let digits = viewModel.registrationData.taxId.filter { $0.isNumber }
                    if digits.count >= expectedDigitCount {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Valid format")
                                .font(.caption)
                        }
                        .foregroundColor(.successGreen)
                    } else {
                        let remaining = expectedDigitCount - digits.count
                        Text("\(remaining) more digit\(remaining == 1 ? "" : "s") needed")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            
            // Tax Residence (for non-Kuwait users or if needed)
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
            }
            
            // Security notice
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 20))
                    .foregroundColor(.successGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("256-bit Encryption")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(isKuwait
                        ? "Your Civil ID is encrypted and never stored in plain text."
                        : "Your SSN is encrypted and never stored in plain text.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(12)
            .background(Color.successGreen.opacity(0.08))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showIdTypePicker) {
            TaxIdTypePickerSheet(
                selectedType: $viewModel.registrationData.taxIdType,
                availableTypes: availableIdTypes
            )
        }
        .sheet(isPresented: $showCountryPicker) {
            CountrySelectionSheet(
                selectedCountryCode: $viewModel.registrationData.countryOfTaxResidence,
                title: "Tax Residence"
            )
        }
    }
    
    // MARK: - Tax ID Helpers
    
    private func resetAutoMaskTimer() {
        autoMaskTimer?.invalidate()
        autoMaskTimer = Timer.scheduledTimer(withTimeInterval: autoMaskDelay, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                showId = false
            }
        }
    }
    
    private func formatIdNumber(_ input: String) -> String {
        switch viewModel.registrationData.taxIdType {
        case .ssn, .itin:
            return viewModel.formatTaxId(input)
        case .kuwaitCivilId:
            return input.filter { $0.isNumber }
        case .foreignPassport, .foreignId:
            return input
        }
    }
    
    private var maskedId: String {
        let taxId = viewModel.registrationData.taxId
        let digits = taxId.filter { $0.isNumber }
        
        switch viewModel.registrationData.taxIdType {
        case .kuwaitCivilId:
            if digits.isEmpty { return "••••••••••••" }
            return "••••••••" + String(digits.suffix(4))
        case .ssn, .itin:
            if digits.isEmpty { return "•••-••-••••" }
            return "•••-••-" + String(digits.suffix(4))
        case .foreignPassport, .foreignId:
            if digits.isEmpty { return "••••••••" }
            return "••••" + String(digits.suffix(4))
        }
    }
    
    private var taxResidenceFlag: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfTaxResidence }?.flag ?? "🇰🇼"
    }
    
    private var taxResidenceName: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfTaxResidence }?.name ?? "Kuwait"
    }
    
    // MARK: - Employment Section
    
    private var employmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            RegistrationSectionHeader("Employment", icon: "briefcase.fill")
            
            // Employment Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Employment Status")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                Button(action: { showEmploymentPicker = true }) {
                    HStack {
                        Text(viewModel.registrationData.employmentStatus.displayName)
                            .font(.inputText)
                            .foregroundColor(viewModel.registrationData.employmentStatus == .none ? .textTertiary : .textPrimary)
                        
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
            
            // Employer Name (if employed)
            if viewModel.registrationData.employmentStatus.requiresEmployerInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Employer Name")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Company name", text: Binding(
                        get: { viewModel.registrationData.employer ?? "" },
                        set: { viewModel.registrationData.employer = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .employer))
                    .focused($focusedField, equals: .employer)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .jobTitle }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                
                // Job Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Job Title")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Your position", text: Binding(
                        get: { viewModel.registrationData.occupation ?? "" },
                        set: { viewModel.registrationData.occupation = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .jobTitle))
                    .focused($focusedField, equals: .jobTitle)
                    .submitLabel(.done)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.registrationData.employmentStatus)
        .sheet(isPresented: $showEmploymentPicker) {
            EmploymentPickerSheet(selectedStatus: $viewModel.registrationData.employmentStatus)
        }
    }
    
    // MARK: - Income Section
    
    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            RegistrationSectionHeader("Financial Details", icon: "chart.bar.fill")
            
            // Annual Income
            VStack(alignment: .leading, spacing: 8) {
                Text("Annual Income")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                Button(action: { showIncomePicker = true }) {
                    HStack {
                        Text(viewModel.registrationData.annualIncome?.displayName ?? "Select income range")
                            .font(.inputText)
                            .foregroundColor(viewModel.registrationData.annualIncome == nil ? .textTertiary : .textPrimary)
                        
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
            
            // Net Worth
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Net Worth")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                Button(action: { showNetWorthPicker = true }) {
                    HStack {
                        Text(viewModel.registrationData.netWorth?.displayName ?? "Select net worth range")
                            .font(.inputText)
                            .foregroundColor(viewModel.registrationData.netWorth == nil ? .textTertiary : .textPrimary)
                        
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
                
                Text("Include all assets minus debts")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
        }
        .sheet(isPresented: $showIncomePicker) {
            IncomePickerSheet(selectedIncome: $viewModel.registrationData.annualIncome)
        }
        .sheet(isPresented: $showNetWorthPicker) {
            NetWorthPickerSheet(selectedNetWorth: $viewModel.registrationData.netWorth)
        }
    }
    
    // MARK: - Funding Sources Section
    
    private var fundingSourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Funding Sources")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Where will your investment funds come from? (Select all that apply)")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
            }
            
            // Funding source grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(FundingSource.allCases) { source in
                    FundingSourceCard(
                        source: source,
                        isSelected: viewModel.isFundingSourceSelected(source),
                        action: { viewModel.toggleFundingSource(source) }
                    )
                }
            }
            
            if viewModel.registrationData.fundingSources.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption1)
                    Text("Please select at least one funding source")
                        .font(.caption1)
                }
                .foregroundColor(.warningYellow)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        // Tax ID validation
        let digits = viewModel.registrationData.taxId.filter { $0.isNumber }
        let hasTaxId: Bool
        switch viewModel.registrationData.taxIdType {
        case .kuwaitCivilId:
            hasTaxId = digits.count == 12
        case .ssn, .itin:
            hasTaxId = digits.count == 9
        case .foreignPassport, .foreignId:
            hasTaxId = digits.count >= 5
        }
        
        let hasEmploymentStatus = viewModel.registrationData.employmentStatus != .none
        let hasEmployerInfoIfNeeded = !viewModel.registrationData.employmentStatus.requiresEmployerInfo ||
            (!(viewModel.registrationData.employer?.isEmpty ?? true) && !(viewModel.registrationData.occupation?.isEmpty ?? true))
        let hasFundingSources = !viewModel.registrationData.fundingSources.isEmpty
        
        return hasTaxId && hasEmploymentStatus && hasEmployerInfoIfNeeded && hasFundingSources
    }
}

// MARK: - Employment Picker Sheet

struct EmploymentPickerSheet: View {
    @Binding var selectedStatus: EmploymentStatus
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(EmploymentStatus.allCases.filter { $0 != .none }, id: \.self) { status in
                    Button(action: {
                        selectedStatus = status
                        dismiss()
                    }) {
                        HStack {
                            Text(status.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if status == selectedStatus {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle("Employment Status")
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

// MARK: - Income Picker Sheet

struct IncomePickerSheet: View {
    @Binding var selectedIncome: IncomeRange?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(IncomeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedIncome = range
                        dismiss()
                    }) {
                        HStack {
                            Text(range.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if range == selectedIncome {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .scrollContentBackground(.visible)
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

// MARK: - Net Worth Picker Sheet

struct NetWorthPickerSheet: View {
    @Binding var selectedNetWorth: NetWorthRange?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(NetWorthRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedNetWorth = range
                        dismiss()
                    }) {
                        HStack {
                            Text(range.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if range == selectedNetWorth {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle("Net Worth")
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

// MARK: - Previews

#Preview("Financial Profile - Empty") {
    Step6_FinancialProfileView(viewModel: RegistrationViewModel())
}

#Preview("Financial Profile - Filled") {
    Step6_FinancialProfileView(viewModel: {
        let vm = RegistrationViewModel()
        vm.registrationData.taxId = "123456789012"
        vm.registrationData.employmentStatus = .employed
        vm.registrationData.employer = "Tech Company"
        vm.registrationData.occupation = "Software Engineer"
        vm.registrationData.annualIncome = .from50kTo100k
        vm.registrationData.fundingSources = [.employmentIncome, .savings]
        return vm
    }())
}

#Preview("Employment Picker") {
    EmploymentPickerSheet(selectedStatus: .constant(.employed))
}

#Preview("Income Picker") {
    IncomePickerSheet(selectedIncome: .constant(.from50kTo100k))
}

