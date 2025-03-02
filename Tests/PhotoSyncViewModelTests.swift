import XCTest
@testable import MinIOPhotoSync

class PhotoSyncViewModelTests: XCTestCase {
    var viewModel: PhotoSyncViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = PhotoSyncViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testSaveSettings() {
        // Given
        let serverURL = "https://minio.example.com"
        let accessKey = "testAccessKey"
        let secretKey = "testSecretKey"
        let bucketName = "testBucket"
        
        // When
        viewModel.serverURL = serverURL
        viewModel.accessKey = accessKey
        viewModel.secretKey = secretKey
        viewModel.bucketName = bucketName
        viewModel.saveSettings()
        
        // Then
        XCTAssertEqual(UserDefaults.standard.string(forKey: "serverURL"), serverURL)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "accessKey"), accessKey)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "secretKey"), secretKey)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "bucketName"), bucketName)
    }
    
    func testCreateMinIOService() {
        // Given
        let serverURL = "https://minio.example.com"
        let accessKey = "testAccessKey"
        let secretKey = "testSecretKey"
        let bucketName = "testBucket"
        
        viewModel.serverURL = serverURL
        viewModel.accessKey = accessKey
        viewModel.secretKey = secretKey
        viewModel.bucketName = bucketName
        
        // When
        let service = viewModel.createMinIOService()
        
        // Then
        XCTAssertNotNil(service)
    }
    
    func testCheckSyncStatus() {
        // This is a more complex test that would require mocking the photo library
        // In a real test environment, you would create mock LocalPhoto and MinIOPhoto objects
        // and verify that the sync status is correctly updated
    }
}
