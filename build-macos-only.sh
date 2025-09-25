#!/bin/bash

# Simple build script for CDK Swift bindings - macOS only for testing

set -e

# Configuration
CRATE_NAME="cdk-ffi"
FFI_DIR="../cdk/crates/cdk-ffi"
FRAMEWORK_NAME="cdkFFI"
SWIFT_PACKAGE_NAME="CashuDevKit"

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    log_info "Package.swift not found. Please run this script from the cdk-swift directory."
    exit 1
fi

log_info "Building CDK Swift bindings for macOS only..."

# Clean previous builds
log_info "Cleaning previous builds..."
rm -rf target/
rm -rf "$FRAMEWORK_NAME.xcframework"

# Add macOS targets
log_info "Adding Rust targets..."
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Build for macOS targets only
log_info "Building Rust libraries for macOS targets..."
cd "$FFI_DIR"
cargo build --profile release-smaller --target x86_64-apple-darwin
cargo build --profile release-smaller --target aarch64-apple-darwin
cd - > /dev/null

# Create directories for frameworks
mkdir -p target/macos/

# Combine macOS libraries
log_info "Creating macOS universal library..."
lipo -create \
    "$FFI_DIR/../../target/x86_64-apple-darwin/release-smaller/libcdk_ffi.a" \
    "$FFI_DIR/../../target/aarch64-apple-darwin/release-smaller/libcdk_ffi.a" \
    -output "target/macos/libcdk_ffi.a"

# Create XCFramework with just macOS
log_info "Creating XCFramework (macOS only)..."
xcodebuild -create-xcframework \
    -library "target/macos/libcdk_ffi.a" \
    -headers "Sources/$SWIFT_PACKAGE_NAME/" \
    -output "$FRAMEWORK_NAME.xcframework"

log_info "Build completed successfully!"
log_info "XCFramework created at: $FRAMEWORK_NAME.xcframework"

# Test Swift compilation
log_info "Testing Swift compilation..."
swift build --target CashuDevKit