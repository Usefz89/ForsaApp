//
//  KYCModels.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import Foundation

// MARK: - KYC Registration Data

/// Comprehensive KYC data model for multi-step registration flow
/// Conforms to Alpaca Broker API requirements
struct KYCRegistrationData: Codable {
    
    // MARK: - Step 1: Basic Info (Account Credentials)
    var email: String = ""
    var password: String = ""
    var firstName: String = ""
    var lastName: String = ""
    
    // MARK: - Step 2: Personal Details
    var dateOfBirth: Date?
    var phoneNumber: String = ""
    var citizenship: String = "KWT"
    var countryOfBirth: String = "KWT"
    
    // MARK: - Step 3: Address
    var streetAddress: String = ""
    var apartmentUnit: String?
    var city: String = ""
    var state: String = ""  // Governorate for Kuwait
    var postalCode: String = ""
    var country: String = "KWT"
    
    // MARK: - Kuwait-Specific Address Fields
    var block: String = ""        // Block number
    var building: String = ""     // Building number/name
    var floor: String?            // Floor (optional)
    var area: String = ""         // Area (e.g., Salmiya, Hawalli)
    var governorate: String = ""  // Governorate
    
    // MARK: - Step 4: Tax & Financial
    var taxId: String = ""  // Civil ID for Kuwait
    var taxIdType: TaxIdType = .kuwaitCivilId  // Default to Kuwait Civil ID for Kuwait users
    var countryOfTaxResidence: String = "KWT"
    var fundingSources: [FundingSource] = []
    var annualIncome: IncomeRange?
    var netWorth: NetWorthRange?
    var liquidNetWorth: LiquidNetWorthRange?
    var employmentStatus: EmploymentStatus = .employed
    var employer: String?
    var occupation: String?
    var investmentExperience: InvestmentExperience?
    
    // MARK: - Step 5: Disclosures
    var isControlPerson: Bool = false
    var controlPersonContext: String?
    var isAffiliatedWithExchange: Bool = false
    var affiliationContext: String?
    var isPoliticallyExposed: Bool = false
    var politicalExposureContext: String?
    var immediateFamilyExposed: Bool = false
    var immediateFamilyExposedContext: String?  // Relationship type: spouse, parent, child, sibling
    
    // MARK: - Step 6: Trusted Contact (Optional)
    var trustedContactName: String?
    var trustedContactEmail: String?
    var trustedContactPhone: String?
    
    // MARK: - Agreements
    var agreedToTerms: Bool = false
    var agreedToPrivacy: Bool = false
    var agreedToAccountAgreement: Bool = false
    var agreedToCustomerAgreement: Bool = false
    var agreedToMarginAgreement: Bool = false
    
    // MARK: - Metadata
    var registrationStartedAt: Date = Date()
    var lastUpdatedAt: Date = Date()
    var currentStep: RegistrationStep = .basicInfo
    var ipAddress: String?
    
    // MARK: - CodingKeys (Excludes sensitive data from persistence)
    
    /// Explicitly exclude password and taxId from Codable encoding
    /// These should NEVER be persisted to UserDefaults
    enum CodingKeys: String, CodingKey {
        case email, firstName, lastName
        case dateOfBirth, phoneNumber, citizenship, countryOfBirth
        case streetAddress, apartmentUnit, city, state, postalCode, country
        case block, building, floor, area, governorate  // Kuwait-specific address fields
        // NOTE: taxId is intentionally EXCLUDED - stored in Keychain only
        case taxIdType, countryOfTaxResidence
        case fundingSources, annualIncome, netWorth, liquidNetWorth
        case employmentStatus, employer, occupation, investmentExperience
        case isControlPerson, controlPersonContext
        case isAffiliatedWithExchange, affiliationContext
        case isPoliticallyExposed, politicalExposureContext
        case immediateFamilyExposed, immediateFamilyExposedContext
        case trustedContactName, trustedContactEmail, trustedContactPhone
        case agreedToTerms, agreedToPrivacy, agreedToAccountAgreement
        case agreedToCustomerAgreement, agreedToMarginAgreement
        case registrationStartedAt, lastUpdatedAt, currentStep, ipAddress
        // NOTE: password is intentionally EXCLUDED - never persisted
    }
    
