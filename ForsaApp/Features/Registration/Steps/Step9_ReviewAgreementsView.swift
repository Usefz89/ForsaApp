//
//  Step9_ReviewAgreementsView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 9: Review & Agreements - Review information and accept terms
/// Final review step before account creation with legal agreements
struct Step9_ReviewAgreementsView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var expandedSection: ReviewSection?
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var showAccountSheet = false
    @State private var showCustomerSheet = false
    
    // MARK: - Animation & Feedback
    private let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()
    
    enum ReviewSection: String, CaseIterable {
        case personal = "Personal Information"
        case address = "Home Address"
        case financial = "Financial Profile"
        case disclosures = "Disclosures"
    }
    
    var body: some View {
        RegistrationStepContainer(
            buttonTitle: "Create Account",
            isButtonDisabled: !allAgreementsAccepted,
            isLoading: viewModel.isLoading,
            onPrimaryTap: {
                impactFeedback.impactOccurred()
                Task {
                    await viewModel.submitRegistration()
                    if viewModel.registrationComplete {
                        successFeedback.notificationOccurred(.success)
                    }
                }
            }
        ) {
            VStack(spacing: 24) {
                // Header
                reviewHeader
                
                // Validation errors from previous steps (if any)
                if hasValidationErrors {
                    validationErrorsSection
                }
                
                // Review sections
                reviewSections
                
                // Agreements
                agreementsSection
            }
        }
    }
    
    // MARK: - Validation Errors Section
    
    private var hasValidationErrors: Bool {
        let stepsToCheck: [RegistrationStep] = [
            .basicInfo, .phoneVerification, .personalDetails,
            .address, .taxFinancial, .disclosures
        ]
        return stepsToCheck.contains { step in
            !(viewModel.stepValidationErrors[step]?.isEmpty ?? true)
        }
    }
    
    private var validationErrorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.warningYellow)
                Text("Please fix the following issues:")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(stepsWithErrors, id: \.step) { stepError in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.errorRed)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stepError.step.title)
                                .font(.calloutMedium)
                                .foregroundColor(.textPrimary)
                            
                            ForEach(stepError.errors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption1)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.warningYellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.warningYellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var stepsWithErrors: [(step: RegistrationStep, errors: [String])] {
        let stepsToCheck: [RegistrationStep] = [
            .basicInfo, .phoneVerification, .personalDetails,
            .address, .taxFinancial, .disclosures
        ]
        return stepsToCheck.compactMap { step in
            if let errors = viewModel.stepValidationErrors[step], !errors.isEmpty {
                return (step: step, errors: errors)
            }
            return nil
        }
    }
    
    // MARK: - Header
    
    private var reviewHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                Text("Review & Confirm")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Please review your information and\naccept the agreements below")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Review Sections
    
    private var reviewSections: some View {
        VStack(spacing: 12) {
            Text("Your Information")
                .font(.headline)
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(ReviewSection.allCases, id: \.self) { section in
                ReviewSectionCard(
                    section: section,
                    isExpanded: expandedSection == section,
                    viewModel: viewModel,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            expandedSection = expandedSection == section ? nil : section
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Agreements Section
    
    private var agreementsSection: some View {
        VStack(spacing: 16) {
            Text("Agreements")
                .font(.headline)
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                AgreementRow(
                    title: "Terms of Service",
                    isAccepted: $viewModel.registrationData.agreedToTerms,
                    onViewTap: { showTermsSheet = true }
                )
                
                AgreementRow(
                    title: "Privacy Policy",
                    isAccepted: $viewModel.registrationData.agreedToPrivacy,
                    onViewTap: { showPrivacySheet = true }
                )
                
                AgreementRow(
                    title: "Account Agreement",
                    isAccepted: $viewModel.registrationData.agreedToAccountAgreement,
                    onViewTap: { showAccountSheet = true }
                )
                
                AgreementRow(
                    title: "Customer Agreement",
                    isAccepted: $viewModel.registrationData.agreedToCustomerAgreement,
                    onViewTap: { showCustomerSheet = true }
                )
            }
            
            // Accept all button
            if !allAgreementsAccepted {
                Button(action: acceptAllAgreements) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Accept All Agreements")
                            .font(.calloutMedium)
                    }
                    .foregroundColor(.primaryPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primaryPurple.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            // SIPC disclosure
            SIPCDisclosure()
        }
        .sheet(isPresented: $showTermsSheet) {
            AgreementDetailSheet(title: "Terms of Service", type: .terms)
        }
        .sheet(isPresented: $showPrivacySheet) {
            AgreementDetailSheet(title: "Privacy Policy", type: .privacy)
        }
        .sheet(isPresented: $showAccountSheet) {
            AgreementDetailSheet(title: "Account Agreement", type: .account)
        }
        .sheet(isPresented: $showCustomerSheet) {
            AgreementDetailSheet(title: "Customer Agreement", type: .customer)
        }
    }
    
    // MARK: - Computed Properties
    
    private var allAgreementsAccepted: Bool {
        viewModel.registrationData.agreedToTerms &&
        viewModel.registrationData.agreedToPrivacy &&
        viewModel.registrationData.agreedToAccountAgreement &&
        viewModel.registrationData.agreedToCustomerAgreement
    }
    
    private func acceptAllAgreements() {
        impactFeedback.impactOccurred()
        withAnimation(springAnimation) {
            viewModel.registrationData.agreedToTerms = true
            viewModel.registrationData.agreedToPrivacy = true
            viewModel.registrationData.agreedToAccountAgreement = true
            viewModel.registrationData.agreedToCustomerAgreement = true
        }
    }
}

// MARK: - Review Section Card

struct ReviewSectionCard: View {
    let section: Step9_ReviewAgreementsView.ReviewSection
    let isExpanded: Bool
    let viewModel: RegistrationViewModel
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Image(systemName: sectionIcon)
                        .font(.system(size: 18))
                        .foregroundColor(.primaryPurple)
                        .frame(width: 32)
                    
                    Text(section.rawValue)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(16)
                .background(Color.backgroundCard)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    sectionContent
                        .padding(16)
                }
                .background(Color.backgroundSecondary)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderPrimary, lineWidth: 1)
        )
    }
    
    private var sectionIcon: String {
        switch section {
        case .personal: return "person.fill"
        case .address: return "location.fill"
        case .financial: return "dollarsign.circle.fill"
        case .disclosures: return "doc.text.fill"
        }
    }
    
    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .personal:
            VStack(alignment: .leading, spacing: 8) {
                ReviewRow(label: "Name", value: viewModel.registrationData.fullName)
                ReviewRow(label: "Email", value: viewModel.registrationData.email)
                ReviewRow(label: "Phone", value: formatPhoneForDisplay(viewModel.registrationData.phoneNumber, country: viewModel.registrationData.country))
                if let dob = viewModel.registrationData.dateOfBirth {
                    ReviewRow(label: "Date of Birth", value: formatDate(dob))
                }
                ReviewRow(label: "Citizenship", value: formatCountryName(viewModel.registrationData.citizenship))
            }
            
        case .address:
            VStack(alignment: .leading, spacing: 8) {
                // Check if Kuwait address format
                if viewModel.registrationData.country == "KWT" {
                    // Kuwait-specific address fields
                    ReviewRow(label: "Area", value: viewModel.registrationData.area)
                    ReviewRow(label: "Governorate", value: viewModel.registrationData.governorate)
                    ReviewRow(label: "Block", value: viewModel.registrationData.block)
                    ReviewRow(label: "Street", value: viewModel.registrationData.streetAddress)
                    ReviewRow(label: "Building", value: viewModel.registrationData.building)
                    if let floor = viewModel.registrationData.floor, !floor.isEmpty {
                        ReviewRow(label: "Floor", value: floor)
                    }
                    if let unit = viewModel.registrationData.apartmentUnit, !unit.isEmpty {
                        ReviewRow(label: "Apt", value: unit)
                    }
                    ReviewRow(label: "Country", value: "🇰🇼 Kuwait")
                } else {
                    // International address format
                    ReviewRow(label: "Street", value: viewModel.registrationData.streetAddress)
                    if let unit = viewModel.registrationData.apartmentUnit, !unit.isEmpty {
                        ReviewRow(label: "Unit", value: unit)
                    }
                    ReviewRow(label: "City", value: viewModel.registrationData.city)
                    ReviewRow(label: "State", value: viewModel.registrationData.state)
                    ReviewRow(label: "ZIP", value: viewModel.registrationData.postalCode)
                }
            }
            
        case .financial:
            VStack(alignment: .leading, spacing: 8) {
                ReviewRow(label: "Employment", value: viewModel.registrationData.employmentStatus.displayName)
                if let income = viewModel.registrationData.annualIncome {
                    ReviewRow(label: "Annual Income", value: income.displayName)
                }
                if !viewModel.registrationData.fundingSources.isEmpty {
                    ReviewRow(
                        label: "Funding Sources",
                        value: viewModel.registrationData.fundingSources.map { $0.displayName }.joined(separator: ", ")
                    )
                }
            }
            
        case .disclosures:
            VStack(alignment: .leading, spacing: 8) {
                ReviewRow(label: "Control Person", value: viewModel.registrationData.isControlPerson ? "Yes" : "No")
                ReviewRow(label: "Exchange Affiliated", value: viewModel.registrationData.isAffiliatedWithExchange ? "Yes" : "No")
                ReviewRow(label: "Politically Exposed", value: viewModel.registrationData.isPoliticallyExposed ? "Yes" : "No")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Format phone number based on country
    private func formatPhoneForDisplay(_ phone: String, country: String) -> String {
        let digits = phone.filter { $0.isNumber }
        
        if country == "KWT" {
            // Kuwait format: +965 XXXX XXXX (8 digits)
            if digits.count == 8 {
                let index1 = digits.index(digits.startIndex, offsetBy: 4)
                return "+965 \(digits[..<index1]) \(digits[index1...])"
            }
            return "+965 \(digits)"
        } else if country == "USA" {
            // US format: (XXX) XXX-XXXX
            return viewModel.formatPhoneNumber(phone)
        } else {
            // Generic international format
            let dialCode = Country.common.first { $0.code == country }?.dialCode ?? ""
            return "\(dialCode) \(digits)"
        }
    }
    
    /// Format country code to country name with flag
    private func formatCountryName(_ code: String) -> String {
        if let country = Country.common.first(where: { $0.code == code }) {
            return "\(country.flag) \(country.name)"
        }
        return code
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption1)
                .foregroundColor(.textTertiary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.callout)
                .foregroundColor(.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Agreement Row

struct AgreementRow: View {
    let title: String
    @Binding var isAccepted: Bool
    let onViewTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.2)) {
                    isAccepted.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isAccepted ? Color.primaryPurple : Color.borderPrimary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isAccepted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primaryPurple)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text("I agree to the")
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            Button(action: onViewTap) {
                Text(title)
                    .font(.calloutMedium)
                    .foregroundColor(.primaryPurple)
                    .underline()
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.backgroundCard)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isAccepted ? Color.primaryPurple.opacity(0.3) : Color.borderPrimary, lineWidth: 1)
        )
    }
}

