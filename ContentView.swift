import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = PhotoSyncViewModel()
    @State private var showingImagePicker = false
    @State private var selectedTab = 0
    @ObservedObject private var errorHandler: ErrorHandler
    
    init() {
        let viewModel = PhotoSyncViewModel()
        _viewModel = StateObject(wrappedValue: viewModel)
        errorHandler = viewModel.errorHandler
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Local Photos Tab
            NavigationView {
                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading photos...")
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(viewModel.localPhotos) { photo in
                                    NavigationLink(destination: PhotoDetailView(photoSource: .local(photo))) {
                                        Image(uiImage: photo.thumbnail)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                            .overlay(
                                                photo.syncStatus == .synced ? 
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .padding(4)
                                                        .background(Circle().fill(Color.white))
                                                        .padding(4) : nil,
                                                alignment: .topTrailing
                                            )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Button(action: {
                        viewModel.syncPhotos()
                    }) {
                        Text("Sync Photos")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(viewModel.isSyncing)
                    
                    if viewModel.isSyncing {
                        ProgressView("Syncing...")
                            .padding()
                    }
                }
                .navigationTitle("Local Photos")
                .onAppear {
                    viewModel.requestPhotoAccess()
                }
            }
            .tabItem {
                Label("Local", systemImage: "photo.on.rectangle")
            }
            .tag(0)
            
            // MinIO Photos Tab
            NavigationView {
                VStack {
                    if viewModel.isLoadingMinIO {
                        ProgressView("Loading MinIO photos...")
                    } else if viewModel.minioPhotos.isEmpty {
                        Text("No photos found on MinIO server")
                            .foregroundColor(.gray)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(viewModel.minioPhotos) { photo in
                                    NavigationLink(destination: PhotoDetailView(photoSource: .minio(photo))) {
                                        AsyncImage(url: photo.url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                        } placeholder: {
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Button(action: {
                        viewModel.refreshMinIOPhotos()
                    }) {
                        Text("Refresh")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                .navigationTitle("MinIO Photos")
                .onAppear {
                    viewModel.loadMinIOPhotos()
                }
            }
            .tabItem {
                Label("MinIO", systemImage: "cloud")
            }
            .tag(1)
            
            // Settings Tab
            NavigationView {
                Form {
                    Section(header: Text("MinIO Server Configuration")) {
                        TextField("Server URL", text: $viewModel.serverURL)
                        TextField("Access Key", text: $viewModel.accessKey)
                        SecureField("Secret Key", text: $viewModel.secretKey)
                        TextField("Bucket Name", text: $viewModel.bucketName)
                    }
                    
                    Button("Save Settings") {
                        viewModel.saveSettings()
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .errorAlert(errorHandler: errorHandler)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
