//
//  AlpacaTradingService.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/25/25.
//

import Foundation
import Combine
import UIKit

class AlpacaTradingService: ObservableObject {
    static let shared = AlpacaTradingService()
    
    private let apiKey = AppConfig.Alpaca.apiKey
    private let apiSecret = AppConfig.Alpaca.apiSecret
    private let brokerBaseURL = AppConfig.Alpaca.brokerBaseURL
    private let dataBaseURL = AppConfig.Alpaca.dataBaseURL
    
    @Published var isPlacingOrder = false
    @Published var currentAccount: AlpacaAccount?
    @Published var currentPositions: [AlpacaPosition] = []
    @Published var investmentInProgress = false
    @Published var lastInvestmentResult: PortfolioInvestmentResult?
    
    // Account creation state
    @Published var accountCreationResult: AlpacaAccountCreationResult?
    @Published var isCreatingAccount = false
    @Published var accountStatus: AlpacaAccountStatus?
    
    // Cache for verified assets
    private var verifiedAssets: [String: AlpacaAsset] = [:]
    
    private init() {}
    
    // MARK: - Initialization
    
    /// Verifies Broker API keys are valid
    func initializeSession() async -> Bool {
        if await checkBrokerAPI() {
            print("✅ Session Init: Broker API verified successfully.")
            return true
        }
        
        print("❌ Session Init: Broker API verification failed.")
        return false
    }
    
