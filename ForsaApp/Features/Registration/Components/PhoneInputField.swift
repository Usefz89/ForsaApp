//
//  PhoneInputField.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Phone number input field with country code picker and formatting
struct PhoneInputField: View {
    @Binding var phoneNumber: String
    @Binding var countryCode: String
    var label: String = "Phone Number"
    var placeholder: String = "(555) 123-4567"
    var showValidation: Bool = true
    var onCountryCodeTap: (() -> Void)?
    
    @State private var isFocused = false
    @FocusState private var textFieldFocused: Bool
    
    // Common country codes
    private let countryCodes: [(code: String, dial: String, flag: String)] = [
        ("US", "+1", "🇺🇸"),
        ("CA", "+1", "🇨🇦"),
        ("GB", "+44", "🇬🇧"),
        ("DE", "+49", "🇩🇪"),
        ("FR", "+33", "🇫🇷"),
        ("AE", "+971", "🇦🇪"),
        ("SA", "+966", "🇸🇦"),
        ("KW", "+965", "🇰🇼"),
        ("IN", "+91", "🇮🇳"),
        ("PK", "+92", "🇵🇰")
    ]
    
    private var selectedCountry: (code: String, dial: String, flag: String) {
        countryCodes.first { $0.dial == countryCode } ?? countryCodes[0]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                // Country code picker button
                countryCodeButton
                
                // Phone number input
                phoneNumberInput
            }
            
            // Validation message
            if showValidation {
                validationMessage
            }
        }
    }
    
    // MARK: - Country Code Button
    
    private var countryCodeButton: some View {
        Button(action: { onCountryCodeTap?() }) {
            HStack(spacing: 6) {
                Text(selectedCountry.flag)
                    .font(.title3)
                
                Text(selectedCountry.dial)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Phone Number Input
    
    private var phoneNumberInput: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: Binding(
                get: { formatPhoneNumber(phoneNumber) },
                set: { handleInput($0) }
            ))
            .font(.inputText)
            .foregroundColor(.textPrimary)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .focused($textFieldFocused)
            .onChange(of: textFieldFocused) { _, focused in
                isFocused = focused
            }
            
            // Validation indicator
            if showValidation && !phoneNumber.isEmpty {
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.successGreen)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
        )
    }
    
    // MARK: - Validation Message
    
    @ViewBuilder
    private var validationMessage: some View {
        if phoneNumber.isEmpty {
            Text("We'll send a verification code via SMS")
                .font(.caption1)
                .foregroundColor(.textTertiary)
        } else if isValid {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption1)
                Text("Valid phone number")
                    .font(.caption1)
            }
            .foregroundColor(.successGreen)
        } else {
            Text("Please enter a valid phone number")
                .font(.caption1)
                .foregroundColor(.warningYellow)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }
    
    private var borderColor: Color {
        if isFocused {
            return .primaryPurple
        }
        if !phoneNumber.isEmpty && isValid {
            return .successGreen
        }
        return .borderPrimary
    }
    
    // MARK: - Formatting
    
    private func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var result = ""
        
        // US format: (XXX) XXX-XXXX
        for (index, digit) in digits.prefix(10).enumerated() {
            if index == 0 {
                result += "("
            }
            if index == 3 {
                result += ") "
            }
            if index == 6 {
                result += "-"
            }
            result += String(digit)
        }
        
        // Add remaining digits without formatting
        if digits.count > 10 {
            result += " " + String(digits.dropFirst(10))
        }
        
        return result
    }
    
    private func handleInput(_ input: String) {
        // Extract only digits
        let digits = input.filter { $0.isNumber }
        phoneNumber = digits
    }
}

// MARK: - Country Code Picker Sheet

