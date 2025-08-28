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

# Move to cdk directory first to use its rust-toolchain
cd ../cdk/ || exit

# Add required rust targets to the toolchain used by CDK
rustup target add aarch64-apple-ios      # iOS arm64
rustup target add x86_64-apple-ios       # iOS x86_64
rustup target add aarch64-apple-ios-sim  # simulator mac M1
rustup target add aarch64-apple-darwin   # mac M1
rustup target add x86_64-apple-darwin    # mac x86_64

# Build cdk-ffi rust lib for apple targets
cargo build --package cdk-ffi --profile release-smaller --target x86_64-apple-darwin
cargo build --package cdk-ffi --profile release-smaller --target aarch64-apple-darwin
cargo build --package cdk-ffi --profile release-smaller --target x86_64-apple-ios
cargo build --package cdk-ffi --profile release-smaller --target aarch64-apple-ios
cargo build --package cdk-ffi --profile release-smaller --target aarch64-apple-ios-sim

# Build cdk-ffi Swift bindings and put in cdk-swift Sources
cargo run --bin uniffi-bindgen generate --library ./target/aarch64-apple-ios/release-smaller/libcdk_ffi.dylib --language swift --out-dir ../cdk-swift/Sources/CashuDevKit --no-format

# Combine cdk-ffi static libs for universal binaries via lipo tool
mkdir -p target/lipo-ios-sim/release-smaller
lipo target/aarch64-apple-ios-sim/release-smaller/libcdk_ffi.a target/x86_64-apple-ios/release-smaller/libcdk_ffi.a -create -output target/lipo-ios-sim/release-smaller/libcdk_ffi.a
mkdir -p target/lipo-macos/release-smaller
lipo target/aarch64-apple-darwin/release-smaller/libcdk_ffi.a target/x86_64-apple-darwin/release-smaller/libcdk_ffi.a -create -output target/lipo-macos/release-smaller/libcdk_ffi.a

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
    -library "${TARGETDIR}/lipo-macos/release-smaller/${STATIC_LIB_NAME}" \
    -headers "${NEW_HEADER_DIR}" \
    -library "${TARGETDIR}/aarch64-apple-ios/release-smaller/${STATIC_LIB_NAME}" \
    -headers "${NEW_HEADER_DIR}" \
    -library "${TARGETDIR}/lipo-ios-sim/release-smaller/${STATIC_LIB_NAME}" \
    -headers "${NEW_HEADER_DIR}" \
    -output "${OUTDIR}/${NAME}.xcframework"
