//
//  AlpacaModels.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation

// MARK: - Broker API Models

struct AlpacaAccount: Codable, Identifiable {
    let id: String
    let accountNumber: String?
    let status: String?
    let currency: String?
    let lastEquity: String?
    let equity: String?           // Current equity value
    let cash: String?
    let buyingPower: String?
    let portfolioValue: String?   // Portfolio value
    let longMarketValue: String?  // Total market value of long positions
    let shortMarketValue: String? // Total market value of short positions
    let createdAt: String?
    // Contact and identity info (returned when listing accounts)
    let contact: AlpacaContact?
    let identity: AlpacaIdentity?
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountNumber = "account_number"
        case status
        case currency
        case lastEquity = "last_equity"
        case equity
        case cash
        case buyingPower = "buying_power"
        case portfolioValue = "portfolio_value"
        case longMarketValue = "long_market_value"
        case shortMarketValue = "short_market_value"
        case createdAt = "created_at"
        case contact
        case identity
    }
    
    // Helpers to convert string values to Double
    // Use equity first, then lastEquity, then calculate from positions
    var equityValue: Double {
        if let eq = equity, let val = Double(eq), val > 0 { return val }
        if let lastEq = lastEquity, let val = Double(lastEq), val > 0 { return val }
        if let pv = portfolioValue, let val = Double(pv), val > 0 { return val }
        // Fallback: calculate from long positions + cash
        let longVal = Double(longMarketValue ?? "0") ?? 0.0
        let cashVal = Double(cash ?? "0") ?? 0.0
        return longVal + cashVal
    }
    var cashValue: Double { Double(cash ?? "0") ?? 0.0 }
    var buyingPowerValue: Double { Double(buyingPower ?? "0") ?? 0.0 }
    var longMarketValueValue: Double { Double(longMarketValue ?? "0") ?? 0.0 }
}

struct AlpacaPosition: Codable, Identifiable {
    var id: String { symbol } // Use symbol as ID since API doesn't provide unique position ID
    let symbol: String
    let qty: String
    let marketValue: String?
    let costBasis: String
    let avgEntryPrice: String
    let currentPrice: String?
    let changeToday: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case qty
        case marketValue = "market_value"
        case costBasis = "cost_basis"
        case avgEntryPrice = "avg_entry_price"
        case currentPrice = "current_price"
        case changeToday = "change_today"
    }
    
    var qtyValue: Double { Double(qty) ?? 0.0 }
    var marketValueValue: Double { Double(marketValue ?? "0") ?? 0.0 }
    var avgEntryPriceValue: Double { Double(avgEntryPrice) ?? 0.0 }
    var currentPriceValue: Double { Double(currentPrice ?? "0") ?? 0.0 }
}

struct AlpacaOrder: Codable, Identifiable {
    let id: String
    let clientOrderId: String?
    let symbol: String
    let qty: String?
    let notional: String?
    let side: String
    let type: String
    let timeInForce: String
    let status: String
    let filledQty: String
    let filledAvgPrice: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case symbol
        case qty
        case notional
        case side
        case type
        case timeInForce = "time_in_force"
        case status
        case filledQty = "filled_qty"
        case filledAvgPrice = "filled_avg_price"
        case createdAt = "created_at"
    }
}

// MARK: - Market Data Models

struct AlpacaBar: Codable {
    let t: String // Timestamp
    let o: Double // Open
    let h: Double // High
    let l: Double // Low
    let c: Double // Close
    let v: Int    // Volume
}

struct AlpacaBarsResponse: Codable {
    let bars: [String: [AlpacaBar]]?
    // In V2, it might be structured differently
}

struct AlpacaTrade: Codable {
    let t: String
    let p: Double
    let s: Int
}

struct AlpacaLatestQuote: Codable {
    let symbol: String
    let quote: AlpacaQuoteData
}