struct CountryCodePickerSheet: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private let countries: [(code: String, dial: String, flag: String, name: String)] = [
        ("US", "+1", "🇺🇸", "United States"),
        ("CA", "+1", "🇨🇦", "Canada"),
        ("GB", "+44", "🇬🇧", "United Kingdom"),
        ("DE", "+49", "🇩🇪", "Germany"),
        ("FR", "+33", "🇫🇷", "France"),
        ("ES", "+34", "🇪🇸", "Spain"),
        ("IT", "+39", "🇮🇹", "Italy"),
        ("AU", "+61", "🇦🇺", "Australia"),
        ("JP", "+81", "🇯🇵", "Japan"),
        ("CN", "+86", "🇨🇳", "China"),
        ("IN", "+91", "🇮🇳", "India"),
        ("PK", "+92", "🇵🇰", "Pakistan"),
        ("BD", "+880", "🇧🇩", "Bangladesh"),
        ("AE", "+971", "🇦🇪", "United Arab Emirates"),
        ("SA", "+966", "🇸🇦", "Saudi Arabia"),
        ("KW", "+965", "🇰🇼", "Kuwait"),
        ("QA", "+974", "🇶🇦", "Qatar"),
        ("EG", "+20", "🇪🇬", "Egypt"),
        ("TR", "+90", "🇹🇷", "Turkey"),
        ("ID", "+62", "🇮🇩", "Indonesia"),
        ("MY", "+60", "🇲🇾", "Malaysia"),
        ("SG", "+65", "🇸🇬", "Singapore"),
        ("BR", "+55", "🇧🇷", "Brazil"),
        ("MX", "+52", "🇲🇽", "Mexico")
    ]
    
    private var filteredCountries: [(code: String, dial: String, flag: String, name: String)] {
        if searchText.isEmpty {
            return countries
        }
        return countries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.dial.contains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCountries, id: \.code) { country in
                    Button(action: {
                        selectedCode = country.dial
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Text(country.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(country.name)
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                
                                Text(country.dial)
                                    .font(.caption1)
                                    .foregroundColor(.textTertiary)
                            }
                            
                            Spacer()
                            
                            if country.dial == selectedCode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
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

// MARK: - Compact Phone Input

/// More compact phone input variant
struct CompactPhoneInput: View {
    @Binding var fullPhoneNumber: String // Includes country code
    @State private var countryCode = "+1"
    @State private var phoneNumber = ""
    @State private var showCountryPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 0) {
                // Country code
                Button(action: { showCountryPicker = true }) {
                    HStack(spacing: 4) {
                        Text(flagForCode(countryCode))
                            .font(.body)
                        Text(countryCode)
                            .font(.bodyMedium)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color.backgroundSecondary)
                }
                
                // Divider
                Rectangle()
                    .fill(Color.borderPrimary)
                    .frame(width: 1, height: 24)
                
                // Phone number
                TextField("Phone number", text: $phoneNumber)
                    .font(.inputText)
                    .keyboardType(.phonePad)
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color.backgroundCard)
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
        }
        .onChange(of: phoneNumber) { _, _ in
            fullPhoneNumber = countryCode + phoneNumber.filter { $0.isNumber }
        }
        .onChange(of: countryCode) { _, _ in
            fullPhoneNumber = countryCode + phoneNumber.filter { $0.isNumber }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePickerSheet(selectedCode: $countryCode)
        }
    }
    
    private func flagForCode(_ code: String) -> String {
        let flags: [String: String] = [
            "+1": "🇺🇸", "+44": "🇬🇧", "+49": "🇩🇪", "+33": "🇫🇷",
            "+971": "🇦🇪", "+966": "🇸🇦", "+965": "🇰🇼", "+91": "🇮🇳"
        ]
        return flags[code] ?? "🌍"
    }
}

// MARK: - Previews

#Preview("Phone Input Field") {
    VStack(spacing: 24) {
        PhoneInputField(
            phoneNumber: .constant(""),
            countryCode: .constant("+1")
        )
        
        PhoneInputField(
            phoneNumber: .constant("5551234567"),
            countryCode: .constant("+1")
        )
    }
    .padding()
}

#Preview("Compact Phone Input") {
    CompactPhoneInput(fullPhoneNumber: .constant(""))
        .padding()
}


