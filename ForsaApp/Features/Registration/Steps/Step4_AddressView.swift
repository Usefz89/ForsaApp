//
//  Step4_AddressView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 4: Home Address - Street address, city, governorate/state, postal code, country
/// Optimized for Kuwait customers
struct Step4_AddressView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showGovernoratePicker = false
    @State private var showCountryPicker = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case street, unit, city, zip
        // Kuwait-specific fields
        case block, building, floor, area
    }
    
    /// Whether the selected country is Kuwait
    private var isKuwait: Bool {
        viewModel.registrationData.country == "KWT"
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
                addressHeader
                
                // Address form
                addressForm
                
                // Auto-fill suggestion (mock)
                autoFillSuggestion
            }
        }
    }
    
    // MARK: - Header
    
    private var addressHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Home Address")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Enter your current residential address.\nThis is required for regulatory compliance.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Address Form
    
    private var addressForm: some View {
        VStack(spacing: 16) {
            if isKuwait {
                // Kuwait-specific address format
                kuwaitAddressForm
            } else {
                // Standard international address format
                internationalAddressForm
            }
        }
        .sheet(isPresented: $showGovernoratePicker) {
            if isKuwait {
                GovernoratePickerSheet(selectedGovernorate: $viewModel.registrationData.governorate)
            } else {
                StatePickerSheet(selectedState: $viewModel.registrationData.state)
            }
        }
    }
    
    // MARK: - Kuwait Address Form
    
    private var kuwaitAddressForm: some View {
        VStack(spacing: 16) {
            // Area and Governorate Row
            HStack(spacing: 12) {
                // Area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Area")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("e.g., Salmiya", text: $viewModel.registrationData.area)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .area))
                        .focused($focusedField, equals: .area)
                        .submitLabel(.next)
                        .onSubmit { showGovernoratePicker = true }
                }
                
                // Governorate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Governorate")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    Button(action: { showGovernoratePicker = true }) {
                        HStack {
                            Text(viewModel.registrationData.governorate.isEmpty ? "Select" : viewModel.registrationData.governorate)
                                .font(.inputText)
                                .foregroundColor(viewModel.registrationData.governorate.isEmpty ? .textTertiary : .textPrimary)
                            
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
            }
            
            // Block and Street Row
            HStack(spacing: 12) {
                // Block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Block")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("e.g., 5", text: $viewModel.registrationData.block)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .block))
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .block)
                }
                .frame(width: 100)
                
                // Street
                VStack(alignment: .leading, spacing: 8) {
                    Text("Street")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Street name or number", text: $viewModel.registrationData.streetAddress)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .street))
                        .focused($focusedField, equals: .street)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .building }
                }
            }
            
            // Building and Floor/Apt Row
            HStack(spacing: 12) {
                // Building
                VStack(alignment: .leading, spacing: 8) {
                    Text("Building")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("e.g., 12", text: $viewModel.registrationData.building)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .building))
                        .focused($focusedField, equals: .building)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .floor }
                }
                
                // Floor - Optional
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Floor")
                            .font(.inputLabel)
                            .foregroundColor(.textPrimary)
                        Text("(Optional)")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)
                    }
                    
                    TextField("e.g., 3", text: Binding(
                        get: { viewModel.registrationData.floor ?? "" },
                        set: { viewModel.registrationData.floor = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .floor))
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .floor)
                }
                .frame(width: 100)
                
                // Apartment - Optional
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Apt")
                            .font(.inputLabel)
                            .foregroundColor(.textPrimary)
                        Text("(Opt)")
                            .font(.caption1)
                            .foregroundColor(.textTertiary)
                    }
                    
                    TextField("e.g., 5A", text: Binding(
                        get: { viewModel.registrationData.apartmentUnit ?? "" },
                        set: { viewModel.registrationData.apartmentUnit = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .unit))
                    .focused($focusedField, equals: .unit)
                }
                .frame(width: 80)
            }
            
            // Country (fixed to Kuwait)
            VStack(alignment: .leading, spacing: 8) {
                Text("Country")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    Text("🇰🇼")
                        .font(.title3)
                    
                    Text("Kuwait")
                        .font(.inputText)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.successGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.successGreen.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.successGreen.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - International Address Form
    
    private var internationalAddressForm: some View {
        VStack(spacing: 16) {
            // Street Address
            VStack(alignment: .leading, spacing: 8) {
                Text("Street Address")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                TextField("123 Main Street", text: $viewModel.registrationData.streetAddress)
                    .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .street))
                    .textContentType(.streetAddressLine1)
                    .focused($focusedField, equals: .street)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .unit }
            }
            
            // Apartment/Unit
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Apt/Unit")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    Text("(Optional)")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
                
                TextField("Apt 4B", text: Binding(
                    get: { viewModel.registrationData.apartmentUnit ?? "" },
                    set: { viewModel.registrationData.apartmentUnit = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .unit))
                .textContentType(.streetAddressLine2)
                .focused($focusedField, equals: .unit)
                .submitLabel(.next)
                .onSubmit { focusedField = .city }
            }
            
            // City and State
            HStack(spacing: 12) {
                // City
                VStack(alignment: .leading, spacing: 8) {
                    Text("City")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("City", text: $viewModel.registrationData.city)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .city))
                        .textContentType(.addressCity)
                        .focused($focusedField, equals: .city)
                        .submitLabel(.next)
                        .onSubmit { showGovernoratePicker = true }
                }
                
                // State
                VStack(alignment: .leading, spacing: 8) {
                    Text("State")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    Button(action: { showGovernoratePicker = true }) {
                        HStack {
                            Text(viewModel.registrationData.state.isEmpty ? "Select" : viewModel.registrationData.state)
                                .font(.inputText)
                                .foregroundColor(viewModel.registrationData.state.isEmpty ? .textTertiary : .textPrimary)
                            
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
                .frame(width: 120)
            }
            
            // Postal Code and Country
            HStack(spacing: 12) {
                // Postal Code
                VStack(alignment: .leading, spacing: 8) {
                    Text("ZIP Code")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    TextField("12345", text: $viewModel.registrationData.postalCode)
                        .textFieldStyle(ForsaTextFieldStyle(isFocused: focusedField == .zip))
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                        .focused($focusedField, equals: .zip)
                        .onChange(of: viewModel.registrationData.postalCode) { _, newValue in
                            if newValue.count > 10 {
                                viewModel.registrationData.postalCode = String(newValue.prefix(10))
                            }
                        }
                }
                .frame(width: 120)
                
                // Country
                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        Text(countryFlag)
                            .font(.title3)
                        
                        Text(countryName)
                            .font(.inputText)
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(Color.backgroundCard.opacity(0.6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderPrimary.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Auto-fill Suggestion
    
    private var autoFillSuggestion: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(.primaryPurple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Use your saved address?")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                Text("Tap to auto-fill from your device")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .opacity(0.6) // Dimmed to indicate it's a suggestion
    }
    
    // MARK: - Computed Properties
    
    private var countryFlag: String {
        Country.common.first { $0.code == viewModel.registrationData.country }?.flag ?? "🇰🇼"
    }
    
    private var countryName: String {
        Country.common.first { $0.code == viewModel.registrationData.country }?.name ?? "Kuwait"
    }
    
    private var isFormValid: Bool {
        if isKuwait {
            // Kuwait address validation
            return !viewModel.registrationData.block.isEmpty &&
                   !viewModel.registrationData.streetAddress.isEmpty &&
                   !viewModel.registrationData.building.isEmpty &&
                   !viewModel.registrationData.area.isEmpty &&
                   !viewModel.registrationData.governorate.isEmpty
        } else {
            // International address validation
            return !viewModel.registrationData.streetAddress.isEmpty &&
                   !viewModel.registrationData.city.isEmpty &&
                   !viewModel.registrationData.state.isEmpty &&
                   !viewModel.registrationData.postalCode.isEmpty &&
                   isValidPostalCode
        }
    }
    
    private var isValidPostalCode: Bool {
        let postalCode = viewModel.registrationData.postalCode
        
        if isKuwait {
            // Kuwait doesn't typically use postal codes, but validate if provided
            return postalCode.isEmpty || postalCode.count == 5
        } else {
            // US ZIP codes: 5 digits or 5+4
            let usRegex = "^[0-9]{5}(-[0-9]{4})?$"
            let usPredicate = NSPredicate(format: "SELF MATCHES %@", usRegex)
            return usPredicate.evaluate(with: postalCode)
        }
    }
}

// MARK: - Governorate Picker Sheet (Kuwait)

struct GovernoratePickerSheet: View {
    @Binding var selectedGovernorate: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(KuwaitGovernorate.allCases) { governorate in
                    Button(action: {
                        selectedGovernorate = governorate.displayName
                        dismiss()
                    }) {
                        HStack {
                            Text(governorate.displayName)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if governorate.displayName == selectedGovernorate {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Governorate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
        }
    }
}

// MARK: - State Picker Sheet

struct StatePickerSheet: View {
    @Binding var selectedState: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredStates: [USState] {
        if searchText.isEmpty {
            return USState.allCases
        }
        return USState.allCases.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredStates) { state in
                    Button(action: {
                        selectedState = state.rawValue
                        dismiss()
                    }) {
                        HStack {
                            Text(state.fullName)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text(state.rawValue)
                                .font(.callout)
                                .foregroundColor(.textTertiary)
                            
                            if state.rawValue == selectedState {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search states")
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Step4_AddressView(viewModel: RegistrationViewModel())
}