struct AlpacaQuoteData: Codable {
    let t: String // Timestamp
    let ap: Double // Ask Price
    let as_size: Int // Ask Size
    let bp: Double // Bid Price
    let bs_size: Int // Bid Size
    
    enum CodingKeys: String, CodingKey {
        case t
        case ap
        case as_size = "as"
        case bp
        case bs_size = "bs"
    }
}

// Simplified creation request for Sandbox
struct AlpacaContact: Codable {
    let email_address: String
    let phone_number: String
    let street_address: [String]
    let city: String
    let state: String?
    let postal_code: String?
    let country: String?
}

struct AlpacaIdentity: Codable {
    let given_name: String
    let family_name: String
    let date_of_birth: String // YYYY-MM-DD
    let tax_id: String?
    let tax_id_type: String?
    let country_of_citizenship: String?
    let country_of_birth: String?
    let country_of_tax_residence: String?
    let funding_source: [String]?
    
    // Employment & Financial fields
    let annual_income_min: Int?
    let annual_income_max: Int?
    let liquid_net_worth_min: Int?
    let liquid_net_worth_max: Int?
    let total_net_worth_min: Int?
    let total_net_worth_max: Int?
    let employment_status: String?
    let employer_name: String?
    let occupation: String?
    let investment_experience: String?
    
    init(
        given_name: String,
        family_name: String,
        date_of_birth: String,
        tax_id: String? = nil,
        tax_id_type: String? = nil,
        country_of_citizenship: String? = nil,
        country_of_birth: String? = nil,
        country_of_tax_residence: String? = nil,
        funding_source: [String]? = nil,
        annual_income_min: Int? = nil,
        annual_income_max: Int? = nil,
        liquid_net_worth_min: Int? = nil,
        liquid_net_worth_max: Int? = nil,
        total_net_worth_min: Int? = nil,
        total_net_worth_max: Int? = nil,
        employment_status: String? = nil,
        employer_name: String? = nil,
        occupation: String? = nil,
        investment_experience: String? = nil
    ) {
        self.given_name = given_name
        self.family_name = family_name
        self.date_of_birth = date_of_birth
        self.tax_id = tax_id
        self.tax_id_type = tax_id_type
        self.country_of_citizenship = country_of_citizenship
        self.country_of_birth = country_of_birth
        self.country_of_tax_residence = country_of_tax_residence
        self.funding_source = funding_source
        self.annual_income_min = annual_income_min
        self.annual_income_max = annual_income_max
        self.liquid_net_worth_min = liquid_net_worth_min
        self.liquid_net_worth_max = liquid_net_worth_max
        self.total_net_worth_min = total_net_worth_min
        self.total_net_worth_max = total_net_worth_max
        self.employment_status = employment_status
        self.employer_name = employer_name
        self.occupation = occupation
        self.investment_experience = investment_experience
    }
}

struct AlpacaCreateAccountRequest: Codable {
    let contact: AlpacaContact
    let identity: AlpacaIdentity
    let disclosures: AlpacaDisclosures
    let agreements: [AlpacaAgreement]
    let trusted_contact: AlpacaTrustedContact?
    
    init(contact: AlpacaContact, identity: AlpacaIdentity, disclosures: AlpacaDisclosures, agreements: [AlpacaAgreement], trusted_contact: AlpacaTrustedContact? = nil) {
        self.contact = contact
        self.identity = identity
        self.disclosures = disclosures
        self.agreements = agreements
        self.trusted_contact = trusted_contact
    }
}

// MARK: - Trusted Contact

struct AlpacaTrustedContact: Codable {
    let given_name: String
    let family_name: String
    let email_address: String?
    let phone_number: String?
    let street_address: [String]?
    let city: String?
    let state: String?
    let postal_code: String?
    let country: String?
    