    private func checkBrokerAPI() async -> Bool {
        let url = URL(string: "\(brokerBaseURL)/clock")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let loginString = "\(apiKey):\(apiSecret)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return true
            }
        } catch {
            print("Broker API Check Failed: \(error)")
        }
        return false
    }
    
    // MARK: - Account Management
    
    /// Searches for an existing account by email in Alpaca Broker API
    func searchAccountByEmail(_ email: String) async throws -> AlpacaAccount? {
        print("🔍 Searching for Alpaca account with email: \(email)")
        
        // URL encode the email for query parameter
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        let url = URL(string: "\(brokerBaseURL)/accounts?query=\(encodedEmail)")!
        
        let request = try createBrokerRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Search Response: \(responseString.prefix(500))")
        }
        
        try validateResponse(response, data: data)
        
        // The API returns an array of accounts
        let accounts = try JSONDecoder().decode([AlpacaAccount].self, from: data)
        
        // Find the account that matches the email exactly
        if let matchingAccount = accounts.first(where: { $0.contact?.email_address.lowercased() == email.lowercased() }) {
            print("✅ Found account for email \(email): \(matchingAccount.id)")
            return matchingAccount
        }
        
        // If no exact match, return the first account if any (for cases where search is partial)
        if let firstAccount = accounts.first {
            print("⚠️ No exact email match, using first result: \(firstAccount.id)")
            return firstAccount
        }
        
        print("❌ No account found for email: \(email)")
        return nil
    }
    
    /// Creates a new user account in Alpaca Broker API
    func createAccount(email: String, firstName: String, lastName: String) async throws -> String {
        print("📝 Starting Alpaca Account Creation...")
        print("   Email: \(email)")
        print("   Name: \(firstName) \(lastName)")
        
        let contact = AlpacaContact(
            email_address: email,
            phone_number: "+15555555555",
            street_address: ["123 Main St"],
            city: "New York",
            state: "NY",
            postal_code: "10001",
            country: "USA"
        )
        
        let identity = AlpacaIdentity(
            given_name: firstName,
            family_name: lastName,
            date_of_birth: "1990-01-01",
            tax_id: "555-12-3456",
            tax_id_type: "USA_SSN",
            country_of_citizenship: "USA",
            country_of_birth: "USA",
            country_of_tax_residence: "USA",
            funding_source: ["employment_income"]
        )
        
        let disclosures = AlpacaDisclosures(
            is_control_person: false,
            is_affiliated_exchange_or_finra: false,
            is_politically_exposed: false,
            immediate_family_exposed: false
        )
        
        let signedAt = ISO8601DateFormatter().string(from: Date())
        let ipAddress = "127.0.0.1"
        
        // Required agreements for Alpaca Broker API
        let agreements = [
            AlpacaAgreement(agreement: "account_agreement", signed_at: signedAt, ip_address: ipAddress),
            AlpacaAgreement(agreement: "customer_agreement", signed_at: signedAt, ip_address: ipAddress),
            AlpacaAgreement(agreement: "margin_agreement", signed_at: signedAt, ip_address: ipAddress)
        ]
        
        let body = AlpacaCreateAccountRequest(
            contact: contact,
            identity: identity,
            disclosures: disclosures,
            agreements: agreements
        )
        
        let url = URL(string: "\(brokerBaseURL)/accounts")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(body)
        
        // Log the request body (REDACTED for security)
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request Body (redacted):")
            print(redactSensitiveInfo(bodyString))
        }
        
        print("📤 Sending POST to: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log raw response (REDACTED for security)
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw Response (redacted):")
            print(redactSensitiveInfo(responseString))
        }
        
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        print("✅ Account Created Successfully!")
        print("   Account ID: \(account.id)")
        print("   Status: \(account.status ?? "unknown")")
        
        return account.id
    }
    
    /// Creates a new user account with full KYC data in Alpaca Broker API
    func createAccountWithKYC(
        contact: AlpacaContact,
        identity: AlpacaIdentity,
        disclosures: AlpacaDisclosures,
        agreements: [AlpacaAgreement],
        trustedContact: AlpacaTrustedContact? = nil
    ) async throws -> String {
        print("📝 Starting Alpaca Account Creation with full KYC...")
        print("   Email: \(contact.email_address)")
        print("   Name: \(identity.given_name) \(identity.family_name)")
        
        let body = AlpacaCreateAccountRequest(
            contact: contact,
            identity: identity,
            disclosures: disclosures,
            agreements: agreements,
            trusted_contact: trustedContact
        )
        
        let url = URL(string: "\(brokerBaseURL)/accounts")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(body)
        
        // Log the request body (REDACTED for security)
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request Body (redacted):")
            print(redactSensitiveInfo(bodyString))
        }
        
        print("📤 Sending POST to: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log raw response (REDACTED for security)
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw Response (redacted):")
            print(redactSensitiveInfo(responseString))
        }
        
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        print("✅ Account Created Successfully with full KYC!")
        print("   Account ID: \(account.id)")
        print("   Status: \(account.status ?? "unknown")")
        
        return account.id
    }
    
    // MARK: - Enhanced Account Creation with Full KYC Data
    
    /// Creates a new account using comprehensive KYC registration data
    /// Returns a detailed result including status and any required actions
    /// Supports international users (Kuwait, GCC) with appropriate tax forms
    func createAccount(registrationData: KYCRegistrationData) async throws -> AlpacaAccountCreationResult {
        await MainActor.run { isCreatingAccount = true }
        defer { Task { await MainActor.run { isCreatingAccount = false } } }
        
        // Determine if user is a US person or international
        let isUSPerson = registrationData.citizenship == "USA" || 
                         registrationData.countryOfTaxResidence == "USA"
        let userCountry = registrationData.country.isEmpty ? "KWT" : registrationData.country
        
        print("📝 Starting Enhanced Alpaca Account Creation...")
        print("   Email: \(registrationData.email)")
        print("   Name: \(registrationData.firstName) \(registrationData.lastName)")
        print("   International User: \(!isUSPerson)")
        print("   Country: \(userCountry)")
        
        // Build contact information with proper phone formatting for user's country
        let contact = AlpacaContact(
            email_address: registrationData.email,
            phone_number: formatPhoneNumber(registrationData.phoneNumber, country: userCountry),
            street_address: [registrationData.streetAddress, registrationData.apartmentUnit].compactMap { $0?.isEmpty == false ? $0 : nil },
            city: registrationData.city,
            state: registrationData.state.isEmpty ? nil : registrationData.state,
            postal_code: registrationData.postalCode,
            country: userCountry
        )
        
        // Determine tax ID type based on citizenship
        // For international users (Kuwait, GCC, etc.), use FOREIGN_ID or FOREIGN_PASSPORT
        let taxIdType: String
        if isUSPerson {
            taxIdType = registrationData.taxIdType.rawValue
        } else {
            // International users must use foreign ID types
            switch registrationData.taxIdType {
            case .ssn, .itin:
                // Force to FOREIGN_ID for non-US persons
                taxIdType = TaxIdType.foreignId.rawValue
            case .foreignPassport, .foreignId, .kuwaitCivilId:
                taxIdType = registrationData.taxIdType.rawValue
            }
        }
        
        // Build identity with all financial information
        let identity = AlpacaIdentity(
            given_name: registrationData.firstName,
            family_name: registrationData.lastName,
            date_of_birth: formatDate(registrationData.dateOfBirth),
            tax_id: cleanTaxId(registrationData.taxId),
            tax_id_type: taxIdType,
            country_of_citizenship: registrationData.citizenship.isEmpty ? userCountry : registrationData.citizenship,
            country_of_birth: registrationData.countryOfBirth.isEmpty ? userCountry : registrationData.countryOfBirth,
            country_of_tax_residence: registrationData.countryOfTaxResidence.isEmpty ? userCountry : registrationData.countryOfTaxResidence,
            funding_source: registrationData.fundingSources.map { $0.rawValue },
            annual_income_min: registrationData.annualIncome?.minValue,
            annual_income_max: registrationData.annualIncome?.maxValue,
            liquid_net_worth_min: registrationData.liquidNetWorth?.minValue,
            liquid_net_worth_max: registrationData.liquidNetWorth?.maxValue,
            total_net_worth_min: registrationData.netWorth?.minValue,
            total_net_worth_max: registrationData.netWorth?.maxValue,
            employment_status: registrationData.employmentStatus.rawValue,
            employer_name: registrationData.employer,
            occupation: registrationData.occupation,
            investment_experience: registrationData.investmentExperience?.rawValue
        )
        
        // Build disclosures with context
        let disclosures = AlpacaDisclosures(
            is_control_person: registrationData.isControlPerson,
            is_affiliated_exchange_or_finra: registrationData.isAffiliatedWithExchange,
            is_politically_exposed: registrationData.isPoliticallyExposed,
            immediate_family_exposed: registrationData.immediateFamilyExposed,
            control_person_context: registrationData.controlPersonContext,
            affiliated_context: registrationData.affiliationContext,
            politically_exposed_context: registrationData.politicalExposureContext
        )
        
        // Build agreements with timestamp and IP
        let signedAt = ISO8601DateFormatter().string(from: Date())
        let ipAddress = registrationData.ipAddress ?? "0.0.0.0"
        
        var agreements: [AlpacaAgreement] = [
            AlpacaAgreement(agreement: "customer_agreement", signed_at: signedAt, ip_address: ipAddress),
            AlpacaAgreement(agreement: "account_agreement", signed_at: signedAt, ip_address: ipAddress)
        ]
        
        // Add margin agreement if accepted
        if registrationData.agreedToMarginAgreement {
            agreements.append(AlpacaAgreement(agreement: "margin_agreement", signed_at: signedAt, ip_address: ipAddress))
        }
        
        // For international users (non-US), add W-8BEN agreement instead of W-9
        // W-8BEN is required for foreign persons to certify foreign status for tax withholding
        if !isUSPerson {
            agreements.append(AlpacaAgreement(
                agreement: "w8ben_agreement",
                signed_at: signedAt,
                ip_address: ipAddress
            ))
            print("   📋 Added W-8BEN agreement for international user")
        }
        
        // Build trusted contact if provided
        let trustedContact = buildTrustedContact(from: registrationData)
        
        // Create the request body
        let body = AlpacaCreateAccountRequest(
            contact: contact,
            identity: identity,
            disclosures: disclosures,
            agreements: agreements,
            trusted_contact: trustedContact
        )
        
        let url = URL(string: "\(brokerBaseURL)/accounts")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(body)
        
        // Log the request body (redact sensitive info)
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            let redactedBody = redactSensitiveInfo(bodyString)
            print("📤 Request Body (redacted):")
            print(redactedBody)
        }
        
        print("📤 Sending POST to: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw Response:")
            print(responseString)
        }
        
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        print("✅ Account Created!")
        print("   Account ID: \(account.id)")
        print("   Status: \(account.status ?? "unknown")")
        
        // Fetch full account status for detailed result
        let statusResponse = try? await getAccountStatus(accountId: account.id)
        
        // Build comprehensive result
        let result = AlpacaAccountCreationResult.from(account: account, statusResponse: statusResponse)
        
        await MainActor.run {
            self.accountCreationResult = result
            self.accountStatus = statusResponse
        }
        
        return result
    }
    
    // MARK: - Account Status Handling
    
    /// Fetches and processes account status, returning actionable result
    func checkAccountStatus(accountId: String) async throws -> AlpacaAccountCreationResult {
        print("🔍 Checking account status for: \(accountId)")
        
        // Get account details
        let accountUrl = URL(string: "\(brokerBaseURL)/accounts/\(accountId)")!
        let accountRequest = try createBrokerRequest(url: accountUrl, method: "GET")
        
        let (accountData, accountResponse) = try await URLSession.shared.data(for: accountRequest)
        try validateResponse(accountResponse, data: accountData)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: accountData)
        
        // Get detailed status
        let statusResponse = try await getAccountStatus(accountId: accountId)
        
        let result = AlpacaAccountCreationResult.from(account: account, statusResponse: statusResponse)
        
        await MainActor.run {
            self.accountCreationResult = result
            self.accountStatus = statusResponse
        }
        
        // Log status
        logAccountStatus(result)
        
        return result
    }
    
    /// Handles different account statuses with appropriate actions
    func handleAccountStatus(_ result: AlpacaAccountCreationResult) -> AccountStatusAction {
        switch result.status {
        case .submitted:
            return .showPendingVerification(
                message: result.message ?? "Your account is being verified. This typically takes 1-3 business days."
            )
            
        case .actionRequired:
            return .showRequiredActions(actions: result.requiredActions)
            
        case .approved:
            return .proceedToOnboarding(accountId: result.accountId)
            
        case .rejected:
            return .showRejection(
                reasons: result.rejectionReasons ?? ["Unable to verify your information"],
                canAppeal: true
            )
            
        case .pendingReview:
            return .showPendingVerification(
                message: "Your application is under manual review. We'll notify you when complete."
            )
        }
    }
    
    /// Polls account status until it changes from pending
    func pollAccountStatus(accountId: String, maxAttempts: Int = 10, intervalSeconds: TimeInterval = 30) async throws -> AlpacaAccountCreationResult {
        var attempts = 0
        
        while attempts < maxAttempts {
            let result = try await checkAccountStatus(accountId: accountId)
            
            // If no longer pending, return the result
            if result.status != .submitted && result.status != .pendingReview {
                return result
            }
            
            attempts += 1
            
            if attempts < maxAttempts {
                try await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
        
        // Return last known status
        return try await checkAccountStatus(accountId: accountId)
    }
    
    /// Submit appeal for rejected account
    func submitAccountAppeal(accountId: String, reason: String, additionalInfo: String?) async throws {
        print("📝 Submitting appeal for account: \(accountId)")
        
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)")!
        var request = try createBrokerRequest(url: url, method: "PATCH")
        
        var body: [String: Any] = [
            "appeal_reason": reason
        ]
        
        if let info = additionalInfo {
            body["additional_information"] = info
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Appeal Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        print("✅ Appeal submitted successfully")
    }
    
    private func logAccountStatus(_ result: AlpacaAccountCreationResult) {
        print("📊 Account Status Summary:")
        print("   Account ID: \(result.accountId)")
        print("   Status: \(result.status.displayTitle)")
        
        if !result.requiredActions.isEmpty {
            print("   Required Actions:")
            for action in result.requiredActions {
                print("     - \(action.type.displayName): \(action.description)")
            }
        }
        
        if let reasons = result.rejectionReasons {
            print("   Rejection Reasons:")
            for reason in reasons {
                print("     - \(reason)")
            }
        }
        
        if let message = result.message {
            print("   Message: \(message)")
        }
    }
    
    /// Uploads a document for KYC verification
    func uploadDocument(accountId: String, documentType: String, documentSubType: String?, imageData: Data, mimeType: String = "image/jpeg") async throws -> AlpacaDocumentResponse {
        print("📄 Uploading document for account: \(accountId)")
        
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/documents/upload")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let base64Content = imageData.base64EncodedString()
        
        var body: [String: Any] = [
            "document_type": documentType,
            "content": base64Content,
            "mime_type": mimeType
        ]
        
        if let subType = documentSubType {
            body["document_sub_type"] = subType
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Document Upload Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        
        let documentResponse = try JSONDecoder().decode(AlpacaDocumentResponse.self, from: data)
        print("✅ Document uploaded successfully: \(documentResponse.id)")
        
        return documentResponse
    }
    
    // MARK: - Enhanced Document Upload API
    
    /// Uploads a document with automatic image compression and format handling
    /// - Parameters:
    ///   - accountId: The Alpaca account ID
    ///   - documentType: Type of document (identity_verification, address_verification, etc.)
    ///   - documentSubType: Sub-type (passport, drivers_license, etc.)
    ///   - imageData: Raw image data
    ///   - side: For documents requiring both sides (front/back)
    /// - Returns: Upload result with status
    func uploadDocumentWithCompression(
        accountId: String,
        documentType: AlpacaDocumentType,
        documentSubType: AlpacaDocumentSubType?,
        imageData: Data,
        side: DocumentSide = .front
    ) async throws -> AlpacaDocumentUploadResult {
        print("📄 Uploading \(documentType.displayName) (\(side.rawValue)) for account: \(accountId)")
        
        // Compress and validate image
        let (processedData, mimeType) = try processImageForUpload(imageData)
        
        print("   Original size: \(imageData.count / 1024)KB")
        print("   Processed size: \(processedData.count / 1024)KB")
        print("   MIME type: \(mimeType)")
        
        // Build document type string with side suffix if needed
        var docTypeString = documentType.rawValue
        if documentSubType?.requiresBothSides == true {
            docTypeString += "_\(side.rawValue)"
        }
        
        // Upload the document
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/documents/upload")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let base64Content = processedData.base64EncodedString()
        
        var body: [String: Any] = [
            "document_type": documentType.rawValue,
            "content": base64Content,
            "mime_type": mimeType
        ]
        
        if let subType = documentSubType {
            body["document_sub_type"] = subType.rawValue
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Document Upload Response: \(responseString)")
        }
        
        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            return AlpacaDocumentUploadResult(
                documentId: "",
                uploadedAt: Date(),
                status: .failed(error: "Invalid response"),
                errorMessage: "Server returned invalid response"
            )
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            let documentResponse = try JSONDecoder().decode(AlpacaDocumentResponse.self, from: data)
            print("✅ Document uploaded successfully: \(documentResponse.id)")
            
            return AlpacaDocumentUploadResult(
                documentId: documentResponse.id,
                uploadedAt: Date(),
                status: .uploaded,
                errorMessage: nil
            )
        } else {
            // Parse error
            let errorMessage = parseUploadError(data: data, statusCode: httpResponse.statusCode)
            
            return AlpacaDocumentUploadResult(
                documentId: "",
                uploadedAt: Date(),
                status: .failed(error: errorMessage),
                errorMessage: errorMessage
            )
        }
    }
    
    /// Uploads both sides of an ID document
    func uploadIdDocument(
        accountId: String,
        documentSubType: AlpacaDocumentSubType,
        frontImageData: Data,
        backImageData: Data?
    ) async throws -> [AlpacaDocumentUploadResult] {
        var results: [AlpacaDocumentUploadResult] = []
        
        // Upload front
        let frontResult = try await uploadDocumentWithCompression(
            accountId: accountId,
            documentType: .identityVerification,
            documentSubType: documentSubType,
            imageData: frontImageData,
            side: .front
        )
        results.append(frontResult)
        
        // Upload back if required and provided
        if documentSubType.requiresBothSides, let backData = backImageData {
            let backResult = try await uploadDocumentWithCompression(
                accountId: accountId,
                documentType: .identityVerification,
                documentSubType: documentSubType,
                imageData: backData,
                side: .back
            )
            results.append(backResult)
        }
        
        return results
    }
    
    /// Uploads proof of address document
    func uploadProofOfAddress(
        accountId: String,
        documentSubType: AlpacaDocumentSubType,
        imageData: Data
    ) async throws -> AlpacaDocumentUploadResult {
        return try await uploadDocumentWithCompression(
            accountId: accountId,
            documentType: .addressVerification,
            documentSubType: documentSubType,
            imageData: imageData,
            side: .front
        )
    }
    
    /// Processes image data for upload: validates, compresses, and converts if needed
    private func processImageForUpload(_ imageData: Data) throws -> (Data, String) {
        // Check if it's a PDF
        if isPDF(imageData) {
            // Validate PDF size
            if imageData.count > DocumentImageSettings.maxFileSize {
                throw DocumentUploadError.fileTooLarge(maxSize: DocumentImageSettings.maxFileSize)
            }
            return (imageData, "application/pdf")
        }
        
        // Try to create a UIImage
        guard let image = UIImage(data: imageData) else {
            throw DocumentUploadError.invalidImageFormat
        }
        
        // Resize if needed
        let resizedImage = resizeImageIfNeeded(image, maxDimension: DocumentImageSettings.maxDimension)
        
        // Compress to JPEG with adaptive quality
        var quality = DocumentImageSettings.compressionQuality
        var compressedData = resizedImage.jpegData(compressionQuality: quality)
        
        // Progressively reduce quality if still too large
        while let data = compressedData,
              data.count > DocumentImageSettings.maxFileSize,
              quality > 0.3 {
            quality -= 0.1
            compressedData = resizedImage.jpegData(compressionQuality: quality)
        }
        
        guard let finalData = compressedData else {
            throw DocumentUploadError.compressionFailed
        }
        
        if finalData.count > DocumentImageSettings.maxFileSize {
            throw DocumentUploadError.fileTooLarge(maxSize: DocumentImageSettings.maxFileSize)
        }
        
        return (finalData, "image/jpeg")
    }
    
    /// Resizes image if it exceeds maximum dimension
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resize is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Render resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Checks if data is a PDF file
    private func isPDF(_ data: Data) -> Bool {
        // PDF magic bytes: %PDF
        let pdfMagic: [UInt8] = [0x25, 0x50, 0x44, 0x46]
        guard data.count >= 4 else { return false }
        let header = Array(data.prefix(4))
        return header == pdfMagic
    }
    
    /// Parses upload error from response
    private func parseUploadError(data: Data, statusCode: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = json["message"] as? String {
                return message
            }
            if let code = json["code"] as? String {
                return "Error: \(code)"
            }
        }
        
        switch statusCode {
        case 400: return "Invalid document format or data"
        case 401: return "Authentication failed"
        case 403: return "Not authorized to upload documents"
        case 404: return "Account not found"
        case 413: return "File too large"
        case 422: return "Invalid document type or content"
        default: return "Upload failed (HTTP \(statusCode))"
        }
    }
    
    /// Gets the KYC/CIP verification status for an account
    func getAccountStatus(accountId: String) async throws -> AlpacaAccountStatus {
        print("🔍 Fetching account status for: \(accountId)")
        
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Account Status Response: \(responseString.prefix(500))")
        }
        
        try validateResponse(response, data: data)
        
        let status = try JSONDecoder().decode(AlpacaAccountStatus.self, from: data)
        print("✅ Account status: \(status.status)")
        
        return status
    }
    
    /// Gets all documents for an account
    func getDocuments(accountId: String) async throws -> [AlpacaDocumentResponse] {
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/documents")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode([AlpacaDocumentResponse].self, from: data)
    }
    
    /// Updates an existing account with additional information
    func updateAccount(accountId: String, updates: [String: Any]) async throws {
        print("📝 Updating account: \(accountId)")
        
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)")!
        var request = try createBrokerRequest(url: url, method: "PATCH")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: updates)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Update Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        print("✅ Account updated successfully")
    }
    
    /// Fetches account details for a sub-account
    func fetchAccountDetails(accountId: String) async throws -> AlpacaAccount {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account")!
        
        let request = try createBrokerRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let account = try JSONDecoder().decode(AlpacaAccount.self, from: data)
        await MainActor.run { self.currentAccount = account }
        return account
    }
    
    /// Creates an ACH relationship for sandbox funding
    func createSandboxACHRelationship(accountId: String) async throws -> String {
        print("🏦 Creating sandbox ACH relationship for account: \(accountId)")
        
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/ach_relationships")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        // Sandbox test bank details
        let body: [String: Any] = [
            "account_owner_name": "Test User",
            "bank_account_type": "CHECKING",
            "bank_account_number": "32131231abc",
            "bank_routing_number": "121000358",
            "nickname": "Test Bank Account"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 ACH Relationship Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        
        // Parse the relationship ID
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let relationshipId = json["id"] as? String {
            print("✅ ACH Relationship Created: \(relationshipId)")
            
            // SANDBOX: Approve the ACH relationship so transfers can complete
            await approveACHRelationship(accountId: accountId, relationshipId: relationshipId)
            
            return relationshipId
        }
        
        throw URLError(.badServerResponse)
    }
    
    /// SANDBOX ONLY: Approves an ACH relationship so transfers can be processed
    private func approveACHRelationship(accountId: String, relationshipId: String) async {
        print("🔄 Approving ACH relationship in sandbox...")
        
        // Sandbox endpoint to approve ACH relationship
        let url = URL(string: "\(brokerBaseURL)/sandbox/accounts/\(accountId)/ach_relationships/\(relationshipId)/approve")!
        
        do {
            var request = try createBrokerRequest(url: url, method: "POST")
            request.httpBody = "{}".data(using: .utf8)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ ACH relationship approved")
                } else if let responseString = String(data: data, encoding: .utf8) {
                    print("⚠️ ACH approval response (\(httpResponse.statusCode)): \(responseString)")
                }
            }
        } catch {
            print("⚠️ ACH approval failed: \(error)")
        }
    }
    
    /// Gets existing ACH relationships
    func getACHRelationships(accountId: String) async throws -> [[String: Any]] {
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/ach_relationships")!
        let request = try createBrokerRequest(url: url, method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        if let relationships = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return relationships
        }
        return []
    }

    /// Gets linked bank account information for display
    /// Returns nil if no bank account is linked
    func getLinkedBankAccount(accountId: String) async throws -> LinkedBankAccount? {
        let relationships = try await getACHRelationships(accountId: accountId)

        guard let relationship = relationships.first,
              let status = relationship["status"] as? String,
              status.uppercased() == "APPROVED" || status.uppercased() == "ACTIVE" else {
            return nil
        }

        let nickname = relationship["nickname"] as? String ?? "Bank Account"
        let bankAccountType = relationship["bank_account_type"] as? String ?? "CHECKING"
        let bankAccountNumber = relationship["bank_account_number"] as? String ?? ""
        let relationshipId = relationship["id"] as? String ?? ""

        // Mask account number - show only last 4 digits
        let maskedAccountNumber: String
        if bankAccountNumber.count >= 4 {
            maskedAccountNumber = "••••" + bankAccountNumber.suffix(4)
        } else {
            maskedAccountNumber = "••••" + bankAccountNumber
        }

        return LinkedBankAccount(
            id: relationshipId,
            nickname: nickname,
            bankAccountType: bankAccountType,
            maskedAccountNumber: maskedAccountNumber,
            status: status
        )
    }

    /// Checks if user has a linked bank account for withdrawals
    func hasLinkedBankAccount(accountId: String) async -> Bool {
        do {
            let account = try await getLinkedBankAccount(accountId: accountId)
            return account != nil
        } catch {
            return false
        }
    }
    
    /// Funds the account via ACH Transfer (Sandbox)
    /// In sandbox mode, we also simulate instant completion of the transfer
    func fundAccount(accountId: String, amount: Double) async throws {
        print("💰 Funding account \(accountId) with $\(amount)")
        
        guard amount > 0 else { return }
        
        // First, check if we have an ACH relationship, if not create one
        var relationshipId: String?
        let relationships = try await getACHRelationships(accountId: accountId)
        
        if let firstRelationship = relationships.first,
           let id = firstRelationship["id"] as? String {
            relationshipId = id
            print("📌 Using existing ACH relationship: \(id)")
            
            // SANDBOX: Check if relationship needs approval
            let status = firstRelationship["status"] as? String ?? ""
            if status == "QUEUED" || status == "PENDING" {
                print("⚠️ ACH relationship is \(status), approving...")
                await approveACHRelationship(accountId: accountId, relationshipId: id)
            }
        } else {
            // Create a new ACH relationship for sandbox
            relationshipId = try await createSandboxACHRelationship(accountId: accountId)
        }
        
        guard let achRelationshipId = relationshipId else {
            throw URLError(.badServerResponse)
        }
        
        // Create transfer
        let transferUrl = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/transfers")!
        var transferRequest = try createBrokerRequest(url: transferUrl, method: "POST")
        
        let body: [String: Any] = [
            "transfer_type": "ach",
            "relationship_id": achRelationshipId,
            "amount": String(format: "%.2f", amount),
            "direction": "INCOMING"
        ]
        
        transferRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: transferRequest)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Transfer Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        
        // Parse transfer ID from response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let transferId = json["id"] as? String {
            print("✅ Transfer created with ID: \(transferId)")
            
            // SANDBOX ONLY: Simulate instant completion of the transfer
            // This uses the Alpaca sandbox simulation endpoint
            await simulateTransferComplete(accountId: accountId, transferId: transferId)
        }
        
        print("✅ Funding transfer initiated successfully!")
        
        // Wait a brief moment for the transfer to be processed
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Refresh account to get updated balance
        _ = try? await fetchAccountDetails(accountId: accountId)
    }
    
    /// SANDBOX ONLY: Simulates instant completion of an ACH transfer
    /// This endpoint only works in Alpaca's sandbox environment
    private func simulateTransferComplete(accountId: String, transferId: String) async {
        print("🔄 Simulating transfer completion for sandbox...")
        
        // Method 1: Try PATCH on specific transfer to mark as complete
        let patchUrl = URL(string: "\(brokerBaseURL)/sandbox/accounts/\(accountId)/transfers/\(transferId)")!
        
        do {
            var request = try createBrokerRequest(url: patchUrl, method: "PATCH")
            
            let body: [String: Any] = [
                "status": "COMPLETE"
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ Transfer marked as COMPLETE")
                    // Wait for processing
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    return
                } else if let responseString = String(data: data, encoding: .utf8) {
                    print("⚠️ PATCH transfer response (\(httpResponse.statusCode)): \(responseString)")
                }
            }
        } catch {
            print("⚠️ PATCH transfer failed: \(error)")
        }
        
        // Method 2: Try POST to sandbox transfers endpoint
        let postUrl = URL(string: "\(brokerBaseURL)/sandbox/accounts/\(accountId)/transfers")!
        
        do {
            var request = try createBrokerRequest(url: postUrl, method: "POST")
            
            let body: [String: Any] = [
                "transfer_id": transferId,
                "status": "COMPLETE"
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ Transfer simulation successful via POST")
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    return
                } else if let responseString = String(data: data, encoding: .utf8) {
                    print("⚠️ POST transfer response (\(httpResponse.statusCode)): \(responseString)")
                }
            }
        } catch {
            print("⚠️ POST transfer simulation failed: \(error)")
        }
        
        print("ℹ️ Transfer simulation methods exhausted. Transfer may need manual approval or time to process.")
    }
    
    /// Withdraws funds from the account via ACH Transfer
    /// Returns the transfer details on success
    func withdrawFunds(accountId: String, amount: Double) async throws -> WithdrawalResult {
        print("💸 Withdrawing $\(amount) from account \(accountId)")

        guard amount > 0 else {
            throw WithdrawalError.invalidAmount
        }

        // Validate minimum withdrawal amount
        guard amount >= 1.0 else {
            throw WithdrawalError.belowMinimum(minimum: 1.0)
        }

        // Get account details to check available balance
        let account = try await fetchAccountDetails(accountId: accountId)
        let availableCash = account.cashValue

        // Check if sufficient funds available
        guard amount <= availableCash else {
            throw WithdrawalError.insufficientFunds(available: availableCash, requested: amount)
        }

        // Get existing ACH relationship
        let relationships = try await getACHRelationships(accountId: accountId)

        guard let firstRelationship = relationships.first,
              let achRelationshipId = firstRelationship["id"] as? String else {
            print("❌ No ACH relationship found. Cannot withdraw.")
            throw WithdrawalError.noBankAccountLinked
        }

        // Check ACH relationship status
        let relationshipStatus = firstRelationship["status"] as? String ?? ""
        guard relationshipStatus.uppercased() == "APPROVED" || relationshipStatus.uppercased() == "ACTIVE" else {
            throw WithdrawalError.bankAccountNotApproved(status: relationshipStatus)
        }

        // Create withdrawal transfer
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/transfers")!
        var request = try createBrokerRequest(url: url, method: "POST")

        let body: [String: Any] = [
            "transfer_type": "ach",
            "relationship_id": achRelationshipId,
            "amount": String(format: "%.2f", amount),
            "direction": "OUTGOING"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Withdrawal Response: \(responseString)")
        }

        try validateResponse(response, data: data)

        // Parse response for transfer details
        var transferId = ""
        var status = "QUEUED"
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            transferId = json["id"] as? String ?? ""
            status = json["status"] as? String ?? "QUEUED"
        }

        print("✅ Withdrawal transfer initiated successfully! Transfer ID: \(transferId)")

        // Refresh account to get updated balance
        _ = try? await fetchAccountDetails(accountId: accountId)

        // Get bank account info for the result
        let bankNickname = firstRelationship["nickname"] as? String ?? "Bank Account"
        let bankAccountNumber = firstRelationship["bank_account_number"] as? String ?? ""
        let maskedAccount = bankAccountNumber.count >= 4 ? "••••" + bankAccountNumber.suffix(4) : "••••"

        return WithdrawalResult(
            transferId: transferId,
            amount: amount,
            status: status,
            bankAccountNickname: bankNickname,
            maskedBankAccount: maskedAccount,
            estimatedArrival: "1-3 business days"
        )
    }
    
    /// Gets transfer history for an account
    func getTransfers(accountId: String) async throws -> [[String: Any]] {
        let url = URL(string: "\(brokerBaseURL)/accounts/\(accountId)/transfers")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        if let transfers = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return transfers
        }
        return []
    }
    
    // MARK: - Asset Verification
    
    /// Verifies if an asset is tradable on Alpaca
    func verifyAsset(symbol: String) async throws -> AlpacaAsset {
        // Check cache first
        if let cachedAsset = verifiedAssets[symbol] {
            return cachedAsset
        }
        
        let url = URL(string: "\(brokerBaseURL)/assets/\(symbol)")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let asset = try JSONDecoder().decode(AlpacaAsset.self, from: data)
        
        // Cache the result
        verifiedAssets[symbol] = asset
        
        return asset
    }
    
    /// Verifies multiple assets and returns which ones are tradable
    func verifyAssets(symbols: [String]) async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        await withTaskGroup(of: (String, Bool).self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        let asset = try await self.verifyAsset(symbol: symbol)
                        return (symbol, asset.tradable && asset.fractionable)
                    } catch {
                        print("⚠️ Asset \(symbol) verification failed: \(error)")
                        return (symbol, false)
                    }
                }
            }
            
            for await result in group {
                results[result.0] = result.1
            }
        }
        
        return results
    }
    
    /// Gets tradable allocations for a portfolio, using fallback tickers if primary not available
    func getTradableAllocations(for portfolio: RiskLevel) async -> [(allocation: AssetAllocation, ticker: String, isTradable: Bool)] {
        let allocations = portfolio.allocations
        
        // Collect all tickers (primary and fallback) for verification
        var allTickers: Set<String> = []
        for allocation in allocations {
            allTickers.insert(allocation.ticker)
            if let fallback = allocation.fallbackTicker {
                allTickers.insert(fallback)
            }
        }
        
        let verificationResults = await verifyAssets(symbols: Array(allTickers))
        
        return allocations.map { allocation in
            let primaryTradable = verificationResults[allocation.ticker] ?? false
            
            if primaryTradable {
                return (allocation, allocation.ticker, true)
            } else if let fallback = allocation.fallbackTicker,
                      verificationResults[fallback] == true {
                print("📌 Using fallback ticker \(fallback) for \(allocation.name)")
                return (allocation, fallback, true)
            } else {
                return (allocation, allocation.ticker, false)
            }
        }
    }
    
    // MARK: - Trading
    
    func placeOrder(accountId: String, symbol: String, notional: Double) async throws -> AlpacaOrder {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/orders")!
        
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "symbol": symbol,
            "notional": String(format: "%.2f", notional),
            "side": "buy",
            "type": "market",
            "time_in_force": "day"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let order = try JSONDecoder().decode(AlpacaOrder.self, from: data)
        return order
    }
    
    /// Places orders for all assets in a portfolio based on allocation percentages
    /// Returns detailed results for each order
    func placeBasketOrder(accountId: String, amount: Double, portfolio: RiskLevel) async throws -> PortfolioInvestmentResult {
        await MainActor.run { 
            isPlacingOrder = true 
            investmentInProgress = true
        }
        defer { 
            Task { 
                await MainActor.run { 
                    isPlacingOrder = false 
                    investmentInProgress = false
                } 
            } 
        }
        
        print("📊 Starting portfolio investment for \(portfolio.title)")
        print("   Total amount: $\(String(format: "%.2f", amount))")
        
        var orderResults: [OrderResult] = []
        var totalInvested: Double = 0
        
        // First verify all assets (with fallback support)
        let tradableAllocations = await getTradableAllocations(for: portfolio)
        
        // Calculate adjusted allocations for tradable assets only
        let tradableTotal = tradableAllocations
            .filter { $0.isTradable }
            .reduce(0.0) { $0 + $1.allocation.percentage }
        
        for (allocation, ticker, isTradable) in tradableAllocations {
            if !isTradable {
                print("⚠️ Skipping non-tradable asset: \(allocation.ticker) (and fallback)")
                orderResults.append(OrderResult(
                    symbol: allocation.ticker,
                    requestedAmount: amount * allocation.percentage,
                    status: .skipped,
                    message: "Asset not tradable or not fractionable on Alpaca",
                    orderId: nil
                ))
                continue
            }
            
            // Adjust allocation percentage proportionally if some assets are not tradable
            let adjustedPercentage = allocation.percentage / tradableTotal
            let amountForAsset = amount * adjustedPercentage
            
            // Alpaca minimum is $1 for fractional orders
            if amountForAsset < 1.0 {
                print("⚠️ Skipping \(ticker): Amount $\(String(format: "%.2f", amountForAsset)) below minimum")
                orderResults.append(OrderResult(
                    symbol: ticker,
                    requestedAmount: amountForAsset,
                    status: .skipped,
                    message: "Amount below $1 minimum",
                    orderId: nil
                ))
                continue
            }
            
            do {
                // Use the resolved ticker (primary or fallback)
                let order = try await placeOrder(accountId: accountId, symbol: ticker, notional: amountForAsset)
                print("✅ Placed order for \(ticker): $\(String(format: "%.2f", amountForAsset))")
                totalInvested += amountForAsset
                
                orderResults.append(OrderResult(
                    symbol: ticker,
                    requestedAmount: amountForAsset,
                    status: .success,
                    message: "Order \(order.status)",
                    orderId: order.id
                ))
            } catch {
                print("❌ Failed to place order for \(ticker): \(error)")
                orderResults.append(OrderResult(
                    symbol: ticker,
                    requestedAmount: amountForAsset,
                    status: .failed,
                    message: error.localizedDescription,
                    orderId: nil
                ))
            }
        }
        
        let result = PortfolioInvestmentResult(
            totalInvested: totalInvested,
            orderResults: orderResults,
            successCount: orderResults.filter { $0.status == .success }.count,
            failedCount: orderResults.filter { $0.status == .failed }.count
        )
        
        await MainActor.run {
            self.lastInvestmentResult = result
        }
        
        print("📊 Portfolio investment complete:")
        print("   Total invested: $\(String(format: "%.2f", totalInvested))")
        print("   Successful: \(result.successCount), Failed: \(result.failedCount)")
        
        return result
    }
    
    /// Invests in a portfolio after user completes onboarding
    /// This is the main entry point for auto-investing
    /// 
    /// IMPORTANT: Uses buying_power to validate if trading is possible.
    /// Cash balance can be > 0 while buying_power = 0 (funds reserved for pending orders)
    func investInPortfolio(accountId: String, portfolio: RiskLevel, amount: Double? = nil) async throws -> PortfolioInvestmentResult {
        print("🚀 Starting auto-investment in \(portfolio.title) portfolio")
        
        // Get current account to check available buying power (NOT just cash)
        let account = try await fetchAccountDetails(accountId: accountId)
        let buyingPower = account.buyingPowerValue
        let cashBalance = account.cashValue
        
        // Use buying power as the source of truth for what's actually available
        let availableForTrading = buyingPower
        
        // Use specified amount or all available buying power
        let investmentAmount = min(amount ?? availableForTrading, availableForTrading)
        
        guard investmentAmount >= 1.0 else {
            if cashBalance >= 1.0 && buyingPower < 1.0 {
                print("⚠️ Cannot invest: Cash ($\(String(format: "%.2f", cashBalance))) is reserved. Buying power: $\(String(format: "%.2f", buyingPower))")
                print("   This usually means orders are pending for market open.")
            } else {
                print("⚠️ Insufficient funds for investment: $\(String(format: "%.2f", investmentAmount))")
            }
            return PortfolioInvestmentResult(
                totalInvested: 0,
                orderResults: [],
                successCount: 0,
                failedCount: 0
            )
        }
        
        print("💰 Cash Balance: $\(String(format: "%.2f", cashBalance))")
        print("💳 Buying Power: $\(String(format: "%.2f", buyingPower))")
        print("💵 Investment amount: $\(String(format: "%.2f", investmentAmount))")
        
        return try await placeBasketOrder(accountId: accountId, amount: investmentAmount, portfolio: portfolio)
    }
    
    func fetchPositions(accountId: String) async throws -> [AlpacaPosition] {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/positions")!
        
        let request = try createBrokerRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let positions = try JSONDecoder().decode([AlpacaPosition].self, from: data)
        await MainActor.run { self.currentPositions = positions }
        return positions
    }
    
    // MARK: - Order Management
    
    /// Fetches all open/pending orders for an account
    /// These are orders that have been submitted but not yet filled (e.g., market closed)
    func fetchOpenOrders(accountId: String) async throws -> [OpenOrder] {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/orders?status=open")!
        
        let request = try createBrokerRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📋 Open Orders Response: \(responseString.prefix(500))")
        }
        
        try validateResponse(response, data: data)
        
        let orders = try JSONDecoder().decode([OpenOrder].self, from: data)
        print("📊 Found \(orders.count) open orders")
        
        return orders
    }
    
    /// Fetches all orders (open, closed, all) for an account
    func fetchAllOrders(accountId: String, status: String = "all", limit: Int = 50) async throws -> [OpenOrder] {
        var urlString = "\(brokerBaseURL)/trading/accounts/\(accountId)/orders?limit=\(limit)"
        if status != "all" {
            urlString += "&status=\(status)"
        }
        
        let url = URL(string: urlString)!
        let request = try createBrokerRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode([OpenOrder].self, from: data)
    }
    
    /// Cancels a specific order
    func cancelOrder(accountId: String, orderId: String) async throws {
        print("🚫 Cancelling order: \(orderId)")
        
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/orders/\(orderId)")!
        let request = try createBrokerRequest(url: url, method: "DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        print("✅ Order cancelled successfully")
    }
    
    /// Cancels all open orders for an account
    func cancelAllOrders(accountId: String) async throws {
        print("🚫 Cancelling all open orders for account: \(accountId)")
        
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/orders")!
        let request = try createBrokerRequest(url: url, method: "DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        print("✅ All orders cancelled")
    }
    
    /// Gets a summary of pending orders with total reserved amount
    func getPendingOrdersSummary(accountId: String) async throws -> PendingOrdersSummary {
        let orders = try await fetchOpenOrders(accountId: accountId)
        return PendingOrdersSummary(orders: orders)
    }
    
    func fetchPortfolioHistory(accountId: String, period: String = "1M", timeframe: String = "1D") async throws -> [ChartDataPoint] {
        let url = URL(string: "\(brokerBaseURL)/trading/accounts/\(accountId)/account/portfolio/history")!
        
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "timeframe", value: timeframe)
        ]
        
        guard let finalUrl = components.url else { return [] }
        let request = try createBrokerRequest(url: finalUrl, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        struct HistoryResponse: Codable {
            let timestamp: [Int]
            let equity: [Double]
        }
        
        let history = try JSONDecoder().decode(HistoryResponse.self, from: data)
        
        var points: [ChartDataPoint] = []
        for (index, ts) in history.timestamp.enumerated() {
            if index < history.equity.count {
                let date = Date(timeIntervalSince1970: TimeInterval(ts))
                let value = history.equity[index]
                points.append(ChartDataPoint(date: date, value: value))
            }
        }
        return points
    }
    
    // MARK: - Market Data
    
    func getLatestPrice(symbol: String) async throws -> Double {
        let url = URL(string: "\(dataBaseURL)/stocks/\(symbol)/quotes/latest")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Market Data API uses the same Basic Auth for Broker API
        let loginString = "\(apiKey):\(apiSecret)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        let result = try JSONDecoder().decode(AlpacaLatestQuote.self, from: data)
        return result.quote.ap 
    }
    
    // MARK: - Rebalancing API (Server-Side Auto-Invest)
    // Uses Alpaca's beta rebalancing endpoints for automatic portfolio management.
    // See: https://alpaca.markets/learn/how-to-get-started-with-rebalancing-api
    
    private let rebalancingBaseURL = AppConfig.Alpaca.rebalancingBaseURL
    
    /// Creates a rebalancing portfolio on Alpaca that matches our RiskLevel portfolio
    func createRebalancingPortfolio(portfolio: RiskLevel) async throws -> String {
        // Check if Rebalancing API is enabled
        guard AppConfig.Alpaca.rebalancingAPIEnabled else {
            throw RebalancingAPIError.featureNotEnabled
        }
        
        print("📊 Creating rebalancing portfolio: \(portfolio.title)")
        
        let url = URL(string: "\(rebalancingBaseURL)/portfolios")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        // Build weights from portfolio allocations
        var weights: [[String: Any]] = []
        for allocation in portfolio.allocations {
            weights.append([
                "type": "asset",
                "symbol": allocation.ticker,
                "percent": String(format: "%.0f", allocation.percentage * 100)
            ])
        }
        
        let body: [String: Any] = [
            "name": "Fursa_\(portfolio.rawValue)",
            "description": portfolio.description,
            "weights": weights,
            "cooldown_days": 1,  // Minimum days between rebalances
            "rebalance_conditions": [
                [
                    "type": "drift_band",
                    "sub_type": "absolute",
                    "percent": "5"  // Rebalance if drift exceeds 5%
                ],
                [
                    "type": "calendar",
                    "sub_type": "weekly",
                    "day": "monday"
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Create Portfolio Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        
        // Parse response to get portfolio ID
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let portfolioId = json["id"] as? String {
            print("✅ Created rebalancing portfolio: \(portfolioId)")
            return portfolioId
        }
        
        throw NSError(domain: "RebalancingAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse portfolio ID"])
    }
    
    /// Gets existing rebalancing portfolio by name, or creates one if it doesn't exist
    func getOrCreateRebalancingPortfolio(portfolio: RiskLevel) async throws -> String {
        let portfolioName = "Fursa_\(portfolio.rawValue)"
        
        // First, try to find existing portfolio
        let url = URL(string: "\(rebalancingBaseURL)/portfolios")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        if let portfolios = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            if let existing = portfolios.first(where: { ($0["name"] as? String) == portfolioName }),
               let portfolioId = existing["id"] as? String {
                print("✅ Found existing rebalancing portfolio: \(portfolioId)")
                return portfolioId
            }
        }
        
        // Portfolio doesn't exist, create it
        return try await createRebalancingPortfolio(portfolio: portfolio)
    }
    
    /// Subscribes an account to a rebalancing portfolio for auto-invest
    func subscribeAccountToPortfolio(accountId: String, portfolioId: String) async throws {
        print("📝 Subscribing account \(accountId) to portfolio \(portfolioId)")
        
        let url = URL(string: "\(rebalancingBaseURL)/subscriptions")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "account_id": accountId,
            "portfolio_id": portfolioId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Subscription Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        print("✅ Account subscribed to rebalancing portfolio")
    }
    
    /// Checks if an account is subscribed to any rebalancing portfolio
    func getAccountSubscription(accountId: String) async throws -> (subscriptionId: String, portfolioId: String)? {
        let url = URL(string: "\(rebalancingBaseURL)/subscriptions?account_id=\(accountId)")!
        let request = try createBrokerRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        if let subscriptions = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let subscription = subscriptions.first,
           let subscriptionId = subscription["id"] as? String,
           let portfolioId = subscription["portfolio_id"] as? String {
            return (subscriptionId, portfolioId)
        }
        
        return nil
    }
    
    /// Removes an account's subscription to allow manual trading or switch portfolios
    func unsubscribeAccount(subscriptionId: String) async throws {
        print("🗑️ Removing subscription: \(subscriptionId)")
        
        let url = URL(string: "\(rebalancingBaseURL)/subscriptions/\(subscriptionId)")!
        let request = try createBrokerRequest(url: url, method: "DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        print("✅ Subscription removed")
    }
    
    /// Triggers an immediate rebalance/invest run for an account
    func triggerInvestRun(accountId: String, portfolioId: String) async throws {
        print("🚀 Triggering invest run for account \(accountId)")
        
        let url = URL(string: "\(rebalancingBaseURL)/runs")!
        var request = try createBrokerRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "account_id": accountId,
            "portfolio_id": portfolioId,
            "type": "full_rebalance"  // Invests all available cash
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Invest Run Response: \(responseString)")
        }
        
        try validateResponse(response, data: data)
        print("✅ Invest run triggered")
    }
    
    /// Sets up complete auto-invest for an account with a portfolio using Alpaca's Rebalancing API
    /// Call this when user selects a portfolio
    /// See: https://alpaca.markets/learn/how-to-get-started-with-rebalancing-api
    func setupAutoInvest(accountId: String, portfolio: RiskLevel) async throws {
        // Check if Rebalancing API is enabled in config
        guard AppConfig.Alpaca.rebalancingAPIEnabled else {
            throw RebalancingAPIError.featureNotEnabled
        }
        
        print("⚙️ Setting up Rebalancing API auto-invest for \(portfolio.title)")
        
        // 1. Check if already subscribed to a different portfolio
        if let existingSubscription = try await getAccountSubscription(accountId: accountId) {
            // Unsubscribe from old portfolio
            try await unsubscribeAccount(subscriptionId: existingSubscription.subscriptionId)
        }
        
        // 2. Get or create the rebalancing portfolio
        let portfolioId = try await getOrCreateRebalancingPortfolio(portfolio: portfolio)
        
        // 3. Subscribe the account
        try await subscribeAccountToPortfolio(accountId: accountId, portfolioId: portfolioId)
        
        // 4. Trigger immediate invest if there's cash available
        let account = try await fetchAccountDetails(accountId: accountId)
        if account.cashValue >= 1.0 {
            try await triggerInvestRun(accountId: accountId, portfolioId: portfolioId)
        }
        
        print("✅ Rebalancing API auto-invest setup complete for \(portfolio.title)")
    }
    
    // MARK: - Helpers
    
    private func createBrokerRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Broker API uses Basic Auth
        let loginString = "\(apiKey):\(apiSecret)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlpacaAPIError.networkError("Invalid response from server")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("--------------------------------------------------")
            print("Alpaca API Error (Status \(httpResponse.statusCode)):")
            print(errorString)
            print("Request URL: \(response.url?.absoluteString ?? "Unknown")")
            print("--------------------------------------------------")
            
            // Parse Alpaca error response for specific error handling
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Decoded Error: \(errorJson)")
                
                // Check for Alpaca-specific error codes
                if let code = errorJson["code"] as? Int {
                    throw parseAlpacaErrorCode(code, message: errorJson["message"] as? String, statusCode: httpResponse.statusCode)
                }
                
                // Check for error message patterns
                if let message = errorJson["message"] as? String {
                    throw parseAlpacaErrorMessage(message, statusCode: httpResponse.statusCode)
                }
            }
            
            // Fallback to HTTP status code based errors
            throw mapHTTPStatusToError(httpResponse.statusCode)
        }
    }
    
    /// Parse Alpaca-specific error codes into typed errors
    private func parseAlpacaErrorCode(_ code: Int, message: String?, statusCode: Int) -> AlpacaAPIError {
        switch code {
        // Account creation errors (400xx codes)
        case 40010001:
            return .duplicateEmail
        case 40010002:
            return .invalidSSN
        case 40010003:
            return .invalidTaxId(message ?? "Tax ID is invalid")
        case 40010004:
            return .invalidDateOfBirth
        case 40010005:
            return .underageUser
        case 40010010:
            return .accountAlreadyExists
        case 40010011:
            return .invalidAddress(message ?? "Address validation failed")
            
        // Document errors
        case 40020001:
            return .documentRequired(message ?? "Document is required")
        case 40020002:
            return .invalidDocumentFormat
        case 40020003:
            return .documentTooLarge
            
        // Trading errors
        case 40030001:
            return .insufficientFunds
        case 40030002:
            return .tradingNotAllowed(message ?? "Trading is not allowed")
        case 40030003:
            return .marketClosed
            
        // Rate limiting
        case 42900001:
            return .rateLimited
            
        // Server errors
        case 50000001...50099999:
            return .serverError(message ?? "Internal server error")
            
        default:
            return .unknownError(code: code, message: message ?? "Unknown error")
        }
    }
    
    /// Parse error message patterns for common Alpaca errors
    private func parseAlpacaErrorMessage(_ message: String, statusCode: Int) -> AlpacaAPIError {
        let lowercased = message.lowercased()
        
        // Duplicate email detection
        if lowercased.contains("email") && (lowercased.contains("duplicate") || lowercased.contains("already exists") || lowercased.contains("already registered")) {
            return .duplicateEmail
        }
        
        // SSN errors
        if lowercased.contains("ssn") || lowercased.contains("tax_id") {
            if lowercased.contains("invalid") || lowercased.contains("incorrect") {
                return .invalidSSN
            }
            if lowercased.contains("duplicate") || lowercased.contains("already") {
                return .duplicateSSN
            }
        }
        
        // Account rejection
        if lowercased.contains("reject") || lowercased.contains("denied") {
            return .accountRejected(reason: message)
        }
        
        // Rate limiting
        if lowercased.contains("rate limit") || lowercased.contains("too many") {
            return .rateLimited
        }
        
        // Insufficient funds
        if lowercased.contains("insufficient") && lowercased.contains("fund") {
            return .insufficientFunds
        }
        
        // Default based on status code
        return mapHTTPStatusToError(statusCode, message: message)
    }
    
    /// Map HTTP status codes to appropriate errors
    private func mapHTTPStatusToError(_ statusCode: Int, message: String? = nil) -> AlpacaAPIError {
        switch statusCode {
        case 400:
            return .badRequest(message ?? "Invalid request")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden(message ?? "Access denied")
        case 404:
            return .notFound(message ?? "Resource not found")
        case 409:
            return .conflict(message ?? "Conflict with existing data")
        case 422:
            return .validationFailed(message ?? "Validation failed")
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError(message ?? "Server error. Please try again later.")
        default:
            return .networkError(message ?? "Request failed with status \(statusCode)")
        }
    }
    
    // MARK: - Helper Methods for KYC Account Creation
    
    /// Formats date for Alpaca API (YYYY-MM-DD)
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Formats phone number to E.164 format based on country
    /// Default country is Kuwait (KWT) for this app's target users
    private func formatPhoneNumber(_ phone: String, country: String = "KWT") -> String {
        let cleaned = phone.trimmingCharacters(in: .whitespaces)
        
        // If already has + prefix, validate and return
        if cleaned.hasPrefix("+") {
            let digits = String(cleaned.dropFirst().filter { $0.isNumber })
            return "+\(digits)"
        }
        
        // Remove all non-digits
        let digits = String(cleaned.filter { $0.isNumber })
        
        // Handle based on country
        switch country.uppercased() {
        case "KWT":
            // Kuwait: 8 digits, country code +965
            if digits.count == 8 {
                return "+965\(digits)"
            }
            if digits.count == 11 && digits.hasPrefix("965") {
                return "+\(digits)"
            }
            
        case "USA":
            // US: 10 digits, country code +1
            if digits.count == 10 {
                return "+1\(digits)"
            }
            if digits.count == 11 && digits.hasPrefix("1") {
                return "+\(digits)"
            }
            
        case "SAU":
            // Saudi Arabia: 9 digits (without leading 0), country code +966
            if digits.count == 9 && digits.hasPrefix("5") {
                return "+966\(digits)"
            }
            if digits.count == 10 && digits.hasPrefix("05") {
                let withoutLeadingZero = String(digits.dropFirst())
                return "+966\(withoutLeadingZero)"
            }
            
        case "ARE":
            // UAE: 9 digits, country code +971
            if digits.count == 9 && digits.hasPrefix("5") {
                return "+971\(digits)"
            }
            
        case "QAT":
            // Qatar: 8 digits, country code +974
            if digits.count == 8 {
                return "+974\(digits)"
            }
            
        case "BHR":
            // Bahrain: 8 digits, country code +973
            if digits.count == 8 {
                return "+973\(digits)"
            }
            
        case "OMN":
            // Oman: 8 digits, country code +968
            if digits.count == 8 {
                return "+968\(digits)"
            }
            
        default:
            break
        }
        
        // Fallback: detect known country codes
        if digits.hasPrefix("965") && digits.count == 11 {
            return "+\(digits)" // Kuwait with country code
        }
        if digits.hasPrefix("1") && digits.count == 11 {
            return "+\(digits)" // US with country code
        }
        
        // Default: assume Kuwait for 8 digits
        if digits.count == 8 {
            return "+965\(digits)"
        }
        
        // Otherwise just add + prefix
        return "+\(digits)"
    }
    
    /// Cleans tax ID by removing formatting
    private func cleanTaxId(_ taxId: String) -> String {
        return taxId.filter { $0.isNumber }
    }
    
    /// Builds trusted contact from registration data
    private func buildTrustedContact(from data: KYCRegistrationData) -> AlpacaTrustedContact? {
        guard let name = data.trustedContactName, !name.isEmpty else {
            return nil
        }
        
        let nameParts = name.components(separatedBy: " ")
        let firstName = nameParts.first ?? name
        let lastName = nameParts.dropFirst().joined(separator: " ")
        
        return AlpacaTrustedContact(
            given_name: firstName,
            family_name: lastName.isEmpty ? firstName : lastName,
            email_address: data.trustedContactEmail,
            phone_number: data.trustedContactPhone
        )
    }
    
    /// Redacts sensitive information from log output
    private func redactSensitiveInfo(_ input: String) -> String {
        var output = input
        
        // Redact tax_id (SSN/ITIN)
        let ssnPattern = #"\"tax_id\"\s*:\s*\"[^\"]+\""#
        if let regex = try? NSRegularExpression(pattern: ssnPattern) {
            output = regex.stringByReplacingMatches(
                in: output,
                range: NSRange(output.startIndex..., in: output),
                withTemplate: "\"tax_id\": \"***REDACTED***\""
            )
        }
        
        // Redact date_of_birth
        let dobPattern = #"\"date_of_birth\"\s*:\s*\"[^\"]+\""#
        if let regex = try? NSRegularExpression(pattern: dobPattern) {
            output = regex.stringByReplacingMatches(
                in: output,
                range: NSRange(output.startIndex..., in: output),
                withTemplate: "\"date_of_birth\": \"****-**-**\""
            )
        }
        
        return output
    }
}

