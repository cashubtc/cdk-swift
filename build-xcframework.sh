#!/bin/bash

# Build script for CDK Swift bindings
# Based on bdk-swift build script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
CRATE_NAME="cdk-ffi"
CDK_DIR="${CDK_DIR:-../cdk}"
FFI_DIR="${CDK_DIR}/crates/cdk-ffi"
FRAMEWORK_NAME="cdkFFI"
SWIFT_PACKAGE_NAME="CashuDevKit"

# Detect host architecture
HOST_ARCH=$(uname -m)

# Rust targets for different platforms - filtered based on host architecture
if [ "$HOST_ARCH" = "arm64" ]; then
    # Apple Silicon Mac - can build ARM targets and iOS simulator for ARM
    IOS_TARGETS=(
        "aarch64-apple-ios"           # iOS device
        "aarch64-apple-ios-sim"       # iOS simulator (Apple Silicon)
    )
    MACOS_TARGETS=(
        "aarch64-apple-darwin"        # macOS Apple Silicon
    )
    log_info "Detected Apple Silicon Mac - building ARM64 targets only"
elif [ "$HOST_ARCH" = "x86_64" ]; then
    # Intel Mac - can build x86_64 targets and iOS simulator for Intel
    IOS_TARGETS=(
        "aarch64-apple-ios"           # iOS device (cross-compile)
        "x86_64-apple-ios"            # iOS simulator (Intel)
    )
    MACOS_TARGETS=(
        "x86_64-apple-darwin"         # macOS Intel
    )
    log_info "Detected Intel Mac - building x86_64 targets"
else
    log_error "Unsupported host architecture: $HOST_ARCH"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    log_error "Package.swift not found. Please run this script from the cdk-swift directory."
    exit 1
fi

# Check if the cdk-ffi crate exists
if [ ! -d "$FFI_DIR" ]; then
    log_error "CDK FFI directory not found at $FFI_DIR"
    log_error "Set CDK_DIR environment variable to point to your CDK repository"
    log_error "Example: export CDK_DIR=/path/to/cdk"
    exit 1
fi

log_info "Building CDK Swift bindings..."

# Clean previous builds
log_info "Cleaning previous builds..."
rm -rf target/
rm -rf "$FRAMEWORK_NAME.xcframework"
# Clean generated files
rm -rf Sources/$SWIFT_PACKAGE_NAME/CashuDevKit.swift
rm -rf Sources/$SWIFT_PACKAGE_NAME/CashuDevKitFFI.h
rm -rf Sources/$SWIFT_PACKAGE_NAME/CashuDevKitFFI.modulemap

# Add Rust targets
log_info "Adding Rust targets..."
for target in "${IOS_TARGETS[@]}" "${MACOS_TARGETS[@]}"; do
    rustup target add "$target"
done

# Ensure source directory exists
mkdir -p Sources/$SWIFT_PACKAGE_NAME/

# Generate Swift bindings
log_info "Generating Swift bindings..."
bash ./generate-bindings.sh

# Build for all targets
log_info "Building Rust libraries for all targets..."
for target in "${IOS_TARGETS[@]}" "${MACOS_TARGETS[@]}"; do
    log_info "Building for $target..."
    cd "$FFI_DIR"
    cargo build --release --target "$target"
    cd - > /dev/null
done

# Create directories for frameworks
mkdir -p target/ios/
mkdir -p target/ios-simulator/
mkdir -p target/macos/

# Combine iOS device libraries (always aarch64)
log_info "Creating iOS device library..."
cp "$CDK_DIR/target/aarch64-apple-ios/release/libcdk_ffi.a" "target/ios/libcdk_ffi.a"

# Combine iOS Simulator libraries (architecture-dependent)
log_info "Creating iOS Simulator library..."
if [ "$HOST_ARCH" = "arm64" ]; then
    # Apple Silicon: Only ARM64 simulator
    cp "$CDK_DIR/target/aarch64-apple-ios-sim/release/libcdk_ffi.a" "target/ios-simulator/libcdk_ffi.a"
elif [ "$HOST_ARCH" = "x86_64" ]; then
    # Intel Mac: Only x86_64 simulator (no universal needed since we only have one arch)
    cp "$CDK_DIR/target/x86_64-apple-ios/release/libcdk_ffi.a" "target/ios-simulator/libcdk_ffi.a"
fi

# Combine macOS libraries (architecture-dependent)
log_info "Creating macOS library..."
if [ "$HOST_ARCH" = "arm64" ]; then
    # Apple Silicon: Only ARM64
    cp "$CDK_DIR/target/aarch64-apple-darwin/release/libcdk_ffi.a" "target/macos/libcdk_ffi.a"
elif [ "$HOST_ARCH" = "x86_64" ]; then
    # Intel Mac: Only x86_64
    cp "$CDK_DIR/target/x86_64-apple-darwin/release/libcdk_ffi.a" "target/macos/libcdk_ffi.a"
fi

# Create XCFramework
log_info "Creating XCFramework..."
xcodebuild -create-xcframework \
    -library "target/ios/libcdk_ffi.a" \
    -headers "Sources/CashuDevKitFFI/" \
    -library "target/ios-simulator/libcdk_ffi.a" \
    -headers "Sources/CashuDevKitFFI/" \
    -library "target/macos/libcdk_ffi.a" \
    -headers "Sources/CashuDevKitFFI/" \
    -output "$FRAMEWORK_NAME.xcframework"

log_info "Build completed successfully!"
log_info "XCFramework created at: $FRAMEWORK_NAME.xcframework"
log_info "Swift bindings generated in: Sources/$SWIFT_PACKAGE_NAME/"

# Run tests if requested
if [ "$1" == "--test" ]; then
    log_info "Running tests..."
    swift test
fi