    init(given_name: String, family_name: String, email_address: String? = nil, phone_number: String? = nil, street_address: [String]? = nil, city: String? = nil, state: String? = nil, postal_code: String? = nil, country: String? = nil) {
        self.given_name = given_name
        self.family_name = family_name
        self.email_address = email_address
        self.phone_number = phone_number
        self.street_address = street_address
        self.city = city
        self.state = state
        self.postal_code = postal_code
        self.country = country
    }
}

struct AlpacaDisclosures: Codable {
    let is_control_person: Bool
    let is_affiliated_exchange_or_finra: Bool
    let is_politically_exposed: Bool
    let immediate_family_exposed: Bool
    
    // Optional context fields for affirmative disclosures
    let control_person_context: String?
    let affiliated_context: String?
    let politically_exposed_context: String?
    
    init(
        is_control_person: Bool,
        is_affiliated_exchange_or_finra: Bool,
        is_politically_exposed: Bool,
        immediate_family_exposed: Bool,
        control_person_context: String? = nil,
        affiliated_context: String? = nil,
        politically_exposed_context: String? = nil
    ) {
        self.is_control_person = is_control_person
        self.is_affiliated_exchange_or_finra = is_affiliated_exchange_or_finra
        self.is_politically_exposed = is_politically_exposed
        self.immediate_family_exposed = immediate_family_exposed
        self.control_person_context = control_person_context
        self.affiliated_context = affiliated_context
        self.politically_exposed_context = politically_exposed_context
    }
}

struct AlpacaAgreement: Codable {
    let agreement: String
    let signed_at: String
    let ip_address: String
}

// MARK: - Asset Models

struct AlpacaAsset: Codable {
    let id: String
    let assetClass: String
    let exchange: String
    let symbol: String
    let name: String
    let status: String
    let tradable: Bool
    let marginable: Bool
    let shortable: Bool
    let fractionable: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case assetClass = "class"
        case exchange
        case symbol
        case name
        case status
        case tradable
        case marginable
        case shortable
        case fractionable
    }
}

// MARK: - Order Result Models

struct OrderResult: Identifiable {
    let id = UUID()
    let symbol: String
    let requestedAmount: Double
    let status: OrderResultStatus
    let message: String?
    let orderId: String?
}

enum OrderResultStatus {
    case success
    case failed
    case skipped
}

struct PortfolioInvestmentResult {
    let totalInvested: Double
    let orderResults: [OrderResult]
    let successCount: Int
    let failedCount: Int
    
    var isFullySuccessful: Bool {
        failedCount == 0
    }
}

// MARK: - Document Upload Models

/// Document upload request for KYC verification
struct AlpacaDocumentUploadRequest: Codable {
    let document_type: String
    let document_sub_type: String?
    let content: String  // Base64 encoded
    let mime_type: String
    
    enum DocumentType: String {
        case identityVerification = "identity_verification"
        case addressVerification = "address_verification"
        case taxDocument = "tax_document"
        case accountStatement = "account_statement"
        case other = "other"
    }
    
    enum DocumentSubType: String {
        case passport = "passport"
        case driversLicense = "drivers_license"
        case nationalId = "national_id"
        case stateId = "state_id"
        case utilityBill = "utility_bill"
        case bankStatement = "bank_statement"
        case w9 = "w9"
        case w8ben = "w8ben"
    }
}

/// Document upload response from Alpaca
struct AlpacaDocumentResponse: Codable, Identifiable {
    let id: String
    let document_type: String
    let document_sub_type: String?
    let created_at: String
    
    var createdDate: Date? {
        ISO8601DateFormatter().date(from: created_at)
    }
}

// MARK: - Account Activity for Document Status

struct AlpacaAccountActivity: Codable, Identifiable {
    let id: String
    let account_id: String
    let activity_type: String
    let transaction_time: String?
    let date: String?
    let status: String?
    
    enum ActivityType: String {
        case fill = "FILL"
        case transaction = "TRANS"
        case dividend = "DIV"
        case split = "SPLIT"
        case accountTransfer = "ACATC"
    }
}