// MARK: - Supporting Types

// MARK: - Alpaca API Error

/// Comprehensive error types for Alpaca API responses
/// Provides user-friendly error messages for common failure scenarios
enum AlpacaAPIError: Error, LocalizedError {
    // Account creation errors
    case duplicateEmail
    case duplicateSSN
    case invalidSSN
    case invalidTaxId(String)
    case invalidDateOfBirth
    case underageUser
    case accountAlreadyExists
    case invalidAddress(String)
    case accountRejected(reason: String)
    
    // Document errors
    case documentRequired(String)
    case invalidDocumentFormat
    case documentTooLarge
    
    // Trading errors
    case insufficientFunds
    case tradingNotAllowed(String)
    case marketClosed
    
    // HTTP/Network errors
    case badRequest(String)
    case unauthorized
    case forbidden(String)
    case notFound(String)
    case conflict(String)
    case validationFailed(String)
    case rateLimited
    case serverError(String)
    case networkError(String)
    
    // Generic errors
    case unknownError(code: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        // Account creation errors
        case .duplicateEmail:
            return "An account with this email already exists. Please sign in or use a different email."
        case .duplicateSSN:
            return "An account with this SSN/Tax ID already exists."
        case .invalidSSN:
            return "The SSN provided is invalid. Please check and try again."
        case .invalidTaxId(let detail):
            return "Tax ID validation failed: \(detail)"
        case .invalidDateOfBirth:
            return "The date of birth provided is invalid."
        case .underageUser:
            return "You must be at least 18 years old to open an account."
        case .accountAlreadyExists:
            return "An account already exists with this information."
        case .invalidAddress(let detail):
            return "Address validation failed: \(detail)"
        case .accountRejected(let reason):
            return "Account application was rejected: \(reason)"
            
        // Document errors
        case .documentRequired(let type):
            return "Required document missing: \(type)"
        case .invalidDocumentFormat:
            return "Document format is not supported. Please use JPEG, PNG, or PDF."
        case .documentTooLarge:
            return "Document file is too large. Maximum size is 5MB."
            
        // Trading errors
        case .insufficientFunds:
            return "Insufficient funds to complete this transaction."
        case .tradingNotAllowed(let reason):
            return "Trading is not allowed: \(reason)"
        case .marketClosed:
            return "The market is currently closed. Please try again during market hours."
            
        // HTTP/Network errors
        case .badRequest(let detail):
            return "Invalid request: \(detail)"
        case .unauthorized:
            return "Authentication failed. Please sign in again."
        case .forbidden(let detail):
            return "Access denied: \(detail)"
        case .notFound(let detail):
            return "Not found: \(detail)"
        case .conflict(let detail):
            return "Conflict: \(detail)"
        case .validationFailed(let detail):
            return "Validation failed: \(detail)"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let detail):
            return "Server error: \(detail)"
        case .networkError(let detail):
            return "Network error: \(detail)"
            
