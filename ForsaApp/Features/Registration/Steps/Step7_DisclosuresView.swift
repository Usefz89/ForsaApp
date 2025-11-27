//
//  Step7_DisclosuresView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 7: Regulatory Disclosures - Control person, FINRA affiliation, politically exposed
struct Step7_DisclosuresView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var showControlPersonInfo = false
    @State private var showAffiliationInfo = false
    @State private var showPoliticalInfo = false
    
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
                disclosuresHeader
                
                // Disclosure questions
                disclosureQuestions
                
                // Info footer
                regulatoryInfo
            }
        }
    }
    
    // MARK: - Header
    
    private var disclosuresHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Regulatory Disclosures")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Help us comply with SEC and FINRA regulations.\nMost people answer \"No\" to all questions.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Disclosure Questions
    
    private var disclosureQuestions: some View {
        VStack(spacing: 16) {
            // Control Person
            DisclosureCard(
                title: "Control Person",
                description: "Are you a director, officer, or 10%+ shareholder of a publicly traded company?",
                isChecked: $viewModel.registrationData.isControlPerson,
                showInfo: $showControlPersonInfo,
                infoTitle: "What is a Control Person?",
                infoText: "A control person is someone who has the power to influence or direct the management and policies of a publicly traded company. This typically includes directors, executive officers, or shareholders who own 10% or more of the company's stock."
            )
            
            // Control Person Context
            if viewModel.registrationData.isControlPerson {
                DisclosureContextField(
                    placeholder: "Company name and your position",
                    text: Binding(
                        get: { viewModel.registrationData.controlPersonContext ?? "" },
                        set: { viewModel.registrationData.controlPersonContext = $0.isEmpty ? nil : $0 }
                    )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // FINRA Affiliation
            DisclosureCard(
                title: "Exchange Affiliation",
                description: "Are you affiliated with or employed by a stock exchange, FINRA, or a broker-dealer?",
                isChecked: $viewModel.registrationData.isAffiliatedWithExchange,
                showInfo: $showAffiliationInfo,
                infoTitle: "What counts as affiliated?",
                infoText: "This includes employees, registered representatives, or immediate family members of someone who works at a securities exchange (NYSE, NASDAQ), FINRA (Financial Industry Regulatory Authority), or a registered broker-dealer."
            )
            
            // Affiliation Context
            if viewModel.registrationData.isAffiliatedWithExchange {
                DisclosureContextField(
                    placeholder: "Organization name and your relationship",
                    text: Binding(
                        get: { viewModel.registrationData.affiliationContext ?? "" },
                        set: { viewModel.registrationData.affiliationContext = $0.isEmpty ? nil : $0 }
                    )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Politically Exposed Person
            DisclosureCard(
                title: "Politically Exposed Person",
                description: "Are you or an immediate family member a senior political figure or government official?",
                isChecked: $viewModel.registrationData.isPoliticallyExposed,
                showInfo: $showPoliticalInfo,
                infoTitle: "What is a PEP?",
                infoText: "A Politically Exposed Person (PEP) is someone who holds or has held a prominent public position, such as a head of state, senior politician, judicial official, senior military officer, or executive of a state-owned corporation. Immediate family members are also considered."
            )
            
            // Political Context
            if viewModel.registrationData.isPoliticallyExposed {
                DisclosureContextField(
                    placeholder: "Position and government/organization",
                    text: Binding(
                        get: { viewModel.registrationData.politicalExposureContext ?? "" },
                        set: { viewModel.registrationData.politicalExposureContext = $0.isEmpty ? nil : $0 }
                    )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Immediate Family Exposed
            if viewModel.registrationData.isPoliticallyExposed {
                DisclosureCard(
                    title: "Family Member Status",
                    description: "Is the politically exposed person an immediate family member rather than yourself?",
                    isChecked: $viewModel.registrationData.immediateFamilyExposed,
                    showInfo: .constant(false),
                    infoTitle: "",
                    infoText: ""
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                
                // EC-3: Family Relationship Context
                if viewModel.registrationData.immediateFamilyExposed {
                    FamilyRelationshipPicker(
                        selectedRelationship: Binding(
                            get: { viewModel.registrationData.immediateFamilyExposedContext ?? "" },
                            set: { viewModel.registrationData.immediateFamilyExposedContext = $0.isEmpty ? nil : $0 }
                        )
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.registrationData.isControlPerson)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.registrationData.isAffiliatedWithExchange)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.registrationData.isPoliticallyExposed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.registrationData.immediateFamilyExposed)
    }
    
    // MARK: - Regulatory Info
    
    private var regulatoryInfo: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.primaryBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Why do we ask this?")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                Text("The SEC requires all brokerages to collect this information to prevent insider trading and monitor for potential conflicts of interest. Your answers do not affect your ability to open an account.")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .background(Color.primaryBlue.opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        let controlValid = !viewModel.registrationData.isControlPerson ||
            !(viewModel.registrationData.controlPersonContext?.isEmpty ?? true)
        let affiliationValid = !viewModel.registrationData.isAffiliatedWithExchange ||
            !(viewModel.registrationData.affiliationContext?.isEmpty ?? true)
        let politicalValid = !viewModel.registrationData.isPoliticallyExposed ||
            !(viewModel.registrationData.politicalExposureContext?.isEmpty ?? true)
        // EC-3: Require family relationship context when immediate family is exposed
        let familyExposedValid = !viewModel.registrationData.immediateFamilyExposed ||
            !(viewModel.registrationData.immediateFamilyExposedContext?.isEmpty ?? true)
        
        return controlValid && affiliationValid && politicalValid && familyExposedValid
    }
}

// MARK: - Disclosure Card

struct DisclosureCard: View {
    let title: String
    let description: String
    @Binding var isChecked: Bool
    @Binding var showInfo: Bool
    let infoTitle: String
    let infoText: String
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isChecked.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 14) {
                    // Checkbox
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isChecked ? Color.primaryPurple : Color.borderPrimary, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isChecked {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primaryPurple)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 2)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(title)
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            if !infoTitle.isEmpty {
                                Button(action: { showInfo = true }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textTertiary)
                                }
                            }
                        }
                        
                        Text(description)
                            .font(.caption1)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isChecked ? Color.primaryPurple : Color.borderPrimary, lineWidth: isChecked ? 2 : 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showInfo) {
            DisclosureInfoSheet(title: infoTitle, text: infoText)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Disclosure Context Field

struct DisclosureContextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Please provide details:")
                .font(.caption1)
                .foregroundColor(.textSecondary)
            
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.inputText)
                .foregroundColor(.textPrimary)
                .lineLimit(2...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.primaryPurple : Color.borderPrimary, lineWidth: isFocused ? 2 : 1)
                )
                .focused($isFocused)
        }
        .padding(.leading, 38) // Indent to align with checkbox content
    }
}

