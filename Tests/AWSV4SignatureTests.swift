import XCTest
@testable import MinIOPhotoSync

class AWSV4SignatureTests: XCTestCase {
    var signature: AWSV4Signature!
    
    override func setUp() {
        super.setUp()
        signature = AWSV4Signature(
            accessKey: "AKIAIOSFODNN7EXAMPLE",
            secretKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            regionName: "us-east-1",
            serviceName: "s3"
        )
    }
    
    override func tearDown() {
        signature = nil
        super.tearDown()
    }
    
    func testSignRequest() {
        // Given
        let url = URL(string: "https://minio.example.com/testbucket/test.jpg")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        // Use a fixed date for testing to get a deterministic signature
        let fixedDate = ISO8601DateFormatter().date(from: "2023-01-01T12:00:00Z")!
        
        // When
        signature.sign(request: &request, date: fixedDate)
        
        // Then
        XCTAssertNotNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertNotNil(request.value(forHTTPHeaderField: "X-Amz-Date"))
        
        // The exact signature would depend on the implementation details
        // In a real test, you might compare against a known good signature
        // or verify that the signature format is correct
        let authHeader = request.value(forHTTPHeaderField: "Authorization") ?? ""
        XCTAssertTrue(authHeader.hasPrefix("AWS4-HMAC-SHA256 Credential="))
        XCTAssertTrue(authHeader.contains("SignedHeaders="))
        XCTAssertTrue(authHeader.contains("Signature="))
    }
}