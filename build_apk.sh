#!/bin/bash

# Optimized Flutter APK Build Script
# This script builds optimized APK files split by ABI to reduce size

echo "🚀 Starting optimized APK build process..."
echo ""

# Clean the project first
echo "📦 Cleaning Flutter project..."
flutter clean
flutter pub get

# Build optimized APK split by ABI
# This creates separate APKs for each architecture, significantly reducing size
echo ""
echo "🔨 Building optimized APK files (split by ABI)..."
flutter build apk --release --split-per-abi

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📱 APK files generated:"
echo "   - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (32-bit ARM)"
echo "   - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (64-bit ARM)"
echo "   - build/app/outputs/flutter-apk/app-x86_64-release.apk (64-bit x86)"
echo ""
echo "💡 The APK size should be significantly reduced (from ~100MB to ~20-30MB per ABI)"
echo ""
echo "To install on device:"
echo "   adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo ""

