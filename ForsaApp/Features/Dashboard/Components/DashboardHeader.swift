//
//  DashboardHeader.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

struct DashboardHeader: View {
    let userName: String?
    let userInitials: String?
    
    var body: some View {
        HStack {
            ForsaLogo(size: .small, style: .iconOnly)
                .accessibilityHidden(true)
            
            greetingSection
            
            Spacer()
            
            if let initials = userInitials {
                avatarView(initials: initials)
            }
        }
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(TimeBasedGreeting.current) \(userName ?? "Investor")")
    }
    
    // MARK: - Greeting Section
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(TimeBasedGreeting.current)
                .font(.callout)
                .foregroundColor(.textSecondary)
            
            Text(userName ?? "Investor")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
        }
    }
    
    // MARK: - Avatar
    
    private func avatarView(initials: String) -> some View {
        Circle()
            .fill(Color.gradientPrimary)
            .frame(width: DashboardConstants.avatarSize, 
                   height: DashboardConstants.avatarSize)
            .overlay(
                Text(initials)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        DashboardHeader(
            userName: "Yousef",
            userInitials: "YZ"
        )
        .padding()
        
        DashboardHeader(
            userName: nil,
            userInitials: nil
        )
        .padding()
    }
}

