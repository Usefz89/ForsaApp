//
//  Step6_FinancialProfileView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 6: Financial Profile - Employment, income, net worth, funding sources
struct Step6_FinancialProfileView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showEmploymentPicker = false
    @State private var showIncomePicker = false
    @State private var showNetWorthPicker = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case employer, jobTitle
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
                financialHeader
                
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
        let hasEmploymentStatus = viewModel.registrationData.employmentStatus != .none
        let hasEmployerInfoIfNeeded = !viewModel.registrationData.employmentStatus.requiresEmployerInfo ||
            (!(viewModel.registrationData.employer?.isEmpty ?? true) && !(viewModel.registrationData.occupation?.isEmpty ?? true))
        let hasFundingSources = !viewModel.registrationData.fundingSources.isEmpty
        
        return hasEmploymentStatus && hasEmployerInfoIfNeeded && hasFundingSources
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
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if status == selectedStatus {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
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
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if range == selectedIncome {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
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
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if range == selectedNetWorth {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
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
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    Step6_FinancialProfileView(viewModel: RegistrationViewModel())
}

