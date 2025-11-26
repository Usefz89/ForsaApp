//
//  Step8_TrustedContactView.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Step 8: Trusted Contact (Optional) - Emergency contact information
struct Step8_TrustedContactView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    
    @State private var addContact = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, email, phone
    }
    
    var body: some View {
        RegistrationStepContainer(
            buttonTitle: addContact ? "Add Contact & Continue" : "Skip for Now",
            isButtonDisabled: addContact && !isContactValid,
            showSecondaryButton: addContact,
            secondaryButtonTitle: "Skip this step",
            onPrimaryTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.nextStep()
                }
            },
            onSecondaryTap: {
                // Clear contact info and skip
                viewModel.registrationData.trustedContactName = nil
                viewModel.registrationData.trustedContactEmail = nil
                viewModel.registrationData.trustedContactPhone = nil
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.nextStep()
                }
            }
        ) {
            VStack(spacing: 28) {
                // Header
                trustedContactHeader
                
                // Add contact toggle
                addContactToggle
                
                // Contact form (if adding)
                if addContact {
                    contactForm
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Info section
                trustedContactInfo
            }
        }
        .onAppear {
            // Check if there's already contact info
            if viewModel.registrationData.trustedContactName != nil {
                addContact = true
            }
        }
    }
    
    // MARK: - Header
    
    private var trustedContactHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryPurple)
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Trusted Contact")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Optional")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.backgroundTertiary)
                        .cornerRadius(4)
                }
                
                Text("Add someone we can contact in case\nwe can't reach you about your account")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Add Contact Toggle
    
    private var addContactToggle: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                addContact.toggle()
                if !addContact {
                    // Clear contact info when toggling off
                    viewModel.registrationData.trustedContactName = nil
                    viewModel.registrationData.trustedContactEmail = nil
                    viewModel.registrationData.trustedContactPhone = nil
                }
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(addContact ? Color.primaryPurple : Color.borderPrimary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if addContact {
                        Circle()
                            .fill(Color.primaryPurple)
                            .frame(width: 14, height: 14)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(addContact ? "I want to add a trusted contact" : "I'll add a contact later")
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                    
                    Text("You can always add or update this later")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.backgroundCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(addContact ? Color.primaryPurple : Color.borderPrimary, lineWidth: addContact ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Contact Form
    
    private var contactForm: some View {
        VStack(spacing: 16) {
            // Contact Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Contact's Full Name")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                    
                    TextField("John Doe", text: Binding(
                        get: { viewModel.registrationData.trustedContactName ?? "" },
                        set: { viewModel.registrationData.trustedContactName = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.inputText)
                    .foregroundColor(.textPrimary)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .name ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .name ? 2 : 1)
                )
            }
            
            // Contact Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Contact's Email")
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                    
                    TextField("contact@example.com", text: Binding(
                        get: { viewModel.registrationData.trustedContactEmail ?? "" },
                        set: { viewModel.registrationData.trustedContactEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.inputText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .phone }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .email ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .email ? 2 : 1)
                )
            }
            
            // Contact Phone (Optional)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Contact's Phone")
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    Text("(Optional)")
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                    
                    TextField("(555) 123-4567", text: Binding(
                        get: { viewModel.registrationData.trustedContactPhone ?? "" },
                        set: { viewModel.registrationData.trustedContactPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.inputText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focusedField, equals: .phone)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .phone ? Color.primaryPurple : Color.borderPrimary, lineWidth: focusedField == .phone ? 2 : 1)
                )
            }
        }
    }
    
    // MARK: - Info Section
    
    private var trustedContactInfo: some View {
        VStack(spacing: 12) {
            InfoCard(
                icon: "shield.checkered",
                iconColor: .successGreen,
                title: "Limited Access Only",
                text: "Your trusted contact cannot access your account, make trades, or withdraw funds."
            )
            
            InfoCard(
                icon: "bell.fill",
                iconColor: .primaryBlue,
                title: "When We'd Reach Out",
                text: "We may contact them if we suspect you're a victim of fraud or can't reach you about important account matters."
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var isContactValid: Bool {
        guard addContact else { return true }
        
        let hasName = !(viewModel.registrationData.trustedContactName?.isEmpty ?? true)
        let hasEmail = !(viewModel.registrationData.trustedContactEmail?.isEmpty ?? true)
        
        if hasEmail {
            let email = viewModel.registrationData.trustedContactEmail ?? ""
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            let isValidEmail = emailPredicate.evaluate(with: email)
            return hasName && isValidEmail
        }
        
        return hasName && hasEmail
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.calloutMedium)
                    .foregroundColor(.textPrimary)
                
                Text(text)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    Step8_TrustedContactView(viewModel: RegistrationViewModel())
}

