//
//  ProgressIndicator.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// Horizontal step progress indicator for multi-step registration flow
struct StepProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    let completedSteps: Set<Int>
    var showLabels: Bool = false
    var stepLabels: [String] = []
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress dots/steps
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    // Step circle
                    stepCircle(for: step)
                    
                    // Connector line (except for last step)
                    if step < totalSteps - 1 {
                        connectorLine(after: step)
                    }
                }
            }
            
            // Labels (if enabled)
            if showLabels && !stepLabels.isEmpty {
                HStack(spacing: 0) {
                    ForEach(0..<min(totalSteps, stepLabels.count), id: \.self) { index in
                        Text(stepLabels[index])
                            .font(.caption2)
                            .foregroundColor(index == currentStep ? .primaryPurple : .textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // MARK: - Step Circle
    
    private func stepCircle(for step: Int) -> some View {
        let isCompleted = completedSteps.contains(step)
        let isCurrent = step == currentStep
        let isPending = step > currentStep && !isCompleted
        
        return ZStack {
            Circle()
                .fill(circleBackgroundColor(isCompleted: isCompleted, isCurrent: isCurrent))
                .frame(width: 28, height: 28)
            
            Circle()
                .stroke(circleBorderColor(isCompleted: isCompleted, isCurrent: isCurrent), lineWidth: 2)
                .frame(width: 28, height: 28)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else if isCurrent {
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
            } else {
                Text("\(step + 1)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    private func circleBackgroundColor(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted {
            return .primaryPurple
        } else if isCurrent {
            return .primaryPurple
        }
        return .clear
    }
    
    private func circleBorderColor(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted || isCurrent {
            return .primaryPurple
        }
        return .borderPrimary
    }
    
    // MARK: - Connector Line
    
    private func connectorLine(after step: Int) -> some View {
        let isCompleted = completedSteps.contains(step + 1) || step < currentStep
        
        return Rectangle()
            .fill(isCompleted ? Color.primaryPurple : Color.borderPrimary)
            .frame(height: 2)
    }
}

// MARK: - Vertical Step Progress

struct VerticalStepProgress: View {
    let steps: [StepInfo]
    let currentStepIndex: Int
    
    struct StepInfo: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String?
        let icon: String
        let status: StepStatus
        
        enum StepStatus {
            case pending
            case current
            case completed
            case error
            
            var color: Color {
                switch self {
                case .pending: return .textTertiary
                case .current: return .primaryPurple
                case .completed: return .successGreen
                case .error: return .errorRed
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 16) {
                    // Step indicator column
                    VStack(spacing: 0) {
                        // Step circle
                        stepIndicatorCircle(for: step, at: index)
                        
                        // Connector line
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStepIndex ? Color.primaryPurple : Color.borderPrimary)
                                .frame(width: 2, height: 40)
                        }
                    }
                    
                    // Step content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.bodyMedium)
                            .foregroundColor(step.status == .pending ? .textTertiary : .textPrimary)
                        
                        if let subtitle = step.subtitle {
                            Text(subtitle)
                                .font(.caption1)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .padding(.bottom, index < steps.count - 1 ? 24 : 0)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func stepIndicatorCircle(for step: StepInfo, at index: Int) -> some View {
        ZStack {
            Circle()
                .fill(step.status == .completed || step.status == .current ? step.status.color : Color.clear)
                .frame(width: 32, height: 32)
            
            Circle()
                .stroke(step.status == .pending ? Color.borderPrimary : step.status.color, lineWidth: 2)
                .frame(width: 32, height: 32)
            
            if step.status == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else if step.status == .current {
                Image(systemName: step.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            } else if step.status == .error {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(index + 1)")
                    .font(.caption1Medium)
                    .foregroundColor(.textTertiary)
            }
        }
    }
}

// MARK: - Circular Progress Ring

struct CircularProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80
    var backgroundColor: Color = .backgroundTertiary
    var foregroundColor: Color = .primaryPurple
    var showPercentage: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Segmented Progress Bar

struct SegmentedProgressBar: View {
    let segments: Int
    let filledSegments: Int
    var spacing: CGFloat = 4
    var height: CGFloat = 4
    var backgroundColor: Color = .backgroundTertiary
    var foregroundColor: Color = .primaryPurple
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<segments, id: \.self) { index in
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(index < filledSegments ? foregroundColor : backgroundColor)
                    .frame(height: height)
            }
        }
    }
}

// MARK: - Previews

#Preview("Step Progress") {
    VStack(spacing: 40) {
        StepProgressIndicator(
            totalSteps: 8,
            currentStep: 3,
            completedSteps: [0, 1, 2]
        )
        .padding()
        
        StepProgressIndicator(
            totalSteps: 5,
            currentStep: 2,
            completedSteps: [0, 1],
            showLabels: true,
            stepLabels: ["Account", "Personal", "Address", "Financial", "Review"]
        )
        .padding()
    }
}

#Preview("Vertical Progress") {
    VerticalStepProgress(
        steps: [
            .init(title: "Create Account", subtitle: "Email and password", icon: "person.crop.circle", status: .completed),
            .init(title: "Verify Phone", subtitle: "SMS verification", icon: "phone.fill", status: .completed),
            .init(title: "Personal Info", subtitle: "Date of birth, citizenship", icon: "person.text.rectangle", status: .current),
            .init(title: "Address", subtitle: "Home address", icon: "location", status: .pending),
            .init(title: "Financial", subtitle: "Tax and income", icon: "dollarsign.circle", status: .pending)
        ],
        currentStepIndex: 2
    )
    .padding()
}

#Preview("Circular Progress") {
    HStack(spacing: 20) {
        CircularProgressRing(progress: 0.25, size: 60)
        CircularProgressRing(progress: 0.5, size: 80)
        CircularProgressRing(progress: 0.75, size: 100)
    }
}

#Preview("Segmented Bar") {
    VStack(spacing: 20) {
        SegmentedProgressBar(segments: 5, filledSegments: 2)
        SegmentedProgressBar(segments: 8, filledSegments: 5, height: 6, foregroundColor: .successGreen)
    }
    .padding()
}