// MARK: - KYC/CIP Verification Status

struct AlpacaCIPVerification: Codable {
    let status: String
    let approved_at: String?
    let rejection_reason: String?
    
    enum Status: String {
        case pending = "pending"
        case inProgress = "in_progress"
        case approved = "approved"
        case rejected = "rejected"
        case actionRequired = "action_required"
    }
    
    var statusEnum: Status? {
        Status(rawValue: status)
    }
    
    var isApproved: Bool {
        status == Status.approved.rawValue
    }
}

// MARK: - Account Status

struct AlpacaAccountStatus: Codable {
    let id: String
    let account_number: String?
    let status: String
    let crypto_status: String?
    let kyc_results: AlpacaKYCResults?
    let trading_configurations: AlpacaTradingConfig?
    
    enum AccountStatusType: String {
        case onboarding = "ONBOARDING"
        case submissionFailed = "SUBMISSION_FAILED"
        case submitted = "SUBMITTED"
        case accountUpdated = "ACCOUNT_UPDATED"
        case approvalPending = "APPROVAL_PENDING"
        case actionRequired = "ACTION_REQUIRED"
        case approved = "APPROVED"
        case rejected = "REJECTED"
        case active = "ACTIVE"
        case accountClosed = "ACCOUNT_CLOSED"
    }
    
    var statusType: AccountStatusType? {
        AccountStatusType(rawValue: status)
    }
    
    var isActive: Bool {
        status == AccountStatusType.active.rawValue || status == AccountStatusType.approved.rawValue
    }
    
    var isPending: Bool {
        [AccountStatusType.onboarding.rawValue,
         AccountStatusType.submitted.rawValue,
         AccountStatusType.approvalPending.rawValue].contains(status)
    }
    
    var requiresAction: Bool {
        status == AccountStatusType.actionRequired.rawValue ||
        status == AccountStatusType.submissionFailed.rawValue
    }
}

struct AlpacaKYCResults: Codable {
    let reject: AlpacaKYCReject?
    let accept: AlpacaKYCAccept?
    let indeterminate: AlpacaKYCIndeterminate?
    let additional_information: String?
    let summary: String?
}

struct AlpacaKYCReject: Codable {
    let ofac: Bool?
    let pep: Bool?
    let identity: Bool?
    let tax_id: Bool?
    let address: Bool?
    let date_of_birth: Bool?
    let watchlist: Bool?
}

struct AlpacaKYCAccept: Codable {
    let ofac: Bool?
    let pep: Bool?
    let identity: Bool?
    let tax_id: Bool?
    let address: Bool?
    let date_of_birth: Bool?
    let watchlist: Bool?
}

struct AlpacaKYCIndeterminate: Codable {
    let ofac: Bool?
    let pep: Bool?
    let identity: Bool?
    let tax_id: Bool?
    let address: Bool?
    let date_of_birth: Bool?
    let watchlist: Bool?
}

struct AlpacaTradingConfig: Codable {
    let dtbp_check: String?
    let fractional_trading: Bool?
    let max_margin_multiplier: String?
    let no_shorting: Bool?
    let pdt_check: String?
    let suspend_trade: Bool?
    let trade_confirm_email: String?
}

// MARK: - Account Creation Result

/// Comprehensive result from account creation including status and any required actions
struct AlpacaAccountCreationResult {
    let accountId: String
    let status: AccountCreationStatus
    let account: AlpacaAccount?
    let requiredActions: [RequiredAction]
    let rejectionReasons: [String]?
    let message: String?
    
    /// Current status of the account creation process
    enum AccountCreationStatus {
        case submitted           // Account submitted, pending verification
        case actionRequired      // Additional documents or info needed
        case approved           // Account approved, ready for trading
        case rejected           // Account rejected
        case pendingReview      // Under manual review
        
