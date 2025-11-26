//
//  Step3_PersonalInfoView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 3: Personal Information - Date of Birth, citizenship, country of birth
struct Step3_PersonalInfoView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showDatePicker = false
    @State private var showCitizenshipPicker = false
    @State private var showBirthCountryPicker = false
    
    private let minimumDate: Date = {
        Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }()
    
    private let maximumDate: Date = {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }()
    
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
                personalInfoHeader
                
                // Date of Birth
                dateOfBirthSection
                
                // Citizenship
                citizenshipSection
                
                // Country of Birth
                birthCountrySection
                
                // Info card
                infoCard
            }
        }
    }
    
    // MARK: - Header
    
    private var personalInfoHeader: some View {
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
                Text("Personal Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("This information is required by law\nto verify your identity")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Date of Birth Section
    
    private var dateOfBirthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showDatePicker = true }) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.textTertiary)
                    
                    Text(dateOfBirthText)
                        .font(.inputText)
                        .foregroundColor(viewModel.registrationData.dateOfBirth == nil ? .textTertiary : .textPrimary)
                    
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
            
            if let dob = viewModel.registrationData.dateOfBirth {
                let age = calculateAge(from: dob)
                if age < 18 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption1)
                        Text("You must be at least 18 years old")
                            .font(.caption1)
                    }
                    .foregroundColor(.errorRed)
                } else {
                    Text("Age: \(age) years old")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: Binding(
                    get: { viewModel.registrationData.dateOfBirth ?? maximumDate },
                    set: { viewModel.registrationData.dateOfBirth = $0 }
                ),
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                title: "Date of Birth"
            )
            .presentationDetents([.height(400)])
        }
    }
    
    // MARK: - Citizenship Section
    
    private var citizenshipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Country of Citizenship")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showCitizenshipPicker = true }) {
                HStack {
                    Text(citizenshipFlag)
                        .font(.title3)
                    
                    Text(citizenshipName)
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
        .sheet(isPresented: $showCitizenshipPicker) {
            CountrySelectionSheet(
                selectedCountryCode: $viewModel.registrationData.citizenship,
                title: "Country of Citizenship"
            )
        }
    }
    
    // MARK: - Birth Country Section
    
    private var birthCountrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Country of Birth")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showBirthCountryPicker = true }) {
                HStack {
                    Text(birthCountryFlag)
                        .font(.title3)
                    
                    Text(birthCountryName)
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
        .sheet(isPresented: $showBirthCountryPicker) {
            CountrySelectionSheet(
                selectedCountryCode: $viewModel.registrationData.countryOfBirth,
                title: "Country of Birth"
            )
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 20))
                .foregroundColor(.primaryPurple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your data is protected")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                Text("We use bank-level encryption to keep your personal information secure. This data is only used for identity verification.")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .background(Color.primaryPurple.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var dateOfBirthText: String {
        guard let date = viewModel.registrationData.dateOfBirth else {
            return "Select your date of birth"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private var citizenshipFlag: String {
        Country.common.first { $0.code == viewModel.registrationData.citizenship }?.flag ?? "🇺🇸"
    }
    
    private var citizenshipName: String {
        Country.common.first { $0.code == viewModel.registrationData.citizenship }?.name ?? "United States"
    }
    
    private var birthCountryFlag: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfBirth }?.flag ?? "🇺🇸"
    }
    
    private var birthCountryName: String {
        Country.common.first { $0.code == viewModel.registrationData.countryOfBirth }?.name ?? "United States"
    }
    
    private var isFormValid: Bool {
        guard let dob = viewModel.registrationData.dateOfBirth else { return false }
        return calculateAge(from: dob) >= 18 && !viewModel.registrationData.citizenship.isEmpty
    }
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date, to: Date())
        return components.year ?? 0
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let minimumDate: Date
    let maximumDate: Date
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Done") { dismiss() }
                    .font(.bodyMedium)
                    .foregroundColor(.primaryPurple)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            DatePicker(
                "",
                selection: $selectedDate,
                in: minimumDate...maximumDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            
            Spacer()
        }
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Country Selection Sheet

struct CountrySelectionSheet: View {
    @Binding var selectedCountryCode: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.common
        }
        return Country.common.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCountries) { country in
                    Button(action: {
                        selectedCountryCode = country.code
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Text(country.flag)
                                .font(.title2)
                            
                            Text(country.name)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if country.code == selectedCountryCode {
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
            .navigationTitle(title)
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
    Step3_PersonalInfoView(viewModel: RegistrationViewModel())
}