        // Generic errors
        case .unknownError(let code, let message):
            return "Error (\(code)): \(message)"
        }
    }
    
    /// Whether this error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .rateLimited, .serverError, .networkError, .marketClosed:
            return true
        default:
            return false
        }
    }
    
    /// Whether this error should prompt the user to check their input
    var requiresUserAction: Bool {
        switch self {
        case .duplicateEmail, .duplicateSSN, .invalidSSN, .invalidTaxId,
             .invalidDateOfBirth, .underageUser, .invalidAddress,
             .documentRequired, .invalidDocumentFormat, .documentTooLarge,
             .insufficientFunds:
            return true
        default:
            return false
        }
    }
    
    /// Suggested action for the user
    var suggestedAction: String {
        switch self {
        case .duplicateEmail:
            return "Try signing in instead, or use a different email address."
        case .duplicateSSN, .invalidSSN:
            return "Double-check your SSN/Tax ID and try again."
        case .invalidAddress:
            return "Verify your address information is correct."
        case .insufficientFunds:
            return "Add funds to your account and try again."
        case .rateLimited:
            return "Please wait a few minutes before trying again."
        case .serverError, .networkError:
            return "Check your internet connection and try again."
        case .documentRequired, .invalidDocumentFormat, .documentTooLarge:
            return "Please upload a valid document."
        default:
            return "Please try again or contact support if the issue persists."
        }
    }
}

