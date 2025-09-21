//
//  LoadingView.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 9/21/25.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    @State private var isAnimating = false

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.primaryPurple.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.primaryPurple, .primaryPurpleDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }

            Text(message)
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

struct PullToRefreshView: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            Spacer()

            if isRefreshing {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryPurple))
                        .scaleEffect(0.8)

                    Text("Refreshing...")
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .background(Color.backgroundPrimary)
    }
}

struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(70))
                    .offset(x: isAnimating ? 200 : -200)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonCard: View {
    var body: some View {
        ForsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonView()
                            .frame(width: 120, height: 16)
                            .cornerRadius(4)

                        SkeletonView()
                            .frame(width: 80, height: 20)
                            .cornerRadius(4)
                    }

                    Spacer()

                    SkeletonView()
                        .frame(width: 24, height: 24)
                        .cornerRadius(12)
                }

                SkeletonView()
                    .frame(width: 60, height: 14)
                    .cornerRadius(4)
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.textMuted)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            if let actionTitle = actionTitle, let action = action {
                ForsaButton(actionTitle, style: .primary, action: action)
                    .padding(.horizontal, 40)
            }
        }
        .padding(40)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        LoadingView("Loading portfolio...")

        SkeletonCard()

        EmptyStateView(
            icon: "chart.pie",
            title: "No Investment Pies",
            message: "Create your first investment pie to start building a diversified portfolio.",
            actionTitle: "Create Pie"
        ) {
            print("Create pie tapped")
        }
    }
    .padding()
}