        var displayTitle: String {
            switch self {
            case .submitted: return "Verification in Progress"
            case .actionRequired: return "Action Required"
            case .approved: return "Account Approved"
            case .rejected: return "Application Rejected"
            case .pendingReview: return "Under Review"
            }
        }
        
        var displayMessage: String {
            switch self {
            case .submitted:
                return "Your account is being verified. This typically takes 1-3 business days."
            case .actionRequired:
                return "We need additional information to complete your verification."
            case .approved:
                return "Congratulations! Your account is approved and ready for trading."
            case .rejected:
                return "Unfortunately, we were unable to approve your application."
            case .pendingReview:
                return "Your application is under manual review. We'll notify you when it's complete."
            }
        }
        
        var icon: String {
            switch self {
            case .submitted: return "clock.fill"
            case .actionRequired: return "exclamationmark.triangle.fill"
            case .approved: return "checkmark.seal.fill"
            case .rejected: return "xmark.seal.fill"
            case .pendingReview: return "person.badge.clock.fill"
            }
        }
        
        var color: String {
            switch self {
            case .submitted: return "primaryPurple"
            case .actionRequired: return "warningYellow"
            case .approved: return "successGreen"
            case .rejected: return "errorRed"
            case .pendingReview: return "primaryPurple"
            }
        }
    }
    
    /// Actions required to complete account verification
    struct RequiredAction: Identifiable {
        let id = UUID()
        let type: ActionType
        let description: String
        let documentType: String?
        
        enum ActionType: String {
            case uploadId = "upload_id"
            case uploadProofOfAddress = "upload_proof_of_address"
            case additionalInfo = "additional_info"
            case verifyIdentity = "verify_identity"
            case taxDocumentation = "tax_documentation"
            
            var displayName: String {
                switch self {
                case .uploadId: return "Upload Photo ID"
                case .uploadProofOfAddress: return "Proof of Address"
                case .additionalInfo: return "Additional Information"
                case .verifyIdentity: return "Verify Identity"
                case .taxDocumentation: return "Tax Documentation"
                }
            }
            
            var icon: String {
                switch self {
                case .uploadId: return "person.text.rectangle"
                case .uploadProofOfAddress: return "doc.text"
                case .additionalInfo: return "info.circle"
                case .verifyIdentity: return "person.badge.shield.checkmark"
                case .taxDocumentation: return "doc.richtext"
                }
            }
        }
    }
    
    /// Parse from Alpaca account status response
    static func from(account: AlpacaAccount, statusResponse: AlpacaAccountStatus?) -> AlpacaAccountCreationResult {
        let status: AccountCreationStatus
        var requiredActions: [RequiredAction] = []
        var rejectionReasons: [String]? = nil
        var message: String? = nil
        
        let accountStatus = account.status ?? statusResponse?.status ?? ""
        
        switch accountStatus.uppercased() {
        case "SUBMITTED", "APPROVAL_PENDING":
            status = .submitted
        case "ACTION_REQUIRED":
            status = .actionRequired
            // Parse required actions from KYC results
            if let kycResults = statusResponse?.kyc_results {
                if let reject = kycResults.reject {
                    if reject.identity == true {
                        requiredActions.append(RequiredAction(
                            type: .uploadId,
                            description: "Please upload a valid government-issued photo ID",
                            documentType: "identity_verification"
                        ))
                    }
                    if reject.address == true {
                        requiredActions.append(RequiredAction(
                            type: .uploadProofOfAddress,
                            description: "Please upload proof of address (utility bill, bank statement)",
                            documentType: "address_verification"
                        ))
                    }
                    if reject.tax_id == true {
                        requiredActions.append(RequiredAction(
                            type: .taxDocumentation,
                            description: "Please verify your tax identification number",
                            documentType: "tax_document"
                        ))
                    }
                }
                message = kycResults.additional_information ?? kycResults.summary
            }
        case "APPROVED", "ACTIVE":
            status = .approved
        case "REJECTED":
            status = .rejected
            // Parse rejection reasons
            if let kycResults = statusResponse?.kyc_results {
                var reasons: [String] = []
                if let reject = kycResults.reject {
                    if reject.ofac == true { reasons.append("OFAC sanctions check failed") }
                    if reject.pep == true { reasons.append("Politically exposed person check failed") }
                    if reject.identity == true { reasons.append("Identity verification failed") }
                    if reject.tax_id == true { reasons.append("Tax ID verification failed") }
                    if reject.watchlist == true { reasons.append("Watchlist check failed") }
                }
                if !reasons.isEmpty { rejectionReasons = reasons }
                message = kycResults.additional_information
            }
        case "ONBOARDING":
            status = .submitted
        default:
            status = .pendingReview
        }
        
        return AlpacaAccountCreationResult(
            accountId: account.id,
            status: status,
            account: account,
            requiredActions: requiredActions,
            rejectionReasons: rejectionReasons,
            message: message
        )
    }
}

