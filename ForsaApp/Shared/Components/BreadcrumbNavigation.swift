//
//  BreadcrumbNavigation.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/24/25.
//

import SwiftUI

struct BreadcrumbNavigation: View {
    let steps: [BreadcrumbStep]
    let currentStep: Int
    let onStepTapped: ((Int) -> Void)?

    init(steps: [BreadcrumbStep], currentStep: Int, onStepTapped: ((Int) -> Void)? = nil) {
        self.steps = steps
        self.currentStep = currentStep
        self.onStepTapped = onStepTapped
    }

    var body: some View {
        VStack(spacing: 12) {
            // Step indicators
            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    let stepNumber = index + 1
                    let isActive = stepNumber == currentStep
                    let isCompleted = stepNumber < currentStep
                    let isClickable = onStepTapped != nil && stepNumber <= currentStep

                    Button(action: {
                        if isClickable {
                            onStepTapped?(stepNumber)
                        }
                    }) {
                        Circle()
                            .fill(circleColor(for: stepNumber))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Group {
                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.caption1)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(stepNumber)")
                                            .font(.caption1)
                                            .fontWeight(.semibold)
                                            .foregroundColor(textColor(for: stepNumber))
                                    }
                                }
                            )
                    }
                    .disabled(!isClickable)
                    .buttonStyle(PlainButtonStyle())

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(connectorColor(for: stepNumber))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Step labels
            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    let stepNumber = index + 1
                    let isActive = stepNumber == currentStep

                    VStack(spacing: 4) {
                        Text(step.title)
                            .font(.caption1)
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundColor(isActive ? .textPrimary : .textSecondary)
                            .multilineTextAlignment(.center)

                        if let subtitle = step.subtitle, isActive {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundColor(.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.backgroundCard)
    }

    private func circleColor(for stepNumber: Int) -> Color {
        if stepNumber < currentStep {
            return .primaryPurple
        } else if stepNumber == currentStep {
            return .primaryPurple
        } else {
            return .borderPrimary
        }
    }

    private func textColor(for stepNumber: Int) -> Color {
        if stepNumber <= currentStep {
            return .white
        } else {
            return .textMuted
        }
    }

    private func connectorColor(for stepNumber: Int) -> Color {
        if stepNumber < currentStep {
            return .primaryPurple
        } else {
            return .borderPrimary
        }
    }
}

struct BreadcrumbStep {
    let title: String
    let subtitle: String?
    let isRequired: Bool

    init(title: String, subtitle: String? = nil, isRequired: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
    }
}

// MARK: - Investment Flow Steps
extension BreadcrumbStep {
    static let investmentFlowSteps: [BreadcrumbStep] = [
        BreadcrumbStep(title: "Select Pie", subtitle: "Choose your investment"),
        BreadcrumbStep(title: "Investment Method", subtitle: "Manual or AutoInvest"),
        BreadcrumbStep(title: "Configure", subtitle: "Set amounts"),
        BreadcrumbStep(title: "Value Projections", subtitle: "Review projections"),
        BreadcrumbStep(title: "Name Pie", subtitle: "Name & goals"),
        BreadcrumbStep(title: "Confirm", subtitle: "Finalize investment")
    ]
}

// MARK: - Compact Breadcrumb for Modal Headers
struct CompactBreadcrumb: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitle: String

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.borderPrimary)
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Color.primaryPurple)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            // Step info
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text(stepTitle)
                    .font(.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    private var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        BreadcrumbNavigation(
            steps: BreadcrumbStep.investmentFlowSteps,
            currentStep: 3,
            onStepTapped: { step in
                print("Tapped step \(step)")
            }
        )

        CompactBreadcrumb(
            currentStep: 3,
            totalSteps: 6,
            stepTitle: "Configure Investment"
        )
        .padding()
    }
    .background(Color.backgroundPrimary)
}