    // MARK: - Computed Properties
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var formattedDateOfBirth: String? {
        guard let dob = dateOfBirth else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: dob)
    }
    
    var fullStreetAddress: [String] {
        var address = [streetAddress]
        if let unit = apartmentUnit, !unit.isEmpty {
            address.append(unit)
        }
        return address
    }
    
    var hasAllRequiredAgreements: Bool {
        agreedToTerms && agreedToPrivacy && agreedToAccountAgreement && agreedToCustomerAgreement
    }
    
    var isBasicInfoComplete: Bool {
        !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !lastName.isEmpty
    }
    
    var isPersonalDetailsComplete: Bool {
        dateOfBirth != nil && !phoneNumber.isEmpty && !citizenship.isEmpty
    }
    
    var isAddressComplete: Bool {
        // For Kuwait, use Kuwait-specific address fields
        if country == "KWT" {
            return !block.isEmpty && !streetAddress.isEmpty && !building.isEmpty &&
                   !area.isEmpty && !governorate.isEmpty
        }
        // For other countries, use standard address format
        return !streetAddress.isEmpty && !city.isEmpty && !state.isEmpty && !postalCode.isEmpty && !country.isEmpty
    }
    
    var isTaxFinancialComplete: Bool {
        !taxId.isEmpty && !fundingSources.isEmpty && employmentStatus != .none
    }
    
    var isDisclosuresComplete: Bool {
        // Disclosures are always considered complete since they default to false
        // But if any are true, their context should be provided
        let controlPersonValid = !isControlPerson || (controlPersonContext != nil && !controlPersonContext!.isEmpty)
        let affiliatedValid = !isAffiliatedWithExchange || (affiliationContext != nil && !affiliationContext!.isEmpty)
        let politicalValid = !isPoliticallyExposed || (politicalExposureContext != nil && !politicalExposureContext!.isEmpty)
        // EC-3: Require family relationship context when immediate family is exposed
        let familyExposedValid = !immediateFamilyExposed || (immediateFamilyExposedContext != nil && !immediateFamilyExposedContext!.isEmpty)
        return controlPersonValid && affiliatedValid && politicalValid && familyExposedValid
    }
    
    var completionPercentage: Double {
        var completed = 0
        let total = 6 // Total number of steps
        
        if isBasicInfoComplete { completed += 1 }
        if isPersonalDetailsComplete { completed += 1 }
        if isAddressComplete { completed += 1 }
        if isTaxFinancialComplete { completed += 1 }
        if isDisclosuresComplete { completed += 1 }
        if hasAllRequiredAgreements { completed += 1 }
        
        return Double(completed) / Double(total)
    }
}

// MARK: - Registration Step

enum RegistrationStep: Int, Codable, CaseIterable {
    case basicInfo = 0
    case phoneVerification = 1  // NEW: Phone verification step
    case personalDetails = 2
    case address = 3
    case taxFinancial = 4
    case disclosures = 5
    case trustedContact = 6
    case agreements = 7
    case review = 8
    
    var title: String {
        switch self {
        case .basicInfo: return "Account"
        case .phoneVerification: return "Verify Phone"
        case .personalDetails: return "Personal"
        case .address: return "Address"
        case .taxFinancial: return "Financial"
        case .disclosures: return "Disclosures"
        case .trustedContact: return "Contact"
        case .agreements: return "Agreements"
        case .review: return "Review"
        }
    }
    
