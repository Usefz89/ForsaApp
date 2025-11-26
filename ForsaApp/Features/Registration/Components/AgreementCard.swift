//
//  AgreementCard.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Expandable agreement card component
struct AgreementCard: View {
    let title: String
    let summary: String?
    let fullText: String
    @Binding var isAccepted: Bool
    var isRequired: Bool = true
    var onViewFull: (() -> Void)?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 12) {
                    // Checkbox
                    agreementCheckbox
                    
                    // Title and summary
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(.bodyMedium)
                                .foregroundColor(.textPrimary)
                            
                            if isRequired {
                                Text("Required")
                                    .font(.caption2)
                                    .foregroundColor(.errorRed)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.errorRed.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        
                        if let summary = summary, !isExpanded {
                            Text(summary)
                                .font(.caption1)
                                .foregroundColor(.textTertiary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Agreement text preview
                    Text(fullText.prefix(500) + (fullText.count > 500 ? "..." : ""))
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                        .lineLimit(10)
                    
                    // View full button
                    if let onViewFull = onViewFull {
                        Button(action: onViewFull) {
                            HStack(spacing: 4) {
                                Text("View Full Agreement")
                                    .font(.caption1Medium)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption1)
                            }
                            .foregroundColor(.primaryPurple)
                        }
                    }
                    
                    // Accept button
                    if !isAccepted {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isAccepted = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("I Accept")
                                    .font(.calloutMedium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryPurple)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.backgroundCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAccepted ? Color.successGreen.opacity(0.5) : Color.borderPrimary, lineWidth: isAccepted ? 2 : 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Checkbox
    
    private var agreementCheckbox: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                isAccepted.toggle()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isAccepted ? Color.successGreen : Color.borderPrimary, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isAccepted {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.successGreen)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Compact Agreement Row

/// Compact single-line agreement row
struct CompactAgreementRow: View {
    let title: String
    @Binding var isAccepted: Bool
    var linkText: String = "View"
    var onLinkTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
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
            
            // Label
            Text("I agree to the")
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            // Link
            Button(action: { onLinkTap?() }) {
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

// MARK: - Agreement Stack

/// Stack of multiple agreements with "Accept All" option
struct AgreementStack: View {
    let agreements: [AgreementItem]
    @Binding var acceptedAgreements: Set<String>
    var onViewAgreement: ((AgreementItem) -> Void)?
    
    struct AgreementItem: Identifiable {
        let id: String
        let title: String
        let summary: String
        let isRequired: Bool
        
        init(id: String, title: String, summary: String = "", isRequired: Bool = true) {
            self.id = id
            self.title = title
            self.summary = summary
            self.isRequired = isRequired
        }
    }
    
    private var allAccepted: Bool {
        agreements.filter { $0.isRequired }.allSatisfy { acceptedAgreements.contains($0.id) }
    }
    
    private var requiredCount: Int {
        agreements.filter { $0.isRequired }.count
    }
    
    private var acceptedRequiredCount: Int {
        agreements.filter { $0.isRequired && acceptedAgreements.contains($0.id) }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with progress
            HStack {
                Text("Agreements")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(acceptedRequiredCount)/\(requiredCount) accepted")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
            
            // Agreement rows
            VStack(spacing: 8) {
                ForEach(agreements) { agreement in
                    AgreementStackRow(
                        agreement: agreement,
                        isAccepted: acceptedAgreements.contains(agreement.id),
                        onToggle: { toggleAgreement(agreement.id) },
                        onView: { onViewAgreement?(agreement) }
                    )
                }
            }
            
            // Accept all button
            if !allAccepted {
                Button(action: acceptAll) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Accept All Required")
                            .font(.calloutMedium)
                    }
                    .foregroundColor(.primaryPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primaryPurple.opacity(0.1))
                    .cornerRadius(10)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.successGreen)
                    
                    Text("All required agreements accepted")
                        .font(.calloutMedium)
                        .foregroundColor(.successGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.successGreen.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private func toggleAgreement(_ id: String) {
        withAnimation(.spring(response: 0.2)) {
            if acceptedAgreements.contains(id) {
                acceptedAgreements.remove(id)
            } else {
                acceptedAgreements.insert(id)
            }
        }
    }
    
    private func acceptAll() {
        withAnimation(.spring(response: 0.3)) {
            for agreement in agreements where agreement.isRequired {
                acceptedAgreements.insert(agreement.id)
            }
        }
    }
}

struct AgreementStackRow: View {
    let agreement: AgreementStack.AgreementItem
    let isAccepted: Bool
    let onToggle: () -> Void
    let onView: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isAccepted ? Color.successGreen : Color.borderPrimary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isAccepted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.successGreen)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Title and status
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(agreement.title)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                    
                    if agreement.isRequired {
                        Text("*")
                            .font(.body)
                            .foregroundColor(.errorRed)
                    }
                }
                
                if !agreement.summary.isEmpty {
                    Text(agreement.summary)
                        .font(.caption1)
                        .foregroundColor(.textTertiary)
                }
            }
            
            Spacer()
            
            // View button
            Button(action: onView) {
                Text("View")
                    .font(.caption1Medium)
                    .foregroundColor(.primaryPurple)
            }
        }
        .padding(12)
        .background(isAccepted ? Color.successGreen.opacity(0.05) : Color.backgroundCard)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isAccepted ? Color.successGreen.opacity(0.3) : Color.borderPrimary, lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("Agreement Card") {
    VStack(spacing: 16) {
        AgreementCard(
            title: "Terms of Service",
            summary: "Please read and accept our terms",
            fullText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
            isAccepted: .constant(false)
        )
        
        AgreementCard(
            title: "Privacy Policy",
            summary: "How we handle your data",
            fullText: "Your privacy is important to us...",
            isAccepted: .constant(true)
        )
    }
    .padding()
}

#Preview("Compact Row") {
    VStack(spacing: 12) {
        CompactAgreementRow(title: "Terms of Service", isAccepted: .constant(false))
        CompactAgreementRow(title: "Privacy Policy", isAccepted: .constant(true))
    }
    .padding()
}

#Preview("Agreement Stack") {
    AgreementStack(
        agreements: [
            .init(id: "terms", title: "Terms of Service", summary: "Our terms and conditions"),
            .init(id: "privacy", title: "Privacy Policy", summary: "How we handle your data"),
            .init(id: "account", title: "Account Agreement", summary: "Your brokerage account terms"),
            .init(id: "customer", title: "Customer Agreement", summary: "Customer agreement details")
        ],
        acceptedAgreements: .constant(["terms"])
    )
    .padding()
}

