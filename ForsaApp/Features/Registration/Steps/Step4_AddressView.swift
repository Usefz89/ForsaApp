//
//  Step4_AddressView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 4: Home Address - Street address, city, state, ZIP, country
struct Step4_AddressView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showStatePicker = false
    @State private var showCountryPicker = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case street, unit, city, zip
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
                        .onSubmit { showStatePicker = true }
                }
                
                // State
                VStack(alignment: .leading, spacing: 8) {
                    Text("State")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    Button(action: { showStatePicker = true }) {
                        HStack {
                            Text(stateDisplayText)
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
                .frame(width: 100)
            }
            
            // ZIP and Country
            HStack(spacing: 12) {
                // ZIP Code
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
                            // Limit to 10 characters (ZIP+4)
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
                    
                    Button(action: { showCountryPicker = true }) {
                        HStack {
                            Text(countryFlag)
                                .font(.title3)
                            
                            Text(countryName)
                                .font(.inputText)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                        .padding(.horizontal, 12)
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
        }
        .sheet(isPresented: $showStatePicker) {
            StatePickerSheet(selectedState: $viewModel.registrationData.state)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountrySelectionSheet(
                selectedCountryCode: $viewModel.registrationData.country,
                title: "Country"
            )
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
    
    private var stateDisplayText: String {
        if viewModel.registrationData.state.isEmpty {
            return "Select"
        }
        return viewModel.registrationData.state
    }
    
    private var countryFlag: String {
        Country.common.first { $0.code == viewModel.registrationData.country }?.flag ?? "🇺🇸"
    }
    
    private var countryName: String {
        Country.common.first { $0.code == viewModel.registrationData.country }?.name ?? "USA"
    }
    
    private var isFormValid: Bool {
        !viewModel.registrationData.streetAddress.isEmpty &&
        !viewModel.registrationData.city.isEmpty &&
        !viewModel.registrationData.state.isEmpty &&
        !viewModel.registrationData.postalCode.isEmpty &&
        isValidZip
    }
    
    private var isValidZip: Bool {
        let zip = viewModel.registrationData.postalCode
        let zipRegex = "^[0-9]{5}(-[0-9]{4})?$"
        let zipPredicate = NSPredicate(format: "SELF MATCHES %@", zipRegex)
        return zipPredicate.evaluate(with: zip)
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

