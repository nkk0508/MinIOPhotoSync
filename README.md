# MinIO Photo Sync

An iOS application that synchronizes photos with an external MinIO server.

## Features

- Sync photos from your iOS device to a MinIO server
- Efficiently sync only photos that have changed since the last sync
- View photos stored on the MinIO server
- Detailed photo view with zoom and pan capabilities
- Configurable MinIO server settings

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Access to a MinIO server

## Setup

### MinIO Server Setup

1. Set up a MinIO server following the [official documentation](https://docs.min.io/docs/minio-quickstart-guide.html)
2. Create a bucket for storing photos
3. Configure CORS (Cross-Origin Resource Sharing) to allow requests from your app:

```bash
mc admin config set myminio cors <<<EOF
{
 "cors": {
  "allow_origins": ["*"],
  "allow_methods": ["GET", "PUT", "DELETE"],
  "allow_headers": ["*"],
  "expose_headers": ["ETag"],
  "max_age_seconds": 3600
 }
}
EOF
```

4. Restart your MinIO server to apply the CORS configuration

### App Setup

1. Clone this repository
2. Open the project in Xcode
3. Build and run the app on your iOS device or simulator
4. Go to the Settings tab and configure your MinIO server:
   - Server URL: The URL of your MinIO server (e.g., `https://minio.example.com`)
   - Access Key: Your MinIO access key
   - Secret Key: Your MinIO secret key
   - Bucket Name: The name of the bucket you created for storing photos

## How It Works

### Photo Synchronization

The app uses a differential synchronization approach to efficiently sync photos:

1. When you tap "Sync Photos", the app scans your photo library
2. For each photo, it calculates a checksum (SHA-256 hash)
3. It compares the checksum and modification date with the version on the MinIO server
4. Only photos that are new or have been modified since the last sync are uploaded
5. The app stores metadata about each photo to track sync status

### MinIO Integration

The app uses the AWS Signature V4 authentication method to securely communicate with the MinIO server:

- List objects: Retrieves a list of photos stored on the MinIO server
- Upload objects: Uploads photos to the MinIO server
- Get objects: Downloads photos from the MinIO server for viewing

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture:

- **Models**: `LocalPhoto`, `MinIOPhoto`, etc.
- **Views**: `ContentView`, `PhotoDetailView`, etc.
- **ViewModels**: `PhotoSyncViewModel`
- **Services**: `MinIOService`, `AWSV4Signature`, etc.

## License

This project is licensed under the MIT License - see the LICENSE file for details.