    var subtitle: String {
        switch self {
        case .basicInfo: return "Create your account"
        case .phoneVerification: return "Verify your phone number"
        case .personalDetails: return "Tell us about yourself"
        case .address: return "Where do you live?"
        case .taxFinancial: return "Tax & financial information"
        case .disclosures: return "Regulatory disclosures"
        case .trustedContact: return "Emergency contact (optional)"
        case .agreements: return "Review and accept terms"
        case .review: return "Review your information"
        }
    }
    
    var icon: String {
        switch self {
        case .basicInfo: return "person.crop.circle"
        case .phoneVerification: return "phone.badge.checkmark"
        case .personalDetails: return "person.text.rectangle"
        case .address: return "location.circle"
        case .taxFinancial: return "dollarsign.circle"
        case .disclosures: return "doc.text"
        case .trustedContact: return "person.2.circle"
        case .agreements: return "checkmark.seal"
        case .review: return "magnifyingglass.circle"
        }
    }
    
    var next: RegistrationStep? {
        RegistrationStep(rawValue: rawValue + 1)
    }
    
    var previous: RegistrationStep? {
        rawValue > 0 ? RegistrationStep(rawValue: rawValue - 1) : nil
    }
    
    static var requiredSteps: [RegistrationStep] {
        [.basicInfo, .phoneVerification, .personalDetails, .address, .taxFinancial, .disclosures, .agreements]
    }
}

// MARK: - Tax ID Type

enum TaxIdType: String, Codable, CaseIterable {
    case ssn = "USA_SSN"
    case itin = "USA_ITIN"
    case foreignPassport = "FOREIGN_PASSPORT"
    case foreignId = "FOREIGN_ID"
    case kuwaitCivilId = "KUWAIT_CIVIL_ID"
    
    var displayName: String {
        switch self {
        case .ssn: return "Social Security Number (SSN)"
        case .itin: return "Individual Tax ID (ITIN)"
        case .foreignPassport: return "Passport Number"
        case .foreignId: return "Government ID"
        case .kuwaitCivilId: return "Kuwait Civil ID"
        }
    }
    
    var placeholder: String {
        switch self {
        case .ssn, .itin: return "XXX-XX-XXXX"
        case .kuwaitCivilId: return "123456789012"  // 12 digits
        case .foreignPassport, .foreignId: return "Enter ID number"
        }
    }
    
    var alpacaValue: String {
        // Map Kuwait Civil ID to foreign ID for Alpaca API
        switch self {
        case .kuwaitCivilId: return "FOREIGN_ID"
        default: return rawValue
        }
    }
    
    /// Options available for Kuwait users
    static var kuwaitOptions: [TaxIdType] {
        [.kuwaitCivilId, .foreignPassport]
    }
    
    /// Options available for US users
    static var usOptions: [TaxIdType] {
        [.ssn, .itin]
    }
}

// MARK: - Funding Source

enum FundingSource: String, Codable, CaseIterable, Identifiable {
    case employmentIncome = "employment_income"
    case investments = "investments"
    case inheritance = "inheritance"
    case businessIncome = "business_income"
    case savings = "savings"
    case family = "family"
    case pension = "pension"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .employmentIncome: return "Employment Income"
        case .investments: return "Investments"
        case .inheritance: return "Inheritance"
        case .businessIncome: return "Business Income"
        case .savings: return "Savings"
        case .family: return "Family"
        case .pension: return "Pension/Retirement"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .employmentIncome: return "briefcase.fill"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .inheritance: return "gift.fill"
        case .businessIncome: return "building.2.fill"
        case .savings: return "banknote.fill"
        case .family: return "person.3.fill"
        case .pension: return "clock.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Employment Status

enum EmploymentStatus: String, Codable, CaseIterable {
    case none = ""
    case employed = "employed"
    case selfEmployed = "self_employed"
    case unemployed = "unemployed"
    case retired = "retired"
    case student = "student"
    case homemaker = "homemaker"
    
