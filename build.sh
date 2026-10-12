#!/bin/bash

# Exit on error
set -e

# Project root directory
PROJECT_ROOT=$(pwd)

# 1. Parse version from pubspec.yaml
VERSION_LINE=$(grep "^version: " pubspec.yaml)
VERSION=$(echo "$VERSION_LINE" | cut -d' ' -f2)

if [ -z "$VERSION" ]; then
  echo "Error: Could not parse version from pubspec.yaml"
  exit 1
fi

echo "Detected version: $VERSION"

# Ensure build_outputs directory exists
mkdir -p "$PROJECT_ROOT/build_outputs"

# 2. Build Android APK
echo "=========================================="
echo "Building Android APK..."
echo "=========================================="
DART_DEFINE_ARGS=""
if [ -f "$PROJECT_ROOT/.env" ]; then
  DART_DEFINE_ARGS="--dart-define-from-file=.env"
fi
flutter build apk --release $DART_DEFINE_ARGS

# Copy and rename APK
APK_SOURCE="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="$PROJECT_ROOT/build_outputs/TabiLenS-$VERSION.apk"
cp "$APK_SOURCE" "$APK_DEST"
echo "✓ Android APK exported to: $APK_DEST"

# 3. Build iOS IPA (using development export method)
echo "=========================================="
echo "Building iOS IPA..."
echo "=========================================="
flutter build ipa --export-method=development $DART_DEFINE_ARGS

# Copy and rename IPA
# The export path is build/ios/ipa/
IPA_SOURCE=$(find "$PROJECT_ROOT/build/ios/ipa" -name "*.ipa" | head -n 1)
if [ -n "$IPA_SOURCE" ]; then
  IPA_DEST="$PROJECT_ROOT/build_outputs/TabiLenS-$VERSION.ipa"
  cp "$IPA_SOURCE" "$IPA_DEST"
  echo "✓ iOS IPA exported to: $IPA_DEST"
else
  echo "⚠ Warning: No IPA file found in build/ios/ipa"
fi

echo "=========================================="
echo "Build process completed successfully!"
echo "Files exported to: $PROJECT_ROOT/build_outputs"
echo "=========================================="
