# MinIO Photo Sync - Project Summary

## Project Structure

```
MinIOPhotoSync/
├── MinIOPhotoSync.swift         # Main app entry point
├── ContentView.swift            # Main UI with tabs for local photos, MinIO photos, and settings
├── PhotoDetailView.swift        # Detailed view for viewing a single photo
├── PhotoSyncViewModel.swift     # View model for handling photo sync logic
├── MinIOService.swift           # Service for interacting with MinIO server
├── AWSV4Signature.swift         # Implementation of AWS Signature V4 for MinIO authentication
├── MinIOXMLParser.swift         # Parser for MinIO XML responses
├── ErrorHandler.swift           # Error handling utilities
├── Info.plist                   # App configuration and permissions
├── Package.swift                # Swift Package Manager configuration
├── Resources/                   # App resources
│   ├── Assets.xcassets/         # Image assets and colors
│   └── LaunchScreen.storyboard  # Launch screen
└── Tests/                       # Unit tests
    ├── PhotoSyncViewModelTests.swift
    └── AWSV4SignatureTests.swift
```

## Key Components

### Models

- **LocalPhoto**: Represents a photo from the device's photo library
- **MinIOPhoto**: Represents a photo stored on the MinIO server
- **SyncStatus**: Enum for tracking the sync status of photos (notSynced, syncing, synced, failed)
- **AppError**: Enum for different types of errors that can occur in the app

### Views

- **ContentView**: Main tabbed interface with three tabs:
  - Local Photos: Shows photos from the device's photo library
  - MinIO Photos: Shows photos stored on the MinIO server
  - Settings: Configuration for the MinIO server
- **PhotoDetailView**: Detailed view for a single photo with zoom and pan capabilities

### View Models

- **PhotoSyncViewModel**: Handles the business logic for syncing photos between the device and MinIO server

### Services

- **MinIOService**: Handles communication with the MinIO server (list, upload, delete photos)
- **AWSV4Signature**: Implements AWS Signature V4 authentication required by MinIO
- **MinIOXMLParser**: Parses XML responses from the MinIO server

### Utilities

- **ErrorHandler**: Centralized error handling with user-friendly alerts

## Features

1. **Photo Library Access**: Request and manage access to the device's photo library
2. **Photo Synchronization**: 
   - Calculate checksums for photos to identify changes
   - Sync only photos that have changed since the last sync
   - Track sync status for each photo
3. **MinIO Integration**:
   - Secure authentication using AWS Signature V4
   - List photos stored on MinIO
   - Upload photos to MinIO
   - Download photos from MinIO for viewing
4. **User Interface**:
   - Tabbed interface for easy navigation
   - Grid view for browsing photos
   - Detailed view for individual photos with zoom and pan
   - Settings configuration for MinIO server
5. **Error Handling**:
   - User-friendly error messages
   - Centralized error handling

## Implementation Details

### Photo Synchronization Logic

1. The app loads photos from the device's photo library
2. For each photo, it calculates a SHA-256 checksum
3. When syncing:
   - Photos that don't exist on MinIO are uploaded
   - Photos that exist but have been modified (different checksum) are re-uploaded
   - Photos that exist and haven't been modified are skipped
4. The app stores metadata about each photo (ID, checksum, last modified date) to track sync status

### MinIO Integration

The app uses standard HTTP requests with AWS Signature V4 authentication to communicate with the MinIO server:

- **List Objects**: GET request to retrieve a list of photos
- **Upload Object**: PUT request to upload a photo
- **Delete Object**: DELETE request to remove a photo
- **Get Object**: GET request to download a photo

### Error Handling

The app uses a centralized ErrorHandler to manage and display errors:

- Network errors when communicating with MinIO
- Permission errors when accessing the photo library
- Configuration errors when MinIO settings are invalid
- Upload/download errors when syncing photos

## Future Enhancements

1. **Background Sync**: Add support for background photo synchronization
2. **Selective Sync**: Allow users to select specific photos or albums to sync
3. **Conflict Resolution**: Improve handling of conflicts when photos are modified in multiple places
4. **Offline Support**: Add support for queuing uploads when offline
5. **Photo Organization**: Add support for folders or albums on MinIO
6. **Multi-account Support**: Allow configuration of multiple MinIO servers
7. **Improved Security**: Add support for encryption of photos