    var displayName: String {
        switch self {
        case .none: return "Select status"
        case .employed: return "Employed"
        case .selfEmployed: return "Self-Employed"
        case .unemployed: return "Unemployed"
        case .retired: return "Retired"
        case .student: return "Student"
        case .homemaker: return "Homemaker"
        }
    }
    
    var requiresEmployerInfo: Bool {
        self == .employed || self == .selfEmployed
    }
    
    var alpacaValue: String {
        rawValue
    }
}

// MARK: - Income Range

enum IncomeRange: String, Codable, CaseIterable {
    case under25k = "0-25000"
    case from25kTo50k = "25001-50000"
    case from50kTo100k = "50001-100000"
    case from100kTo200k = "100001-200000"
    case from200kTo500k = "200001-500000"
    case from500kTo1m = "500001-1000000"
    case over1m = "1000001+"
    
    var displayName: String {
        switch self {
        case .under25k: return "Under $25,000"
        case .from25kTo50k: return "$25,000 - $50,000"
        case .from50kTo100k: return "$50,000 - $100,000"
        case .from100kTo200k: return "$100,000 - $200,000"
        case .from200kTo500k: return "$200,000 - $500,000"
        case .from500kTo1m: return "$500,000 - $1,000,000"
        case .over1m: return "Over $1,000,000"
        }
    }
    
    var minValue: Int {
        switch self {
        case .under25k: return 0
        case .from25kTo50k: return 25001
        case .from50kTo100k: return 50001
        case .from100kTo200k: return 100001
        case .from200kTo500k: return 200001
        case .from500kTo1m: return 500001
        case .over1m: return 1000001
        }
    }
    
    var maxValue: Int? {
        switch self {
        case .under25k: return 25000
        case .from25kTo50k: return 50000
        case .from50kTo100k: return 100000
        case .from100kTo200k: return 200000
        case .from200kTo500k: return 500000
        case .from500kTo1m: return 1000000
        case .over1m: return nil
        }
    }
}

// MARK: - Net Worth Range

enum NetWorthRange: String, Codable, CaseIterable {
    case under50k = "0-50000"
    case from50kTo100k = "50001-100000"
    case from100kTo250k = "100001-250000"
    case from250kTo500k = "250001-500000"
    case from500kTo1m = "500001-1000000"
    case from1mTo5m = "1000001-5000000"
    case over5m = "5000001+"
    
    var displayName: String {
        switch self {
        case .under50k: return "Under $50,000"
        case .from50kTo100k: return "$50,000 - $100,000"
        case .from100kTo250k: return "$100,000 - $250,000"
        case .from250kTo500k: return "$250,000 - $500,000"
        case .from500kTo1m: return "$500,000 - $1,000,000"
        case .from1mTo5m: return "$1,000,000 - $5,000,000"
        case .over5m: return "Over $5,000,000"
        }
    }
}

// MARK: - Liquid Net Worth Range

enum LiquidNetWorthRange: String, Codable, CaseIterable {
    case under25k = "0-25000"
    case from25kTo50k = "25001-50000"
    case from50kTo100k = "50001-100000"
    case from100kTo250k = "100001-250000"
    case from250kTo500k = "250001-500000"
    case from500kTo1m = "500001-1000000"
    case over1m = "1000001+"
    
    var displayName: String {
        switch self {
        case .under25k: return "Under $25,000"
        case .from25kTo50k: return "$25,000 - $50,000"
        case .from50kTo100k: return "$50,000 - $100,000"
        case .from100kTo250k: return "$100,000 - $250,000"
        case .from250kTo500k: return "$250,000 - $500,000"
        case .from500kTo1m: return "$500,000 - $1,000,000"
        case .over1m: return "Over $1,000,000"
        }
    }
}

// MARK: - Investment Experience

enum InvestmentExperience: String, Codable, CaseIterable {
    case none = "none"
    case limited = "limited"
    case good = "good"
    case extensive = "extensive"
    
