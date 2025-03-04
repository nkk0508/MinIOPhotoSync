import Foundation
import Photos
import UIKit

// 共通のモデル定義
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