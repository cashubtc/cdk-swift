#!/bin/bash

# CDK Swift Bindings Generator
# This script generates Swift bindings from the CDK FFI crate

set -e

# Configuration
CDK_DIR="${CDK_DIR:-../cdk}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_OUTPUT_DIR="$SCRIPT_DIR/Sources/CashuDevKit"
FFI_OUTPUT_DIR="$SCRIPT_DIR/Sources/CashuDevKitFFI"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Validate environment
if [ ! -d "$CDK_DIR" ]; then
    echo "❌ CDK directory not found at $CDK_DIR"
    echo "Set CDK_DIR environment variable or ensure CDK repo is at ../cdk"
    exit 1
fi

if [ ! -d "$CDK_DIR/crates/cdk-ffi" ]; then
    echo "❌ CDK FFI crate not found at $CDK_DIR/crates/cdk-ffi"
    exit 1
fi

log_info "Generating Swift bindings from CDK FFI crate..."
log_info "CDK directory: $CDK_DIR"

# Build the CDK FFI library
log_info "Building CDK FFI library..."
cd "$CDK_DIR/crates/cdk-ffi"
cargo build --release

# Check if library was built successfully
if [ ! -f "../../target/release/libcdk_ffi.dylib" ]; then
    echo "❌ Failed to build libcdk_ffi.dylib"
    exit 1
fi

# Generate Swift bindings
log_info "Generating Swift bindings..."
cargo run --bin uniffi-bindgen generate \
    --library ../../target/release/libcdk_ffi.dylib \
    --language swift \
    --out-dir "$SWIFT_OUTPUT_DIR"

# Return to script directory
cd "$SCRIPT_DIR"

# Organize generated files
log_info "Organizing generated files..."
mkdir -p "$FFI_OUTPUT_DIR"

# Move FFI files to CashuDevKitFFI directory
if [ -f "$SWIFT_OUTPUT_DIR/CashuDevKitFFI.h" ]; then
    mv "$SWIFT_OUTPUT_DIR/CashuDevKitFFI.h" "$FFI_OUTPUT_DIR/"
    log_info "Moved CashuDevKitFFI.h to FFI directory"
else
    log_warn "CashuDevKitFFI.h not found in output"
fi

if [ -f "$SWIFT_OUTPUT_DIR/CashuDevKitFFI.modulemap" ]; then
    mv "$SWIFT_OUTPUT_DIR/CashuDevKitFFI.modulemap" "$FFI_OUTPUT_DIR/module.modulemap"
    log_info "Moved module map to FFI directory"
else
    log_warn "CashuDevKitFFI.modulemap not found in output"
fi

# Verify Swift bindings were generated
if [ -f "$SWIFT_OUTPUT_DIR/CashuDevKit.swift" ]; then
    SWIFT_FILE_SIZE=$(wc -c < "$SWIFT_OUTPUT_DIR/CashuDevKit.swift")
    log_info "Swift bindings generated: CashuDevKit.swift ($SWIFT_FILE_SIZE bytes)"
else
    echo "❌ Swift bindings not generated"
    exit 1
fi

echo ""
echo "✅ Swift bindings generated successfully!"
echo "   - Swift bindings: Sources/CashuDevKit/CashuDevKit.swift"
if [ -f "$FFI_OUTPUT_DIR/CashuDevKitFFI.h" ]; then
    echo "   - FFI header: Sources/CashuDevKitFFI/CashuDevKitFFI.h"
fi
if [ -f "$FFI_OUTPUT_DIR/module.modulemap" ]; then
    echo "   - Module map: Sources/CashuDevKitFFI/module.modulemap"
fi
echo ""