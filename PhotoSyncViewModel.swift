import Foundation
import Photos
import UIKit

enum SyncStatus {
    case notSynced
    case syncing
    case synced
    case failed
}

struct LocalPhoto: Identifiable {
    let id: String
    let asset: PHAsset
    let thumbnail: UIImage
    var syncStatus: SyncStatus = .notSynced
    var lastModifiedDate: Date
    var checksum: String?
}

struct MinIOPhoto: Identifiable {
    let id: String
    let url: URL
    let lastModifiedDate: Date
    let checksum: String?
}

class PhotoSyncViewModel: ObservableObject {
    @Published var localPhotos: [LocalPhoto] = []
    @Published var minioPhotos: [MinIOPhoto] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var isLoadingMinIO = false
    
    // MinIO Configuration
    @Published var serverURL: String = UserDefaults.standard.string(forKey: "serverURL") ?? ""
    @Published var accessKey: String = UserDefaults.standard.string(forKey: "accessKey") ?? ""
    @Published var secretKey: String = UserDefaults.standard.string(forKey: "secretKey") ?? ""
    @Published var bucketName: String = UserDefaults.standard.string(forKey: "bucketName") ?? ""
    
    // Error handling
    let errorHandler = ErrorHandler()
    
    private let imageManager = PHImageManager.default()
    private let thumbnailSize = CGSize(width: 200, height: 200)
    
    func saveSettings() {
        UserDefaults.standard.set(serverURL, forKey: "serverURL")
        UserDefaults.standard.set(accessKey, forKey: "accessKey")
        UserDefaults.standard.set(secretKey, forKey: "secretKey")
        UserDefaults.standard.set(bucketName, forKey: "bucketName")
    }
    
    func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.loadLocalPhotos()
                } else {
                    self?.errorHandler.handle(.photoLibraryAccess)
                }
            }
        }
    }
    
    func loadLocalPhotos() {
        isLoading = true
        localPhotos = []
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<assets.count {
            dispatchGroup.enter()
            
            let asset = assets[i]
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            
            imageManager.requestImage(for: asset, 
                                     targetSize: thumbnailSize,
                                     contentMode: .aspectFill,
                                     options: options) { [weak self] image, _ in
                if let image = image {
                    let localPhoto = LocalPhoto(
                        id: asset.localIdentifier,
                        asset: asset,
                        thumbnail: image,
                        lastModifiedDate: asset.modificationDate ?? asset.creationDate ?? Date()
                    )
                    
                    DispatchQueue.main.async {
                        self?.localPhotos.append(localPhoto)
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.checkSyncStatus()
        }
    }
    
    func loadMinIOPhotos() {
        guard !serverURL.isEmpty, !accessKey.isEmpty, !secretKey.isEmpty, !bucketName.isEmpty else {
            errorHandler.handle(.invalidConfiguration)
            return
        }
        
        isLoadingMinIO = true
        minioPhotos = []
        
        // In a real app, you would use the MinIO SDK to list objects in the bucket
        // For this example, we'll simulate the API call
        
        // Simulated API call to MinIO
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            // This would be replaced with actual MinIO SDK code
            let simulatedPhotos: [MinIOPhoto] = []
            
            DispatchQueue.main.async {
                self?.minioPhotos = simulatedPhotos
                self?.isLoadingMinIO = false
                self?.checkSyncStatus()
            }
        }
    }
    
    func refreshMinIOPhotos() {
        loadMinIOPhotos()
    }
    
    func checkSyncStatus() {
        // Create a dictionary of MinIO photos by their ID for quick lookup
        let minioDict = Dictionary(uniqueKeysWithValues: minioPhotos.map { ($0.id, $0) })
        
        // Update sync status for each local photo
        for i in 0..<localPhotos.count {
            if let minioPhoto = minioDict[localPhotos[i].id] {
                // Check if the photo has been modified since last sync
                if localPhotos[i].lastModifiedDate <= minioPhoto.lastModifiedDate {
                    // Photo is already synced and not modified
                    localPhotos[i].syncStatus = .synced
                } else {
                    // Photo has been modified and needs to be re-synced
                    localPhotos[i].syncStatus = .notSynced
                }
            } else {
                // Photo is not on MinIO
                localPhotos[i].syncStatus = .notSynced
            }
        }
    }
    
    func calculateChecksum(for asset: PHAsset, completion: @escaping (String?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        
        imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            
            // Use our Swift wrapper for SHA256 hash
            let hashData = data.sha256()
            let hashString = hashData.hexString()
            completion(hashString)
        }
    }
    
    func syncPhotos() {
        guard !serverURL.isEmpty, !accessKey.isEmpty, !secretKey.isEmpty, !bucketName.isEmpty else {
            errorHandler.handle(.invalidConfiguration)
            return
        }
        
        isSyncing = true
        
        // Filter photos that need to be synced
        let photosToSync = localPhotos.filter { $0.syncStatus != .synced }
        
        if photosToSync.isEmpty {
            isSyncing = false
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var syncedCount = 0
        var failedCount = 0
        
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
                
                // In a real app, you would use the MinIO SDK to upload the photo
                // For this example, we'll simulate the upload
                
                // Simulated upload to MinIO
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    // Simulate occasional failures for testing
                    let success = Int.random(in: 0..<10) != 0 // 90% success rate
                    
                    if success {
                        syncedCount += 1
                    } else {
                        failedCount += 1
                    }
                    
                    // Update status based on success or failure
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
            guard let self = self else { return }
            
            self.isSyncing = false
            
            // Report results
            if failedCount > 0 {
                let message = "Synced \(syncedCount) photos, but \(failedCount) failed. Please try again."
                self.errorHandler.handle(.uploadFailed, message: message)
            }
            
            self.loadMinIOPhotos() // Refresh MinIO photos after sync
        }
    }
}