    var displayName: String {
        switch self {
        case .none: return "No Experience"
        case .limited: return "Limited (1-2 years)"
        case .good: return "Good (3-5 years)"
        case .extensive: return "Extensive (5+ years)"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "I've never invested before"
        case .limited: return "I have some basic experience with stocks or funds"
        case .good: return "I regularly invest and understand market risks"
        case .extensive: return "I have significant experience with various investments"
        }
    }
}

// MARK: - KYC Verification Status

enum KYCVerificationStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case pending = "pending"
    case submitted = "submitted"
    case approved = "approved"
    case rejected = "rejected"
    case actionRequired = "action_required"
    
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .pending: return "Pending Review"
        case .submitted: return "Submitted"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .actionRequired: return "Action Required"
        }
    }
    
    var color: String {
        switch self {
        case .notStarted: return "textTertiary"
        case .inProgress: return "warningYellow"
        case .pending, .submitted: return "primaryPurple"
        case .approved: return "successGreen"
        case .rejected: return "errorRed"
        case .actionRequired: return "warningYellow"
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .pending, .submitted: return "clock.fill"
        case .approved: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        case .actionRequired: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Document Type (for ID verification)

enum KYCDocumentType: String, Codable, CaseIterable {
    case driversLicense = "drivers_license"
    case passport = "passport"
    case nationalId = "national_id"
    case stateId = "state_id"
    
    var displayName: String {
        switch self {
        case .driversLicense: return "Driver's License"
        case .passport: return "Passport"
        case .nationalId: return "National ID Card"
        case .stateId: return "State ID"
        }
    }
    
    var description: String {
        switch self {
        case .driversLicense: return "Valid US driver's license"
        case .passport: return "Valid passport (any country)"
        case .nationalId: return "Government-issued national ID"
        case .stateId: return "State-issued identification card"
        }
    }
    
    var requiresBothSides: Bool {
        switch self {
        case .driversLicense, .nationalId, .stateId: return true
        case .passport: return false
        }
    }
}

// MARK: - Document Upload

struct KYCDocument: Codable, Identifiable {
    let id: UUID
    let type: KYCDocumentType
    var frontImageData: Data?
    var backImageData: Data?
    var uploadedAt: Date?
    var verificationStatus: DocumentVerificationStatus
    var rejectionReason: String?
    
    init(id: UUID = UUID(), type: KYCDocumentType) {
        self.id = id
        self.type = type
        self.verificationStatus = .notUploaded
    }
    
    var isComplete: Bool {
        if type.requiresBothSides {
            return frontImageData != nil && backImageData != nil
        }
        return frontImageData != nil
    }
}

enum DocumentVerificationStatus: String, Codable {
    case notUploaded = "not_uploaded"
    case uploading = "uploading"
    case uploaded = "uploaded"
    case verifying = "verifying"
    case verified = "verified"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .notUploaded: return "Not Uploaded"
        case .uploading: return "Uploading..."
        case .uploaded: return "Uploaded"
        case .verifying: return "Verifying..."
        case .verified: return "Verified"
        case .rejected: return "Rejected"
        }
    }
}

// MARK: - Validation Errors

enum KYCValidationError: Error, LocalizedError {
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case invalidPhoneNumber
    case invalidDateOfBirth
    case underage
    case invalidTaxId
    case missingRequiredField(String)
    case invalidAddress
    case missingFundingSource
    case disclosureContextRequired(String)
    case agreementRequired(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and number"
        case .passwordMismatch:
            return "Passwords do not match"
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .invalidDateOfBirth:
            return "Please enter a valid date of birth"
        case .underage:
            return "You must be at least 18 years old to open an account"
        case .invalidTaxId:
            return "Please enter a valid tax identification number"
        case .missingRequiredField(let field):
            return "\(field) is required"
        case .invalidAddress:
            return "Please enter a valid address"
        case .missingFundingSource:
            return "Please select at least one funding source"
        case .disclosureContextRequired(let disclosure):
            return "Please provide additional details for: \(disclosure)"
        case .agreementRequired(let agreement):
            return "You must accept the \(agreement)"
        }
    }
}

