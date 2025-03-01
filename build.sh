#!/bin/bash

# Build script for MinIOPhotoSync

echo "Building MinIOPhotoSync..."

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild is not installed. Please install Xcode."
    exit 1
fi

# Create a temporary Xcode project
echo "Creating Xcode project..."
swift package generate-xcodeproj

# Build the project
echo "Building project..."
xcodebuild -project MinIOPhotoSync.xcodeproj -scheme MinIOPhotoSync -destination 'platform=iOS Simulator,name=iPhone 13' build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "You can now open MinIOPhotoSync.xcodeproj in Xcode to run the app on a simulator or device."
else
    echo "Build failed. Please check the error messages above."
    exit 1
fi