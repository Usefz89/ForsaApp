//
//  CountryPicker.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Country picker component with search and flag display
struct CountryPicker: View {
    @Binding var selectedCountryCode: String
    var label: String = "Country"
    var placeholder: String = "Select a country"
    var showFlags: Bool = true
    
    @State private var showPicker = false
    
    private var selectedCountry: Country? {
        Country.common.first { $0.code == selectedCountryCode }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showPicker = true }) {
                HStack {
                    if let country = selectedCountry {
                        if showFlags {
                            Text(country.flag)
                                .font(.title3)
                        }
                        
                        Text(country.name)
                            .font(.inputText)
                            .foregroundColor(.textPrimary)
                    } else {
                        Text(placeholder)
                            .font(.inputText)
                            .foregroundColor(.textTertiary)
                    }
                    
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
        .sheet(isPresented: $showPicker) {
            CountryPickerListSheet(
                selectedCountryCode: $selectedCountryCode,
                showFlags: showFlags
            )
        }
    }
}

// MARK: - Country Picker List Sheet

struct CountryPickerListSheet: View {
    @Binding var selectedCountryCode: String
    var showFlags: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var allCountries: [Country] {
        Country.common
    }
    
    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return allCountries
        }
        return allCountries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Popular countries shown at top
    private let popularCountryCodes = ["USA", "CAN", "GBR", "AUS", "DEU", "ARE", "SAU", "KWT"]
    
    private var popularCountries: [Country] {
        popularCountryCodes.compactMap { code in
            allCountries.first { $0.code == code }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Popular countries section (only when not searching)
                if searchText.isEmpty {
                    Section("Popular") {
                        ForEach(popularCountries) { country in
                            countryRow(country)
                        }
                    }
                    
                    Section("All Countries") {
                        ForEach(allCountries) { country in
                            countryRow(country)
                        }
                    }
                } else {
                    ForEach(filteredCountries) { country in
                        countryRow(country)
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
    
    private func countryRow(_ country: Country) -> some View {
        Button(action: {
            selectedCountryCode = country.code
            dismiss()
        }) {
            HStack(spacing: 12) {
                if showFlags {
                    Text(country.flag)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                    
                    Text(country.code)
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
                
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

// MARK: - Compact Country Selector

/// Inline compact country selector with horizontal scroll
struct CompactCountrySelector: View {
    @Binding var selectedCountryCode: String
    var label: String?
    var popularOnly: Bool = true
    
    private var countries: [Country] {
        if popularOnly {
            let popularCodes = ["USA", "CAN", "GBR", "AUS", "ARE", "SAU", "KWT", "IND"]
            return popularCodes.compactMap { code in
                Country.common.first { $0.code == code }
            }
        }
        return Country.common
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(countries) { country in
                        CountryChip(
                            country: country,
                            isSelected: country.code == selectedCountryCode,
                            action: { selectedCountryCode = country.code }
                        )
                    }
                }
                .padding(.horizontal, 1) // Prevent clipping
            }
        }
    }
}

struct CountryChip: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(country.flag)
                    .font(.body)
                
                Text(country.code)
                    .font(.caption1Medium)
                    .foregroundColor(isSelected ? .white : .textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primaryPurple : Color.backgroundCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: 1)
            )
        }
    }
}

// MARK: - Country Grid Selector

/// Grid-based country selector for larger displays
struct CountryGridSelector: View {
    @Binding var selectedCountryCode: String
    var columns: Int = 2
    
    private let countries = Country.common
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(countries) { country in
                CountryGridCell(
                    country: country,
                    isSelected: country.code == selectedCountryCode,
                    action: { selectedCountryCode = country.code }
                )
            }
        }
    }
}

struct CountryGridCell: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(country.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.caption1Medium)
                        .foregroundColor(isSelected ? .white : .textPrimary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.primaryPurple : Color.backgroundCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Previews

#Preview("Country Picker") {
    VStack(spacing: 24) {
        CountryPicker(selectedCountryCode: .constant("USA"))
        CountryPicker(selectedCountryCode: .constant(""))
    }
    .padding()
}

#Preview("Compact Selector") {
    CompactCountrySelector(
        selectedCountryCode: .constant("USA"),
        label: "Select Country"
    )
    .padding()
}

#Preview("Grid Selector") {
    ScrollView {
        CountryGridSelector(selectedCountryCode: .constant("USA"))
            .padding()
    }
}



