import Foundation
import Photos

class MinIOService {
    let serverURL: String
    let accessKey: String
    let secretKey: String
    let bucketName: String
    
    init(serverURL: String, accessKey: String, secretKey: String, bucketName: String) {
        self.serverURL = serverURL
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.bucketName = bucketName
    }
    
    // List all photos in the MinIO bucket
    func listPhotos(completion: @escaping ([MinIOPhoto]) -> Void) {
        guard let url = URL(string: "\(serverURL)/\(bucketName)?list-type=2") else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers
        addAuthHeaders(to: &request)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching MinIO photos: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            // Parse XML response from MinIO
            // In a real app, you would use a proper XML parser
            // For this example, we'll simulate the parsing
            
            let photos = self.parseListObjectsResponse(data: data)
            completion(photos)
        }
        
        task.resume()
    }
    
    // Upload a photo to MinIO
    func uploadPhoto(asset: PHAsset, photoID: String, checksum: String?, completion: @escaping (Bool) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, _, _, _ in
            guard let self = self, let imageData = data else {
                completion(false)
                return
            }
            
            self.uploadData(imageData, photoID: photoID, checksum: checksum, completion: completion)
        }
    }
    
    // Upload data to MinIO
    private func uploadData(_ data: Data, photoID: String, checksum: String?, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/\(bucketName)/\(photoID).jpg") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        // Add content type header
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        // Add checksum header if available
        if let checksum = checksum {
            request.setValue(checksum, forHTTPHeaderField: "x-amz-meta-checksum")
        }
        
        // Add last modified date
        let dateFormatter = ISO8601DateFormatter()
        request.setValue(dateFormatter.string(from: Date()), forHTTPHeaderField: "x-amz-meta-last-modified")
        
        // Add authentication headers
        addAuthHeaders(to: &request)
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error uploading photo: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(true)
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
    
    // Delete a photo from MinIO
    func deletePhoto(photoID: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/\(bucketName)/\(photoID).jpg") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add authentication headers
        addAuthHeaders(to: &request)
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error deleting photo: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(true)
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
    
    // Parse the XML response from MinIO list objects API
    private func parseListObjectsResponse(data: Data) -> [MinIOPhoto] {
        let parser = MinIOXMLParser()
        let objects = parser.parse(data: data)
        
        return objects.map { $0.toMinIOPhoto(baseURL: serverURL, bucketName: bucketName) }
    }
    
    // Add authentication headers to the request
    private func addAuthHeaders(to request: inout URLRequest) {
        let signature = AWSV4Signature(
            accessKey: accessKey,
            secretKey: secretKey,
            regionName: "us-east-1", // Default region, can be configured
            serviceName: "s3"
        )
        
        signature.sign(request: &request)
    }
}

// Extension to integrate MinIOService with PhotoSyncViewModel
extension PhotoSyncViewModel {
    func createMinIOService() -> MinIOService {
        return MinIOService(
            serverURL: serverURL,
            accessKey: accessKey,
            secretKey: secretKey,
            bucketName: bucketName
        )
    }
    
    // Update the loadMinIOPhotos method to use MinIOService
    func loadMinIOPhotosWithService() {
        guard !serverURL.isEmpty, !accessKey.isEmpty, !secretKey.isEmpty, !bucketName.isEmpty else {
            return
        }
        
        isLoadingMinIO = true
        
        let service = createMinIOService()
        service.listPhotos { [weak self] photos in
            DispatchQueue.main.async {
                self?.minioPhotos = photos
                self?.isLoadingMinIO = false
                self?.checkSyncStatus()
            }
        }
    }
    
    // Update the syncPhotos method to use MinIOService
    func syncPhotosWithService() {
        guard !serverURL.isEmpty, !accessKey.isEmpty, !secretKey.isEmpty, !bucketName.isEmpty else {
            return
        }
        
        isSyncing = true
        
        // Filter photos that need to be synced
        let photosToSync = localPhotos.filter { $0.syncStatus != .synced }
        
        let service = createMinIOService()
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<photosToSync.count {
            let index = localPhotos.firstIndex { $0.id == photosToSync[i].id } ?? 0
            
            dispatchGroup.enter()
            
            // Update status to syncing
            DispatchQueue.main.async {
                self.localPhotos[index].syncStatus = .syncing
            }
            
            // Calculate checksum for the photo
            calculateChecksum(for: photosToSync[i].asset) { [weak self] checksum in
                guard let self = self else { 
                    dispatchGroup.leave()
                    return 
                }
                
                // Upload the photo to MinIO
                service.uploadPhoto(asset: photosToSync[i].asset, photoID: photosToSync[i].id, checksum: checksum) { success in
                    DispatchQueue.main.async {
                        if let index = self.localPhotos.firstIndex(where: { $0.id == photosToSync[i].id }) {
                            self.localPhotos[index].syncStatus = success ? .synced : .failed
                            self.localPhotos[index].checksum = checksum
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.isSyncing = false
            self?.loadMinIOPhotosWithService() // Refresh MinIO photos after sync
        }
    }
}
