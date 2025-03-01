# MinIO Photo Sync - Installation Guide

This guide will help you set up and run the MinIO Photo Sync app on your iOS device or simulator.

## Prerequisites

- macOS with Xcode 13.0 or later
- iOS 15.0 or later (for running on a physical device)
- Swift 5.5 or later
- A MinIO server (self-hosted or cloud-based)

## Setting Up the Development Environment

1. **Clone the Repository**

```bash
git clone https://github.com/yourusername/MinIOPhotoSync.git
cd MinIOPhotoSync
```

2. **Generate Xcode Project**

```bash
swift package generate-xcodeproj
```

3. **Open the Project in Xcode**

```bash
open MinIOPhotoSync.xcodeproj
```

4. **Build and Run**

- Select your target device or simulator
- Click the Run button (▶️) or press Cmd+R

Alternatively, you can use the provided build script:

```bash
./build.sh
```

## Setting Up MinIO Server

### Option 1: Self-hosted MinIO Server

1. **Install MinIO**

Follow the [official MinIO installation guide](https://docs.min.io/docs/minio-quickstart-guide.html) for your platform.

2. **Start MinIO Server**

```bash
minio server /path/to/data
```

3. **Create a Bucket**

Use the MinIO web interface or the MinIO Client (mc) to create a bucket:

```bash
mc mb myminio/photos
```

4. **Configure CORS**

Configure CORS to allow requests from your app:

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

5. **Restart MinIO Server**

```bash
mc admin service restart myminio
```

### Option 2: Cloud-based MinIO Service

You can also use a cloud-based MinIO service like [MinIO SUBNET](https://min.io/subnet) or set up MinIO on a cloud provider like AWS, Google Cloud, or Azure.

## Configuring the App

1. **Launch the App**

Launch the MinIO Photo Sync app on your iOS device or simulator.

2. **Configure MinIO Settings**

- Go to the Settings tab
- Enter your MinIO server details:
  - Server URL: The URL of your MinIO server (e.g., `https://minio.example.com`)
  - Access Key: Your MinIO access key
  - Secret Key: Your MinIO secret key
  - Bucket Name: The name of the bucket you created for storing photos

3. **Grant Photo Library Access**

When prompted, grant the app access to your photo library.

## Troubleshooting

### App Cannot Connect to MinIO Server

- Verify that your MinIO server is running and accessible
- Check that the server URL, access key, secret key, and bucket name are correct
- Ensure that CORS is properly configured on your MinIO server
- Check if your iOS device has network connectivity

### Photos Not Syncing

- Check the error messages in the app
- Verify that you have granted the app access to your photo library
- Ensure that your MinIO server has enough storage space
- Check if your bucket exists and is accessible with the provided credentials

### Build Errors

- Make sure you have the latest version of Xcode and Swift
- Try cleaning the build folder (Shift+Cmd+K in Xcode)
- Check that all dependencies are properly installed

## Support

If you encounter any issues, please file a bug report on the GitHub repository.