// MARK: - Disclosure Info Sheet

struct DisclosureInfoSheet: View {
    let title: String
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            VStack(spacing: 16) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.primaryPurple)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            ForsaButton("Got it", style: .primary, size: .large) {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Family Relationship Picker

/// Picker for selecting the family relationship type for PEP disclosures
struct FamilyRelationshipPicker: View {
    @Binding var selectedRelationship: String
    
    private let relationships = [
        ("spouse", "Spouse", "heart.fill"),
        ("parent", "Parent", "person.fill"),
        ("child", "Child", "figure.and.child.holdinghands"),
        ("sibling", "Sibling", "person.2.fill"),
        ("in_law", "In-Law", "person.2.wave.2.fill"),
        ("other", "Other Relative", "person.3.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What is their relationship to you?")
                .font(.caption1)
                .foregroundColor(.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(relationships, id: \.0) { relationship in
                    RelationshipOptionButton(
                        value: relationship.0,
                        label: relationship.1,
                        icon: relationship.2,
                        isSelected: selectedRelationship == relationship.0,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedRelationship = relationship.0
                            }
                        }
                    )
                }
            }
        }
        .padding(.leading, 38) // Indent to align with checkbox content
    }
}

/// Individual relationship option button
struct RelationshipOptionButton: View {
    let value: String
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primaryPurple)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.primaryPurple : Color.backgroundCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    Step7_DisclosuresView(viewModel: RegistrationViewModel())
}