/// Errors specific to the Rebalancing API
enum RebalancingAPIError: Error, LocalizedError {
    case featureNotEnabled
    case insufficientPermissions
    case portfolioNotFound
    case subscriptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .featureNotEnabled:
            return "Rebalancing API is not enabled. Using client-side auto-invest instead."
        case .insufficientPermissions:
            return "Your Alpaca account doesn't have Rebalancing API permissions. Contact Alpaca support to enable this feature."
        case .portfolioNotFound:
            return "Rebalancing portfolio not found."
        case .subscriptionFailed(let message):
            return "Failed to subscribe to portfolio: \(message)"
        }
    }
}

/// Document side for multi-page documents
enum DocumentSide: String {
    case front = "front"
    case back = "back"
}

/// Errors specific to document upload
enum DocumentUploadError: Error, LocalizedError {
    case invalidImageFormat
    case compressionFailed
    case fileTooLarge(maxSize: Int)
    case uploadFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageFormat:
            return "The image format is not supported. Please use JPEG, PNG, or PDF."
        case .compressionFailed:
            return "Failed to compress the image."
        case .fileTooLarge(let maxSize):
            let maxMB = maxSize / (1024 * 1024)
            return "The file is too large. Maximum size is \(maxMB)MB."
        case .uploadFailed(let message):
            return message
        }
    }
}

