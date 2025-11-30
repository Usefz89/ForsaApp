//
//  DateOfBirthPicker.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Date of birth picker with age validation
struct DateOfBirthPicker: View {
    @Binding var selectedDate: Date?
    var label: String = "Date of Birth"
    var minimumAge: Int = 18
    var maximumAge: Int = 120
    var showAgeValidation: Bool = true
    
    @State private var showPicker = false
    @State private var tempDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .year, value: -maximumAge, to: Date()) ?? Date()
    }
    
    private var maximumDate: Date {
        Calendar.current.date(byAdding: .year, value: -minimumAge, to: Date()) ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            // Date display button
            Button(action: { showPicker = true }) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.textTertiary)
                    
                    Text(dateDisplayText)
                        .font(.inputText)
                        .foregroundColor(selectedDate == nil ? .textTertiary : .textPrimary)
                    
                    Spacer()
                    
                    if let date = selectedDate, showAgeValidation {
                        ageIndicator(for: date)
                    }
                    
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
                        .stroke(borderColor, lineWidth: 1)
                )
            }
            
            // Age validation message
            if showAgeValidation, let date = selectedDate {
                ageValidationMessage(for: date)
            }
        }
        .sheet(isPresented: $showPicker) {
            DateOfBirthPickerSheet(
                selectedDate: $selectedDate,
                tempDate: $tempDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                minimumAge: minimumAge
            )
            .presentationDetents([.height(420)])
        }
        .onAppear {
            if let date = selectedDate {
                tempDate = date
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var dateDisplayText: String {
        guard let date = selectedDate else {
            return "Select your date of birth"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private var borderColor: Color {
        guard let date = selectedDate else {
            return .borderPrimary
        }
        return calculateAge(from: date) >= minimumAge ? .successGreen : .errorRed
    }
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date, to: Date())
        return components.year ?? 0
    }
    
    // MARK: - Age Indicator
    
    @ViewBuilder
    private func ageIndicator(for date: Date) -> some View {
        let age = calculateAge(from: date)
        
        if age >= minimumAge {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.successGreen)
        } else {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.errorRed)
        }
    }
    
    @ViewBuilder
    private func ageValidationMessage(for date: Date) -> some View {
        let age = calculateAge(from: date)
        
        if age >= minimumAge {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption1)
                Text("Age: \(age) years old")
                    .font(.caption1)
            }
            .foregroundColor(.successGreen)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption1)
                Text("You must be at least \(minimumAge) years old")
                    .font(.caption1)
            }
            .foregroundColor(.errorRed)
        }
    }
}

// MARK: - Date Picker Sheet

struct DateOfBirthPickerSheet: View {
    @Binding var selectedDate: Date?
    @Binding var tempDate: Date
    let minimumDate: Date
    let maximumDate: Date
    let minimumAge: Int
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text("Date of Birth")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    selectedDate = tempDate
                    dismiss()
                }
                .foregroundColor(.primaryPurple)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.backgroundSecondary)
            
            Divider()
            
            // Age display
            VStack(spacing: 4) {
                let age = calculateAge(from: tempDate)
                Text("\(age)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(age >= minimumAge ? .primaryPurple : .errorRed)
                
                Text("years old")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                
                if age < minimumAge {
                    Text("Must be at least \(minimumAge) years old")
                        .font(.caption1)
                        .foregroundColor(.errorRed)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 20)
            
            // Date picker
            DatePicker(
                "",
                selection: $tempDate,
                in: minimumDate...maximumDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            
            Spacer()
        }
        .background(Color.backgroundPrimary)
    }
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date, to: Date())
        return components.year ?? 0
    }
}

// MARK: - Inline Date of Birth Picker

/// Compact inline version of the date of birth picker
struct InlineDateOfBirthPicker: View {
    @Binding var selectedDate: Date?
    var minimumAge: Int = 18
    
    @State private var month: String = ""
    @State private var day: String = ""
    @State private var year: String = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case month, day, year
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                // Month
                VStack(alignment: .leading, spacing: 4) {
                    Text("Month")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                    
                    TextField("MM", text: $month)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .month)
                        .onChange(of: month) { _, newValue in
                            month = String(newValue.filter { $0.isNumber }.prefix(2))
                            if month.count == 2 {
                                focusedField = .day
                            }
                            updateDate()
                        }
                        .frame(height: 48)
                        .background(Color.backgroundCard)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .month ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .month ? 2 : 1)
                        )
                }
                .frame(width: 70)
                
                // Day
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                    
                    TextField("DD", text: $day)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .day)
                        .onChange(of: day) { _, newValue in
                            day = String(newValue.filter { $0.isNumber }.prefix(2))
                            if day.count == 2 {
                                focusedField = .year
                            }
                            updateDate()
                        }
                        .frame(height: 48)
                        .background(Color.backgroundCard)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .day ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .day ? 2 : 1)
                        )
                }
                .frame(width: 70)
                
                // Year
                VStack(alignment: .leading, spacing: 4) {
                    Text("Year")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                    
                    TextField("YYYY", text: $year)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .year)
                        .onChange(of: year) { _, newValue in
                            year = String(newValue.filter { $0.isNumber }.prefix(4))
                            updateDate()
                        }
                        .frame(height: 48)
                        .background(Color.backgroundCard)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .year ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .year ? 2 : 1)
                        )
                }
            }
            
            // Validation
            if let date = selectedDate {
                let age = calculateAge(from: date)
                if age < minimumAge {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption1)
                        Text("You must be at least \(minimumAge) years old")
                            .font(.caption1)
                    }
                    .foregroundColor(.errorRed)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption1)
                        Text("Age: \(age) years old")
                            .font(.caption1)
                    }
                    .foregroundColor(.successGreen)
                }
            }
        }
        .onAppear {
            if let date = selectedDate {
                let components = Calendar.current.dateComponents([.month, .day, .year], from: date)
                month = String(format: "%02d", components.month ?? 0)
                day = String(format: "%02d", components.day ?? 0)
                year = String(components.year ?? 0)
            }
        }
    }
    
    private func updateDate() {
        guard let m = Int(month), let d = Int(day), let y = Int(year),
              m >= 1, m <= 12, d >= 1, d <= 31, year.count == 4 else {
            selectedDate = nil
            return
        }
        
        var components = DateComponents()
        components.month = m
        components.day = d
        components.year = y
        
        selectedDate = Calendar.current.date(from: components)
    }
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date, to: Date())
        return components.year ?? 0
    }
}

// MARK: - Previews

#Preview("Date of Birth Picker") {
    VStack(spacing: 24) {
        DateOfBirthPicker(selectedDate: .constant(nil))
        DateOfBirthPicker(
            selectedDate: .constant(Calendar.current.date(byAdding: .year, value: -25, to: Date()))
        )
        DateOfBirthPicker(
            selectedDate: .constant(Calendar.current.date(byAdding: .year, value: -16, to: Date()))
        )
    }
    .padding()
}

#Preview("Inline Date Picker") {
    InlineDateOfBirthPicker(selectedDate: .constant(nil))
        .padding()
}



