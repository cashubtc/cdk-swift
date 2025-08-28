#!/bin/bash
# This script builds CDK Swift language bindings and corresponding cdkFFI.xcframework.
# Based on the bdk-swift build script pattern.

set -e  # Exit on error

HEADERPATH="Sources/CashuDevKit/CashuDevKitFFI.h"
MODMAPPATH="Sources/CashuDevKit/CashuDevKitFFI.modulemap"
TARGETDIR="../cdk/target"
OUTDIR="."
NAME="cdkFFI"
STATIC_LIB_NAME="libcdk_ffi.a"
NEW_HEADER_DIR="../cdk/target/include"

# Move to cdk directory for building
cd ../cdk/ || exit

# Build cdk-ffi rust lib for apple targets
cargo build --package cdk-ffi --release --target x86_64-apple-darwin
cargo build --package cdk-ffi --release --target aarch64-apple-darwin
cargo build --package cdk-ffi --release --target x86_64-apple-ios
cargo build --package cdk-ffi --release --target aarch64-apple-ios
cargo build --package cdk-ffi --release --target aarch64-apple-ios-sim

# Build cdk-ffi Swift bindings and put in cdk-swift Sources
cargo run --bin uniffi-bindgen generate --library ./target/aarch64-apple-ios/release/libcdk_ffi.dylib --language swift --out-dir ../cdk-swift/Sources/CashuDevKit --no-format

# Combine cdk-ffi static libs for universal binaries via lipo tool
mkdir -p target/lipo-ios-sim/release
lipo target/aarch64-apple-ios-sim/release/libcdk_ffi.a target/x86_64-apple-ios/release/libcdk_ffi.a -create -output target/lipo-ios-sim/release/libcdk_ffi.a
mkdir -p target/lipo-macos/release
lipo target/aarch64-apple-darwin/release/libcdk_ffi.a target/x86_64-apple-darwin/release/libcdk_ffi.a -create -output target/lipo-macos/release/libcdk_ffi.a

cd ../cdk-swift/ || exit

# Move cdk-ffi static lib header files to temporary directory
mkdir -p "${NEW_HEADER_DIR}"
mv "${HEADERPATH}" "${NEW_HEADER_DIR}"
mv "${MODMAPPATH}" "${NEW_HEADER_DIR}/module.modulemap"
echo -e "\n" >> "${NEW_HEADER_DIR}/module.modulemap"

# Remove old xcframework directory
rm -rf "${OUTDIR}/${NAME}.xcframework"

# Create new xcframework from cdk-ffi static libs and headers
xcodebuild -create-xcframework \
    -library "${TARGETDIR}/lipo-macos/release/${STATIC_LIB_NAME}" \
    -headers "${NEW_HEADER_DIR}" \
    -library "${TARGETDIR}/aarch64-apple-ios/release/${STATIC_LIB_NAME}" \
    -headers "${NEW_HEADER_DIR}" \
    -library "${TARGETDIR}/lipo-ios-sim/release/${STATIC_LIB_NAME}" \
    -headers "${NEW_HEADER_DIR}" \
    -output "${OUTDIR}/${NAME}.xcframework"