/// Actions to take based on account status
enum AccountStatusAction {
    case showPendingVerification(message: String)
    case showRequiredActions(actions: [AlpacaAccountCreationResult.RequiredAction])
    case proceedToOnboarding(accountId: String)
    case showRejection(reasons: [String], canAppeal: Bool)

    var title: String {
        switch self {
        case .showPendingVerification:
            return "Verification in Progress"
        case .showRequiredActions:
            return "Action Required"
        case .proceedToOnboarding:
            return "Account Approved"
        case .showRejection:
            return "Application Status"
        }
    }
}

// MARK: - Withdrawal Types

/// Represents a linked bank account for withdrawals
struct LinkedBankAccount {
    let id: String
    let nickname: String
    let bankAccountType: String
    let maskedAccountNumber: String
    let status: String

    var displayName: String {
        if nickname.isEmpty {
            return "\(bankAccountType.capitalized) \(maskedAccountNumber)"
        }
        return "\(nickname) \(maskedAccountNumber)"
    }

    var accountTypeDisplayName: String {
        switch bankAccountType.uppercased() {
        case "CHECKING": return "Checking"
        case "SAVINGS": return "Savings"
        default: return bankAccountType.capitalized
        }
    }

    var isActive: Bool {
        status.uppercased() == "APPROVED" || status.uppercased() == "ACTIVE"
    }
}

