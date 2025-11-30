//
//  DepositComponents.swift
//  ForsaApp
//
//  Created by Yousef Zuriqi on 11/30/25.
//

import SwiftUI

// MARK: - Payment Method Selection

enum DepositPaymentMethod: String, CaseIterable, Identifiable {
    case knet = "knet"
    case creditCard = "credit_card"
    case bankWire = "bank_wire"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .knet: return WalletStrings.knetTitle
        case .creditCard: return WalletStrings.creditCardTitle
        case .bankWire: return WalletStrings.bankWireTitle
        }
    }
    
    var shortDescription: String {
        switch self {
        case .knet: return WalletStrings.knetDescription
        case .creditCard: return WalletStrings.creditCardDescription
        case .bankWire: return WalletStrings.bankWireDescription
        }
    }
    
    var icon: String {
        switch self {
        case .knet: return "building.columns.fill"
        case .creditCard: return "creditcard.fill"
        case .bankWire: return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .knet: return Color(hex: "0066B3") ?? .blue
        case .creditCard: return .primaryPurple
        case .bankWire: return .primaryGreen
        }
    }
    
    var feePercentage: Double {
        switch self {
        case .knet: return 0.0
        case .creditCard: return 2.5
        case .bankWire: return 0.0
        }
    }
    
    var flatFee: Double {
        switch self {
        case .knet: return 0.0
        case .creditCard: return 0.0
        case .bankWire: return 5.0
        }
    }
    
    var processingTime: String {
        switch self {
        case .knet: return "Instant"
        case .creditCard: return "Instant"
        case .bankWire: return "1-3 Business Days"
        }
    }
    
    var isInstant: Bool {
        self == .knet || self == .creditCard
    }
    
    func calculateFee(for amount: Double) -> Double {
        let percentageFee = amount * (feePercentage / 100)
        return percentageFee + flatFee
    }
    
    func calculateNetAmount(for amount: Double) -> Double {
        amount - calculateFee(for: amount)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Payment Method Tab Bar

struct PaymentMethodTabBar: View {
    @Binding var selectedMethod: DepositPaymentMethod
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DepositPaymentMethod.allCases) { method in
                PaymentMethodTab(
                    method: method,
                    isSelected: selectedMethod == method,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMethod = method
                    }
                }
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(WalletConstants.tabCornerRadius)
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
}

// MARK: - Individual Payment Tab

struct PaymentMethodTab: View {
    let method: DepositPaymentMethod
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: method.icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(method.title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: WalletConstants.tabHeight)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: WalletConstants.tabCornerRadius - 2)
                        .fill(method.iconColor)
                        .matchedGeometryEffect(id: "tab_bg", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(method.title) payment method")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Payment Method Header Card

struct PaymentMethodHeaderCard: View {
    let method: DepositPaymentMethod
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(method.iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: method.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(method.iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(method.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    if method == .knet {
                        PopularBadge()
                    }
                }
                
                Text(methodDescription)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status indicator
            if method.isInstant {
                InstantBadge()
            }
        }
        .padding()
        .background(Color.backgroundCard)
        .cornerRadius(WalletConstants.infoCardCornerRadius)
        .shadow(color: .shadowLight, radius: 4, y: 2)
        .padding(.horizontal, WalletConstants.horizontalPadding)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
        }
    }
    
    private var methodDescription: String {
        switch method {
        case .knet:
            return WalletStrings.knetSecurePayment
        case .creditCard:
            return WalletStrings.cardSecurePayment
        case .bankWire:
            return WalletStrings.wireTransferInstructions
        }
    }
}

// MARK: - Popular Badge

struct PopularBadge: View {
    var body: some View {
        Text(WalletStrings.popularInKuwait)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [Color(hex: "0066B3") ?? .blue, Color(hex: "004d86") ?? .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
    }
}

// MARK: - Instant Badge

struct InstantBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10))
            Text(WalletStrings.instantDeposit)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.primaryGreen)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primaryGreen.opacity(0.12))
        .cornerRadius(6)
    }
}

// MARK: - Fee Breakdown Card

struct FeeBreakdownCard: View {
    let method: DepositPaymentMethod
    let amountKWD: Double
    let exchangeRate: Double
    
    private var fee: Double {
        method.calculateFee(for: amountKWD)
    }
    
    private var netAmountKWD: Double {
        amountKWD - fee
    }
    
    private var netAmountUSD: Double {
        netAmountKWD * exchangeRate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "receipt")
                    .foregroundColor(.primaryPurple)
                Text("Fee Breakdown")
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                FeeRow(label: "Amount", value: "KWD \(String(format: "%.3f", amountKWD))")
                
                if fee > 0 {
                    FeeRow(
                        label: method.feePercentage > 0 ? "Fee (\(String(format: "%.1f", method.feePercentage))%)" : "Transfer Fee",
                        value: "- KWD \(String(format: "%.3f", fee))",
                        valueColor: .errorRed
                    )
                } else {
                    FeeRow(label: "Fee", value: "FREE", valueColor: .primaryGreen)
                }
                
                Divider()
                
                FeeRow(
                    label: "You'll Deposit",
                    value: "$\(String(format: "%.2f", netAmountUSD)) USD",
                    isTotal: true
                )
            }
        }
        .padding(WalletConstants.infoCardPadding)
        .background(Color.backgroundSecondary)
        .cornerRadius(WalletConstants.infoCardCornerRadius)
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
}

// MARK: - Fee Row

struct FeeRow: View {
    let label: String
    let value: String
    var valueColor: Color = .textPrimary
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .callout : .caption)
                .fontWeight(isTotal ? .semibold : .regular)
                .foregroundColor(isTotal ? .textPrimary : .textSecondary)
            
            Spacer()
            
            Text(value)
                .font(isTotal ? .callout : .caption)
                .fontWeight(isTotal ? .bold : .medium)
                .foregroundColor(isTotal ? .primaryPurple : valueColor)
        }
    }
}