// MARK: - Enhanced Document Upload

/// Document types for Alpaca's upload API
enum AlpacaDocumentType: String {
    case identityVerification = "identity_verification"
    case addressVerification = "address_verification"
    case dateOfBirth = "date_of_birth_verification"
    case taxId = "tax_id_verification"
    case accountStatement = "account_statement"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .identityVerification: return "Identity Verification"
        case .addressVerification: return "Address Verification"
        case .dateOfBirth: return "Date of Birth Verification"
        case .taxId: return "Tax ID Verification"
        case .accountStatement: return "Account Statement"
        case .other: return "Other Document"
        }
    }
}

/// Document sub-types for identity verification
enum AlpacaDocumentSubType: String {
    case passport = "passport"
    case driversLicense = "drivers_license"
    case nationalId = "national_id"
    case stateId = "state_id"
    case utilityBill = "utility_bill"
    case bankStatement = "bank_statement"
    case w9 = "w9"
    case w8ben = "w8ben"
    
    var displayName: String {
        switch self {
        case .passport: return "Passport"
        case .driversLicense: return "Driver's License"
        case .nationalId: return "National ID"
        case .stateId: return "State ID"
        case .utilityBill: return "Utility Bill"
        case .bankStatement: return "Bank Statement"
        case .w9: return "W-9 Form"
        case .w8ben: return "W-8BEN Form"
        }
    }
    
    var requiresBothSides: Bool {
        switch self {
        case .driversLicense, .nationalId, .stateId:
            return true
        default:
            return false
        }
    }
}

/// Image compression settings for document upload
struct DocumentImageSettings {
    /// Maximum file size in bytes (5MB default for Alpaca)
    static let maxFileSize: Int = 5 * 1024 * 1024
    
    /// Compression quality (0.0 to 1.0)
    static let compressionQuality: CGFloat = 0.8
    
    /// Maximum dimension for images
    static let maxDimension: CGFloat = 2048
    
    /// Supported MIME types
    static let supportedMimeTypes = ["image/jpeg", "image/png", "image/gif", "application/pdf"]
}

/// Extended document response with status tracking
struct AlpacaDocumentUploadResult {
    let documentId: String
    let uploadedAt: Date
    let status: DocumentStatus
    let errorMessage: String?
    
    enum DocumentStatus {
        case uploaded
        case processing
        case verified
        case rejected(reason: String)
        case failed(error: String)
        
        var displayName: String {
            switch self {
            case .uploaded: return "Uploaded"
            case .processing: return "Processing"
            case .verified: return "Verified"
            case .rejected(let reason): return "Rejected: \(reason)"
            case .failed(let error): return "Failed: \(error)"
            }
        }
        
        var isSuccess: Bool {
            switch self {
            case .uploaded, .processing, .verified:
                return true
            default:
                return false
            }
        }
    }
}

