import SwiftUI
import Photos

struct PhotoDetailView: View {
    enum PhotoSource {
        case local(LocalPhoto)
        case minio(MinIOPhoto)
    }
    
    let photoSource: PhotoSource
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isShowingInfo = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Group {
                switch photoSource {
                case .local(let photo):
                    Image(uiImage: photo.thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(dragGesture)
                        .gesture(magnificationGesture)
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                        .onTapGesture(count: 1) {
                            withAnimation {
                                isShowingInfo.toggle()
                            }
                        }
                
                case .minio(let photo):
                    AsyncImage(url: photo.url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(dragGesture)
                                .gesture(magnificationGesture)
                                .onTapGesture(count: 2) {
                                    withAnimation {
                                        if scale > 1 {
                                            scale = 1
                                            offset = .zero
                                        } else {
                                            scale = 2
                                        }
                                    }
                                }
                                .onTapGesture(count: 1) {
                                    withAnimation {
                                        isShowingInfo.toggle()
                                    }
                                }
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .foregroundColor(.red)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            
            if isShowingInfo {
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            switch photoSource {
                            case .local(let photo):
                                Text("Photo ID: \(photo.id)")
                                Text("Sync Status: \(syncStatusText(photo.syncStatus))")
                                Text("Last Modified: \(formatDate(photo.lastModifiedDate))")
                                if let checksum = photo.checksum {
                                    Text("Checksum: \(checksum.prefix(10))...")
                                }
                            
                            case .minio(let photo):
                                Text("Photo ID: \(photo.id)")
                                Text("Last Modified: \(formatDate(photo.lastModifiedDate))")
                                if let checksum = photo.checksum {
                                    Text("Checksum: \(checksum.prefix(10))...")
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { value in
                lastOffset = offset
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = lastScale * value
            }
            .onEnded { value in
                lastScale = scale
            }
    }
    
    private func syncStatusText(_ status: SyncStatus) -> String {
        switch status {
        case .notSynced:
            return "Not Synced"
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .failed:
            return "Failed"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