// MARK: - US States

enum USState: String, Codable, CaseIterable, Identifiable {
    case AL, AK, AZ, AR, CA, CO, CT, DE, FL, GA
    case HI, ID, IL, IN, IA, KS, KY, LA, ME, MD
    case MA, MI, MN, MS, MO, MT, NE, NV, NH, NJ
    case NM, NY, NC, ND, OH, OK, OR, PA, RI, SC
    case SD, TN, TX, UT, VT, VA, WA, WV, WI, WY
    case DC
    
    var id: String { rawValue }
    
    var fullName: String {
        switch self {
        case .AL: return "Alabama"
        case .AK: return "Alaska"
        case .AZ: return "Arizona"
        case .AR: return "Arkansas"
        case .CA: return "California"
        case .CO: return "Colorado"
        case .CT: return "Connecticut"
        case .DE: return "Delaware"
        case .FL: return "Florida"
        case .GA: return "Georgia"
        case .HI: return "Hawaii"
        case .ID: return "Idaho"
        case .IL: return "Illinois"
        case .IN: return "Indiana"
        case .IA: return "Iowa"
        case .KS: return "Kansas"
        case .KY: return "Kentucky"
        case .LA: return "Louisiana"
        case .ME: return "Maine"
        case .MD: return "Maryland"
        case .MA: return "Massachusetts"
        case .MI: return "Michigan"
        case .MN: return "Minnesota"
        case .MS: return "Mississippi"
        case .MO: return "Missouri"
        case .MT: return "Montana"
        case .NE: return "Nebraska"
        case .NV: return "Nevada"
        case .NH: return "New Hampshire"
        case .NJ: return "New Jersey"
        case .NM: return "New Mexico"
        case .NY: return "New York"
        case .NC: return "North Carolina"
        case .ND: return "North Dakota"
        case .OH: return "Ohio"
        case .OK: return "Oklahoma"
        case .OR: return "Oregon"
        case .PA: return "Pennsylvania"
        case .RI: return "Rhode Island"
        case .SC: return "South Carolina"
        case .SD: return "South Dakota"
        case .TN: return "Tennessee"
        case .TX: return "Texas"
        case .UT: return "Utah"
        case .VT: return "Vermont"
        case .VA: return "Virginia"
        case .WA: return "Washington"
        case .WV: return "West Virginia"
        case .WI: return "Wisconsin"
        case .WY: return "Wyoming"
        case .DC: return "District of Columbia"
        }
    }
}

// MARK: - Kuwait Governorates

enum KuwaitGovernorate: String, Codable, CaseIterable, Identifiable {
    case alAsimah = "Al Asimah"
    case hawalli = "Hawalli"
    case farwaniya = "Al Farwaniyah"
    case mubarak = "Mubarak Al-Kabeer"
    case ahmadi = "Al Ahmadi"
    case jahra = "Al Jahra"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var displayNameArabic: String {
        switch self {
        case .alAsimah: return "العاصمة"
        case .hawalli: return "حولي"
        case .farwaniya: return "الفروانية"
        case .mubarak: return "مبارك الكبير"
        case .ahmadi: return "الأحمدي"
        case .jahra: return "الجهراء"
        }
    }
}

// MARK: - Country

