//
//  SSNInputField.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Secure, masked SSN input field with formatting and validation
struct SSNInputField: View {
    @Binding var ssn: String
    var label: String = "Social Security Number"
    var placeholder: String = "XXX-XX-XXXX"
    var showValidation: Bool = true
    
    @State private var isSecure = true
    @State private var isFocused = false
    @FocusState private var textFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label row
            HStack {
                Text(label)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Show/hide toggle
                Button(action: { isSecure.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isSecure ? "eye.fill" : "eye.slash.fill")
                            .font(.caption)
                        Text(isSecure ? "Show" : "Hide")
                            .font(.caption1)
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryPurple)
                
                if isSecure {
                    // Masked display
                    Text(maskedValue)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(ssn.isEmpty ? .textTertiary : .textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            isSecure = false
                            textFieldFocused = true
                        }
                } else {
                    // Editable field
                    TextField(placeholder, text: Binding(
                        get: { formattedSSN },
                        set: { handleInput($0) }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .keyboardType(.numberPad)
                    .focused($textFieldFocused)
                    .onChange(of: textFieldFocused) { _, focused in
                        isFocused = focused
                        if !focused && !ssn.isEmpty {
                            // Auto-hide when losing focus
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isSecure = true
                            }
                        }
                    }
                }
                
                // Validation indicator
                if showValidation && !ssn.isEmpty {
                    validationIndicator
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
            
            // Helper text / validation message
            if showValidation {
                validationMessage
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedSSN: String {
        formatSSN(ssn)
    }
    
    private var maskedValue: String {
        guard !ssn.isEmpty else { return placeholder }
        
        let digits = ssn.filter { $0.isNumber }
        if digits.count <= 4 {
            return "•••-••-\(String(repeating: "•", count: max(0, 4 - digits.count)))\(digits)"
        }
        
        // Show last 4 digits
        let last4 = String(digits.suffix(4))
        return "•••-••-\(last4)"
    }
    
    private var isValid: Bool {
        ssn.filter { $0.isNumber }.count == 9
    }
    
    private var borderColor: Color {
        if isFocused {
            return .primaryPurple
        }
        if !ssn.isEmpty && !isValid {
            return .warningYellow
        }
        if isValid {
            return .successGreen
        }
        return .borderPrimary
    }
    
    @ViewBuilder
    private var validationIndicator: some View {
        if isValid {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.successGreen)
        } else {
            let remaining = 9 - ssn.filter { $0.isNumber }.count
            Text("\(remaining)")
                .font(.caption1Medium)
                .foregroundColor(.textTertiary)
                .frame(width: 20)
        }
    }
    
    @ViewBuilder
    private var validationMessage: some View {
        if ssn.isEmpty {
            EmptyView()
        } else if isValid {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption1)
                Text("Valid SSN format")
                    .font(.caption1)
            }
            .foregroundColor(.successGreen)
        } else {
            let remaining = 9 - ssn.filter { $0.isNumber }.count
            Text("\(remaining) more digit\(remaining == 1 ? "" : "s") needed")
                .font(.caption1)
                .foregroundColor(.textTertiary)
        }
    }
    
    // MARK: - Formatting
    
    private func formatSSN(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var result = ""
        
        for (index, digit) in digits.prefix(9).enumerated() {
            if index == 3 || index == 5 {
                result += "-"
            }
            result += String(digit)
        }
        
        return result
    }
    
    private func handleInput(_ input: String) {
        // Extract only digits
        let digits = input.filter { $0.isNumber }
        
        // Limit to 9 digits
        ssn = String(digits.prefix(9))
    }
}

// MARK: - SSN Segment Input (Alternative Style)

/// Alternative SSN input with separate segment fields
struct SSNSegmentInput: View {
    @Binding var ssn: String
    
    @State private var segment1 = ""
    @State private var segment2 = ""
    @State private var segment3 = ""
    @State private var isSecure = true
    
    @FocusState private var focusedSegment: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Social Security Number")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: { isSecure.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isSecure ? "eye.fill" : "eye.slash.fill")
                            .font(.caption)
                        Text(isSecure ? "Show" : "Hide")
                            .font(.caption1)
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
            
            HStack(spacing: 8) {
                // First segment (3 digits)
                segmentField(
                    text: $segment1,
                    maxLength: 3,
                    placeholder: "•••",
                    segmentIndex: 0
                )
                
                Text("-")
                    .font(.title3)
                    .foregroundColor(.textTertiary)
                
                // Second segment (2 digits)
                segmentField(
                    text: $segment2,
                    maxLength: 2,
                    placeholder: "••",
                    segmentIndex: 1
                )
                
                Text("-")
                    .font(.title3)
                    .foregroundColor(.textTertiary)
                
                // Third segment (4 digits)
                segmentField(
                    text: $segment3,
                    maxLength: 4,
                    placeholder: "••••",
                    segmentIndex: 2
                )
            }
        }
        .onChange(of: segment1 + segment2 + segment3) { _, newValue in
            ssn = newValue
        }
        .onAppear {
            // Split existing SSN into segments
            let digits = ssn.filter { $0.isNumber }
            if digits.count >= 3 {
                segment1 = String(digits.prefix(3))
            }
            if digits.count >= 5 {
                segment2 = String(digits.dropFirst(3).prefix(2))
            }
            if digits.count >= 9 {
                segment3 = String(digits.dropFirst(5).prefix(4))
            }
        }
    }
    
    private func segmentField(text: Binding<String>, maxLength: Int, placeholder: String, segmentIndex: Int) -> some View {
        let isFocused = focusedSegment == segmentIndex
        
        return Group {
            if isSecure && !text.wrappedValue.isEmpty {
                Text(String(repeating: "•", count: text.wrappedValue.count))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.backgroundCard)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.borderPrimary, lineWidth: 1)
                    )
                    .onTapGesture {
                        isSecure = false
                        focusedSegment = segmentIndex
                    }
            } else {
                TextField(placeholder, text: text)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusedSegment, equals: segmentIndex)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        // Filter to only digits and limit length
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > maxLength {
                            text.wrappedValue = String(filtered.prefix(maxLength))
                        } else {
                            text.wrappedValue = filtered
                        }
                        
                        // Auto-advance to next segment
                        if text.wrappedValue.count == maxLength && segmentIndex < 2 {
                            focusedSegment = segmentIndex + 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.backgroundCard)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? Color.primaryPurple : Color.borderPrimary, lineWidth: isFocused ? 2 : 1)
                    )
            }
        }
    }
}

// MARK: - Previews

#Preview("SSN Input Field") {
    VStack(spacing: 24) {
        SSNInputField(ssn: .constant(""))
        SSNInputField(ssn: .constant("123456789"))
        SSNInputField(ssn: .constant("12345"))
    }
    .padding()
}

#Preview("SSN Segment Input") {
    VStack(spacing: 24) {
        SSNSegmentInput(ssn: .constant(""))
        SSNSegmentInput(ssn: .constant("123456789"))
    }
    .padding()
}