// MARK: - KNET Logo View

struct KNETLogoView: View {
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0066B3") ?? .blue, Color(hex: "004080") ?? .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Text("K")
                .font(.system(size: size * 0.5, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Processing Overlay

struct PaymentProcessingOverlay: View {
    let message: String
    let method: DepositPaymentMethod
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(method.iconColor.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(method.iconColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                    
                    Image(systemName: method.icon)
                        .font(.system(size: 28))
                        .foregroundColor(method.iconColor)
                }
                
                VStack(spacing: 8) {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Please do not close this screen")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(40)
            .background(Color.backgroundCard)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Bank Wire Instructions Card

struct BankWireInstructionsCard: View {
    @State private var copiedField: String?
    
    private let bankDetails = [
        ("Bank Name", "Kuwait Finance House (KFH)"),
        ("Account Name", "Fursa Investment Company"),
        ("IBAN", "KW81CBKU0000000000001234560101"),
        ("SWIFT/BIC", "CBKUKWKW"),
        ("Reference", "FORSA-\(Int.random(in: 100000...999999))")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.columns")
                    .foregroundColor(.primaryGreen)
                Text("Bank Transfer Details")
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                ForEach(bankDetails, id: \.0) { detail in
                    BankDetailRow(
                        label: detail.0,
                        value: detail.1,
                        isCopied: copiedField == detail.0
                    ) {
                        UIPasteboard.general.string = detail.1
                        withAnimation {
                            copiedField = detail.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                if copiedField == detail.0 {
                                    copiedField = nil
                                }
                            }
                        }
                    }
                }
            }
            
            // Important notes
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Include your reference number in the transfer description")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.warningYellow)
                        .font(.caption)
                }
                
                Label {
                    Text("Funds typically arrive within 1-3 business days")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.infoBlue)
                        .font(.caption)
                }
            }
            .padding(.top, 8)
        }
        .padding(WalletConstants.infoCardPadding)
        .background(Color.primaryGreen.opacity(0.08))
        .cornerRadius(WalletConstants.infoCardCornerRadius)
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
}

// MARK: - Bank Detail Row

struct BankDetailRow: View {
    let label: String
    let value: String
    let isCopied: Bool
    let onCopy: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            Button(action: onCopy) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(isCopied ? .primaryGreen : .primaryPurple)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Credit Card Form

struct CreditCardInputForm: View {
    @Binding var cardNumber: String
    @Binding var expiryDate: String
    @Binding var cvv: String
    @Binding var cardholderName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Card Number
            VStack(alignment: .leading, spacing: 6) {
                Text("Card Number")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                HStack {
                    TextField("1234 5678 9012 3456", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .font(.callout)
                        .foregroundColor(.textPrimary)
                        .onChange(of: cardNumber) { _, newValue in
                            cardNumber = formatCardNumber(newValue)
                        }
                    
                    CardBrandIcon(cardNumber: cardNumber)
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(10)
            }
            
            // Expiry & CVV
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Expiry Date")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    TextField("MM/YY", text: $expiryDate)
                        .keyboardType(.numberPad)
                        .font(.callout)
                        .foregroundColor(.textPrimary)
                        .onChange(of: expiryDate) { _, newValue in
                            expiryDate = formatExpiryDate(newValue)
                        }
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("CVV")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    SecureField("123", text: $cvv)
                        .keyboardType(.numberPad)
                        .font(.callout)
                        .foregroundColor(.textPrimary)
                        .onChange(of: cvv) { _, newValue in
                            cvv = String(newValue.prefix(4))
                        }
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(10)
                }
                .frame(width: 100)
            }
            
            // Cardholder Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Cardholder Name")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                TextField("Name on card", text: $cardholderName)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .font(.callout)
                    .foregroundColor(.textPrimary)
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)
            }
        }
        .padding(WalletConstants.infoCardPadding)
        .background(Color.backgroundCard)
        .cornerRadius(WalletConstants.infoCardCornerRadius)
        .shadow(color: .shadowLight, radius: 4, y: 2)
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
    
    private func formatCardNumber(_ input: String) -> String {
        let cleaned = input.replacingOccurrences(of: " ", with: "")
        let limited = String(cleaned.prefix(16))
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        return formatted
    }
    
    private func formatExpiryDate(_ input: String) -> String {
        let cleaned = input.replacingOccurrences(of: "/", with: "")
        let limited = String(cleaned.prefix(4))
        if limited.count > 2 {
            return String(limited.prefix(2)) + "/" + String(limited.suffix(limited.count - 2))
        }
        return limited
    }
}

// MARK: - Card Brand Icon

struct CardBrandIcon: View {
    let cardNumber: String
    
    private var brand: String {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        if cleaned.hasPrefix("4") {
            return "visa"
        } else if cleaned.hasPrefix("5") || cleaned.hasPrefix("2") {
            return "mastercard"
        }
        return "creditcard"
    }
    
    var body: some View {
        Group {
            switch brand {
            case "visa":
                Text("VISA")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            case "mastercard":
                HStack(spacing: -4) {
                    Circle().fill(Color.red).frame(width: 16, height: 16)
                    Circle().fill(Color.orange).frame(width: 16, height: 16)
                }
            default:
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.textTertiary)
            }
        }
    }
}

// MARK: - Security Badge

struct SecurityBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(.primaryGreen)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("256-bit SSL Encryption")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("Your payment info is secure")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.primaryGreen)
        }
        .padding(12)
        .background(Color.primaryGreen.opacity(0.08))
        .cornerRadius(8)
        .padding(.horizontal, WalletConstants.horizontalPadding)
    }
}