/// Result returned after successful withdrawal initiation
struct WithdrawalResult {
    let transferId: String
    let amount: Double
    let status: String
    let bankAccountNickname: String
    let maskedBankAccount: String
    let estimatedArrival: String

    var formattedAmount: String {
        "$\(String(format: "%.2f", amount))"
    }

    var statusDisplayName: String {
        switch status.uppercased() {
        case "QUEUED": return "Queued"
        case "PENDING": return "Pending"
        case "SENT_TO_CLEARING": return "Processing"
        case "APPROVED": return "Approved"
        case "COMPLETE": return "Complete"
        case "CANCELED", "CANCELLED": return "Cancelled"
        case "RETURNED": return "Returned"
        default: return status.capitalized
        }
    }
}

/// Errors specific to withdrawal operations
enum WithdrawalError: Error, LocalizedError {
    case invalidAmount
    case belowMinimum(minimum: Double)
    case insufficientFunds(available: Double, requested: Double)
    case noBankAccountLinked
    case bankAccountNotApproved(status: String)
    case withdrawalFailed(message: String)
    case transferCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid withdrawal amount."
        case .belowMinimum(let minimum):
            return "Minimum withdrawal amount is $\(String(format: "%.2f", minimum))."
        case .insufficientFunds(let available, let requested):
            return "Insufficient funds. You requested $\(String(format: "%.2f", requested)) but only $\(String(format: "%.2f", available)) is available."
        case .noBankAccountLinked:
            return "No bank account linked. Please link a bank account first to withdraw funds."
        case .bankAccountNotApproved(let status):
            return "Your linked bank account is not approved yet (status: \(status)). Please wait for approval or link a different account."
        case .withdrawalFailed(let message):
            return "Withdrawal failed: \(message)"
        case .transferCreationFailed:
            return "Failed to create withdrawal transfer. Please try again."
        }
    }

    var suggestedAction: String {
        switch self {
        case .invalidAmount, .belowMinimum:
            return "Enter a valid amount above the minimum."
        case .insufficientFunds:
            return "Reduce the withdrawal amount or deposit more funds."
        case .noBankAccountLinked:
            return "Go to Settings > Bank Accounts to link a bank account."
        case .bankAccountNotApproved:
            return "Wait for bank account approval or link a different account."
        case .withdrawalFailed, .transferCreationFailed:
            return "Please try again later or contact support."
        }
    }
}

