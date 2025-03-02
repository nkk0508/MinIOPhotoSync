import Foundation
import SwiftUI

enum AppError: Error {
    case photoLibraryAccess
    case minioConnection
    case uploadFailed
    case downloadFailed
    case invalidConfiguration
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .photoLibraryAccess:
            return "Cannot access photo library. Please check permissions in Settings."
        case .minioConnection:
            return "Cannot connect to MinIO server. Please check your connection and server settings."
        case .uploadFailed:
            return "Failed to upload photo to MinIO server."
        case .downloadFailed:
            return "Failed to download photo from MinIO server."
        case .invalidConfiguration:
            return "Invalid MinIO server configuration. Please check your settings."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

struct ErrorAlert: Identifiable {
    let id = UUID()
    let error: AppError
    let message: String
    
    init(error: AppError, message: String? = nil) {
        self.error = error
        self.message = message ?? error.localizedDescription
    }
}

class ErrorHandler: ObservableObject {
    @Published var currentAlert: ErrorAlert?
    
    func handle(_ error: AppError, message: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.currentAlert = ErrorAlert(error: error, message: message)
        }
    }
    
    func handle(_ error: Error) {
        let appError: AppError
        
        if let error = error as? AppError {
            appError = error
        } else {
            appError = .unknown
        }
        
        handle(appError, message: error.localizedDescription)
    }
    
    func dismiss() {
        currentAlert = nil
    }
}

// Extension to use ErrorHandler in SwiftUI views
extension View {
    func errorAlert(errorHandler: ErrorHandler) -> some View {
        self.alert(
            "Error",
            isPresented: Binding<Bool>(
                get: { errorHandler.currentAlert != nil },
                set: { if !$0 { errorHandler.dismiss() } }
            ),
            presenting: errorHandler.currentAlert
        ) { _ in
            Button("OK") {
                errorHandler.dismiss()
            }
        } message: { alert in
            Text(alert.message)
        }
    }
}