// MARK: - SIPC Disclosure

struct SIPCDisclosure: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.fill")
                .font(.system(size: 18))
                .foregroundColor(.successGreen)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("SIPC Protected")
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                Text("Your securities are protected up to $500,000 (including $250,000 for cash claims) by the Securities Investor Protection Corporation (SIPC).")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .background(Color.successGreen.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.successGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Agreement Detail Sheet

enum AgreementType {
    case terms, privacy, account, customer
}

struct AgreementDetailSheet: View {
    let title: String
    let type: AgreementType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(agreementText)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .padding()
                }
            }
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
    
    private var agreementText: String {
        // Placeholder text - in production, this would be actual legal text
        switch type {
        case .terms:
            return """
            TERMS OF SERVICE
            
            Last Updated: November 2025
            
            Welcome to Forsa. These Terms of Service govern your use of our mobile application and services.
            
            1. Acceptance of Terms
            By accessing or using Forsa, you agree to be bound by these Terms and all applicable laws and regulations.
            
            2. Account Registration
            You must provide accurate and complete information when creating an account. You are responsible for maintaining the confidentiality of your account credentials.
            
            3. Halal Investment Standards
            Forsa provides investment services that comply with Islamic finance principles. We screen all investments for Sharia compliance using established guidelines.
            
            4. Investment Risks
            All investments carry risk. Past performance does not guarantee future results. You may lose some or all of your invested capital.
            
            5. Fees and Charges
            Current fee schedules are available in the app. We reserve the right to modify fees with advance notice.
            
            [Additional terms would continue here...]
            """
            
        case .privacy:
            return """
            PRIVACY POLICY
            
            Last Updated: November 2025
            
            This Privacy Policy describes how Forsa collects, uses, and protects your personal information.
            
            1. Information We Collect
            - Personal identification information (name, email, phone, SSN)
            - Financial information (income, net worth, employment)
            - Transaction data and investment history
            - Device and usage information
            
            2. How We Use Your Information
            - To verify your identity and open your account
            - To process transactions and provide services
            - To comply with regulatory requirements
            - To improve our services and user experience
            
            3. Data Security
            We use industry-standard encryption and security measures to protect your data. Your SSN and sensitive financial information is encrypted at rest and in transit.
            
            4. Third-Party Sharing
            We share information only as required by law or with service providers necessary to operate our platform.
            
            [Additional privacy terms would continue here...]
            """
            
        case .account:
            return """
            ACCOUNT AGREEMENT
            
            Last Updated: November 2025
            
            This Account Agreement governs your brokerage account with Forsa.
            
            1. Account Type
            Your account is a self-directed brokerage account. You are responsible for all investment decisions.
            
            2. Margin
            Margin trading is not currently available. All trades must be fully funded.
            
            3. Order Execution
            Orders are executed through our clearing partner. Market orders are executed at the best available price.
            
            4. Account Statements
            Electronic statements are provided monthly. You agree to review statements promptly and report any errors.
            
            5. Tax Reporting
            We provide Form 1099-B for taxable events. Consult a tax professional for advice.
            
            [Additional account terms would continue here...]
            """
            
        case .customer:
            return """
            CUSTOMER AGREEMENT
            
            Last Updated: November 2025
            
            This Customer Agreement sets forth the terms under which Forsa provides brokerage services.
            
            1. Brokerage Services
            Forsa provides self-directed brokerage services for buying and selling securities.
            
            2. Custody of Assets
            Your securities are held in custody by our clearing broker. Cash is held in FDIC-insured bank accounts.
            
            3. SIPC Protection
            Your account is protected by SIPC up to $500,000 (including $250,000 for cash).
            
            4. Dispute Resolution
            Any disputes will be resolved through binding arbitration in accordance with FINRA rules.
            
            5. Amendments
            We may amend this agreement with 30 days notice. Continued use constitutes acceptance.
            
            [Additional customer agreement terms would continue here...]
            """
        }
    }
}

// MARK: - Previews

#Preview("Review - Empty") {
    Step9_ReviewAgreementsView(viewModel: RegistrationViewModel())
}

#Preview("Review - With Data") {
    Step9_ReviewAgreementsView(viewModel: {
        let vm = RegistrationViewModel()
        vm.registrationData.firstName = "Ahmed"
        vm.registrationData.lastName = "Al-Khalid"
        vm.registrationData.email = "ahmed@example.com"
        vm.registrationData.phoneNumber = "99887766"
        vm.registrationData.country = "KWT"
        vm.registrationData.area = "Salmiya"
        vm.registrationData.governorate = "Hawalli"
        return vm
    }())
}

#Preview("Review - All Agreed") {
    Step9_ReviewAgreementsView(viewModel: {
        let vm = RegistrationViewModel()
        vm.registrationData.agreedToTerms = true
        vm.registrationData.agreedToPrivacy = true
        vm.registrationData.agreedToAccountAgreement = true
        vm.registrationData.agreedToCustomerAgreement = true
        return vm
    }())
}

#Preview("Agreement Row") {
    AgreementRow(
        title: "Terms of Service",
        isAccepted: .constant(true),
        onViewTap: {}
    )
    .padding()
}

