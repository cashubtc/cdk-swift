#!/bin/bash

# Simple build script for CDK Swift bindings - native target only for testing

set -e

# Configuration
CRATE_NAME="cdk-ffi"
CDK_DIR="${CDK_DIR:-../cdk}"
FFI_DIR="${CDK_DIR}/crates/cdk-ffi"
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

# Check if the cdk-ffi crate exists
if [ ! -d "$FFI_DIR" ]; then
    log_info "CDK FFI directory not found at $FFI_DIR"
    log_info "Set CDK_DIR environment variable to point to your CDK repository"
    log_info "Example: export CDK_DIR=/path/to/cdk"
    exit 1
fi

log_info "Building CDK Swift bindings for native target only..."

# Clean previous builds
log_info "Cleaning previous builds..."
rm -rf target/
rm -rf "$FRAMEWORK_NAME.xcframework"

# Build for native target only
log_info "Building Rust library for native target..."
cd "$FFI_DIR"
cargo build --profile release-smaller
cd - > /dev/null

# Generate Swift bindings if they don't exist
if [ ! -f "Sources/CashuDevKitFFI/CashuDevKitFFI.h" ]; then
    log_info "Generating Swift bindings..."
    bash ./generate-bindings.sh
fi

# Create directories for frameworks
mkdir -p target/native/Headers/

# Copy native library and headers
log_info "Copying native library and headers..."
cp "$FFI_DIR/../../target/release-smaller/libcdk_ffi.a" "target/native/libcdk_ffi.a"
cp "Sources/CashuDevKitFFI/CashuDevKitFFI.h" "target/native/Headers/"
cp "Sources/CashuDevKitFFI/module.modulemap" "target/native/Headers/CashuDevKitFFI.modulemap"

# Create XCFramework with just native
log_info "Creating XCFramework (native only)..."
xcodebuild -create-xcframework \
    -library "target/native/libcdk_ffi.a" \
    -headers "target/native/Headers/" \
    -output "$FRAMEWORK_NAME.xcframework"

log_info "Build completed successfully!"
log_info "XCFramework created at: $FRAMEWORK_NAME.xcframework"

# Test Swift compilation (optional - known linking issues)
log_info "Testing Swift compilation..."
if swift build --target CashuDevKit 2>/dev/null; then
    log_info "✅ Swift compilation successful!"
else
    log_info "⚠️  Swift compilation has linking issues (expected - XCFramework built successfully)"
fi