struct Country: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let flag: String
    let dialCode: String
    
    var id: String { code }
    
    /// Check if country is Kuwait
    var isKuwait: Bool { code == "KWT" }
    
    /// Check if country is USA
    var isUSA: Bool { code == "USA" }
    
    static let kuwait = Country(code: "KWT", name: "Kuwait", flag: "🇰🇼", dialCode: "+965")
    static let usa = Country(code: "USA", name: "United States", flag: "🇺🇸", dialCode: "+1")
    static let canada = Country(code: "CAN", name: "Canada", flag: "🇨🇦", dialCode: "+1")
    static let uk = Country(code: "GBR", name: "United Kingdom", flag: "🇬🇧", dialCode: "+44")
    
    /// Primary country for the app (Kuwait-only)
    static let primary = kuwait
    
    /// All supported countries - Kuwait is primary, GCC countries next, then others
    static let common: [Country] = [
        // Kuwait first (primary market)
        kuwait,
        
        // GCC countries (regional priority)
        Country(code: "SAU", name: "Saudi Arabia", flag: "🇸🇦", dialCode: "+966"),
        Country(code: "ARE", name: "United Arab Emirates", flag: "🇦🇪", dialCode: "+971"),
        Country(code: "QAT", name: "Qatar", flag: "🇶🇦", dialCode: "+974"),
        Country(code: "BHR", name: "Bahrain", flag: "🇧🇭", dialCode: "+973"),
        Country(code: "OMN", name: "Oman", flag: "🇴🇲", dialCode: "+968"),
        
        // Other Arab countries
        Country(code: "EGY", name: "Egypt", flag: "🇪🇬", dialCode: "+20"),
        Country(code: "JOR", name: "Jordan", flag: "🇯🇴", dialCode: "+962"),
        Country(code: "LBN", name: "Lebanon", flag: "🇱🇧", dialCode: "+961"),
        Country(code: "IRQ", name: "Iraq", flag: "🇮🇶", dialCode: "+964"),
        Country(code: "SYR", name: "Syria", flag: "🇸🇾", dialCode: "+963"),
        Country(code: "PSE", name: "Palestine", flag: "🇵🇸", dialCode: "+970"),
        Country(code: "YEM", name: "Yemen", flag: "🇾🇪", dialCode: "+967"),
        
        // South Asian countries (large expat communities in Kuwait)
        Country(code: "IND", name: "India", flag: "🇮🇳", dialCode: "+91"),
        Country(code: "PAK", name: "Pakistan", flag: "🇵🇰", dialCode: "+92"),
        Country(code: "BGD", name: "Bangladesh", flag: "🇧🇩", dialCode: "+880"),
        Country(code: "LKA", name: "Sri Lanka", flag: "🇱🇰", dialCode: "+94"),
        Country(code: "NPL", name: "Nepal", flag: "🇳🇵", dialCode: "+977"),
        
        // Southeast Asian countries (large expat communities)
        Country(code: "PHL", name: "Philippines", flag: "🇵🇭", dialCode: "+63"),
        Country(code: "IDN", name: "Indonesia", flag: "🇮🇩", dialCode: "+62"),
        
        // Western countries
        usa, canada, uk,
        Country(code: "DEU", name: "Germany", flag: "🇩🇪", dialCode: "+49"),
        Country(code: "FRA", name: "France", flag: "🇫🇷", dialCode: "+33"),
        Country(code: "AUS", name: "Australia", flag: "🇦🇺", dialCode: "+61"),
    ]
    
    /// Get country by code
    static func byCode(_ code: String) -> Country? {
        common.first { $0.code == code }
    }
}

// MARK: - Persistence Key

extension KYCRegistrationData {
    static let persistenceKey = "kyc_registration_data"
    
    /// Save to UserDefaults for persistence across app backgrounding
    func save() throws {
        var copy = self
        copy.lastUpdatedAt = Date()
        let data = try JSONEncoder().encode(copy)
        UserDefaults.standard.set(data, forKey: Self.persistenceKey)
    }
    
    /// Load from UserDefaults
    static func load() -> KYCRegistrationData? {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            return nil
        }
        return try? JSONDecoder().decode(KYCRegistrationData.self, from: data)
    }
    
    /// Clear saved data
    static func clear() {
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }
}