// MARK: - Net Worth Range Extensions

extension NetWorthRange {
    var minValue: Int {
        switch self {
        case .under50k: return 0
        case .from50kTo100k: return 50001
        case .from100kTo250k: return 100001
        case .from250kTo500k: return 250001
        case .from500kTo1m: return 500001
        case .from1mTo5m: return 1000001
        case .over5m: return 5000001
        }
    }
    
    var maxValue: Int? {
        switch self {
        case .under50k: return 50000
        case .from50kTo100k: return 100000
        case .from100kTo250k: return 250000
        case .from250kTo500k: return 500000
        case .from500kTo1m: return 1000000
        case .from1mTo5m: return 5000000
        case .over5m: return nil
        }
    }
}

extension LiquidNetWorthRange {
    var minValue: Int {
        switch self {
        case .under25k: return 0
        case .from25kTo50k: return 25001
        case .from50kTo100k: return 50001
        case .from100kTo250k: return 100001
        case .from250kTo500k: return 250001
        case .from500kTo1m: return 500001
        case .over1m: return 1000001
        }
    }
    
    var maxValue: Int? {
        switch self {
        case .under25k: return 25000
        case .from25kTo50k: return 50000
        case .from50kTo100k: return 100000
        case .from100kTo250k: return 250000
        case .from250kTo500k: return 500000
        case .from500kTo1m: return 1000000
        case .over1m: return nil
        }
    }
}
