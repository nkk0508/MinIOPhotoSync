import Foundation
import CryptoKit

struct AWSV4Signature {
    private let accessKey: String
    private let secretKey: String
    private let regionName: String
    private let serviceName: String
    
    init(accessKey: String, secretKey: String, regionName: String = "us-east-1", serviceName: String = "s3") {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.regionName = regionName
        self.serviceName = serviceName
    }
    
    func sign(request: inout URLRequest, date: Date = Date()) {
        // Step 1: Create a canonical request
        let canonicalRequest = createCanonicalRequest(request: request)
        
        // Step 2: Create a string to sign
        let stringToSign = createStringToSign(canonicalRequest: canonicalRequest, date: date)
        
        // Step 3: Calculate the signature
        let signature = calculateSignature(stringToSign: stringToSign, date: date)
        
        // Step 4: Add the signature to the request
        addSignatureToRequest(request: &request, signature: signature, date: date)
    }
    
    private func createCanonicalRequest(request: URLRequest) -> String {
        guard let url = request.url, let method = request.httpMethod else {
            return ""
        }
        
        // HTTP method
        let httpMethod = method.uppercased()
        
        // Canonical URI
        let canonicalURI = url.path.isEmpty ? "/" : url.path
        
        // Canonical query string
        let canonicalQueryString = url.query ?? ""
        
        // Canonical headers
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["host"] = url.host
        
        let canonicalHeaders = headers.sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { "\($0.key.lowercased()):\($0.value)" }
            .joined(separator: "\n") + "\n"
        
        // Signed headers
        let signedHeaders = headers.keys
            .map { $0.lowercased() }
            .sorted()
            .joined(separator: ";")
        
        // Request payload
        let payload = request.httpBody ?? Data()
        let payloadHash = SHA256.hash(data: payload).compactMap { String(format: "%02x", $0) }.joined()
        
        // Combine to create canonical request
        let canonicalRequest = [
            httpMethod,
            canonicalURI,
            canonicalQueryString,
            canonicalHeaders,
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")
        
        return canonicalRequest
    }
    
    private func createStringToSign(canonicalRequest: String, date: Date) -> String {
        let algorithm = "AWS4-HMAC-SHA256"
        let requestDate = formattedDate(date)
        let credentialScope = "\(formattedDateShort(date))/\(regionName)/\(serviceName)/aws4_request"
        let hashedCanonicalRequest = SHA256.hash(data: canonicalRequest.data(using: .utf8)!)
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        return [
            algorithm,
            requestDate,
            credentialScope,
            hashedCanonicalRequest
        ].joined(separator: "\n")
    }
    
    private func calculateSignature(stringToSign: String, date: Date) -> String {
        let dateKey = hmacSHA256(key: "AWS4\(secretKey)".data(using: .utf8)!, data: formattedDateShort(date).data(using: .utf8)!)
        let regionKey = hmacSHA256(key: dateKey, data: regionName.data(using: .utf8)!)
        let serviceKey = hmacSHA256(key: regionKey, data: serviceName.data(using: .utf8)!)
        let signingKey = hmacSHA256(key: serviceKey, data: "aws4_request".data(using: .utf8)!)
        
        let signature = hmacSHA256(key: signingKey, data: stringToSign.data(using: .utf8)!)
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        return signature
    }
    
    private func addSignatureToRequest(request: inout URLRequest, signature: String, date: Date) {
        let algorithm = "AWS4-HMAC-SHA256"
        let requestDate = formattedDate(date)
        let credentialScope = "\(formattedDateShort(date))/\(regionName)/\(serviceName)/aws4_request"
        
        let signedHeaders = (request.allHTTPHeaderFields ?? [:])
            .keys
            .map { $0.lowercased() }
            .sorted()
            .joined(separator: ";")
        
        let authorizationHeader = [
            "AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope)",
            "SignedHeaders=\(signedHeaders)",
            "Signature=\(signature)"
        ].joined(separator: ", ")
        
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue(requestDate, forHTTPHeaderField: "X-Amz-Date")
    }
    
    private func hmacSHA256(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(hmac)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    private func formattedDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

// Update MinIOService to use AWSV4Signature
extension MinIOService {
    // Update the addAuthHeaders method to use AWSV4Signature
    func addAuthHeadersWithSignature(to request: inout URLRequest) {
        let signature = AWSV4Signature(
            accessKey: accessKey,
            secretKey: secretKey,
            regionName: "us-east-1", // Default region, can be configured
            serviceName: "s3"
        )
        
        signature.sign(request: &request)
    }
}