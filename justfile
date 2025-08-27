# CDK repository path - can be overridden with CDK_DIR environment variable
CDK_DIR := env_var_or_default('CDK_DIR', '../cdk')

[group("Repo")]
[doc("Default command; list all available commands.")]
@list:
 just --list --unsorted

[group("Repo")]
[doc("Open CDK repo on GitHub in your default browser.")]
repo:
 open https://github.com/cashubtc/cdk

[group("Build")]
[doc("Generate Swift bindings and FFI sources from the CDK crate.")]
generate:
 @bash ./generate-bindings.sh

[group("Build")]
[doc("Build the library with full cross-platform support.")]
build:
 CDK_DIR={{CDK_DIR}} bash ./build-xcframework.sh

[group("Build")]
[doc("Build the library for native platform only (faster for development).")]
build-native:
 CDK_DIR={{CDK_DIR}} bash ./build-native.sh

[group("Build")]
[doc("Remove all caches and previous builds to start from scratch.")]
clean:
 rm -rf {{CDK_DIR}}/target/
 rm -rf target/
 rm -rf cdkFFI.xcframework
 rm -rf .build/
 rm -rf Sources/CashuDevKit/*.swift
 rm -rf Sources/CashuDevKitFFI/

[group("Test")]
[doc("Run all tests (bindings, xcframework, and Swift tests).")]
test:
 @just test-bindings
 @just test-xcframework
 @just test-swift
 @echo "✅ All tests passed"

[group("Test")]
[doc("Run Swift package tests.")]
test-swift:
 @echo "Running Swift tests..."
 swift test
 @echo "✅ Swift tests passed"

[group("Test")]
[doc("Test that the XCFramework was created successfully.")]
test-xcframework:
 @echo "Testing XCFramework structure..."
 @if [ -d "cdkFFI.xcframework" ]; then echo "✅ XCFramework exists"; else echo "❌ XCFramework missing"; exit 1; fi
 @if [ -f "cdkFFI.xcframework/Info.plist" ]; then echo "✅ Info.plist exists"; else echo "❌ Info.plist missing"; exit 1; fi
 @if [ -f "cdkFFI.xcframework/macos-arm64/libcdk_ffi.a" ]; then echo "✅ Static library exists"; else echo "❌ Static library missing"; exit 1; fi
 @if [ -f "cdkFFI.xcframework/macos-arm64/Headers/CashuDevKitFFI.h" ]; then echo "✅ Header file exists"; else echo "❌ Header file missing"; exit 1; fi
 @echo "✅ XCFramework structure is valid"

[group("Test")]
[doc("Test that Swift bindings were generated successfully.")]
test-bindings:
 @echo "Testing Swift bindings..."
 @if [ -f "Sources/CashuDevKit/CashuDevKit.swift" ]; then echo "✅ Swift bindings exist"; else echo "❌ Swift bindings missing"; exit 1; fi
 @if [ -f "Sources/CashuDevKitFFI/CashuDevKitFFI.h" ]; then echo "✅ C header exists"; else echo "❌ C header missing"; exit 1; fi
 @if [ -f "Sources/CashuDevKitFFI/module.modulemap" ]; then echo "✅ Module map exists"; else echo "❌ Module map missing"; exit 1; fi
 @echo "✅ Swift bindings are valid"
 @echo "Generated Swift API includes:"
 @grep -c "public.*func\|public.*class\|public.*struct\|public.*enum" Sources/CashuDevKit/CashuDevKit.swift | sed 's/^/  - /' | sed 's/$/ public symbols/'


[group("Development")]
[doc("Check if all required tools are installed.")]
check-tools:
 @echo "Checking required tools..."
 @which cargo || echo "❌ Cargo (Rust) not found - install from https://rustup.rs/"
 @which swift || echo "❌ Swift not found - install Xcode or Swift toolchain"
 @which xcodebuild || echo "❌ xcodebuild not found - install Xcode"
 @echo "✅ Tool check complete"

[group("Development")]
[doc("Validate CDK directory and show setup instructions.")]
check-cdk:
 @echo "Checking CDK directory..."
 @echo "CDK_DIR = {{CDK_DIR}}"
 @if [ -d "{{CDK_DIR}}" ]; then \
   echo "✅ CDK directory exists"; \
   if [ -f "{{CDK_DIR}}/crates/cdk-ffi/Cargo.toml" ]; then \
     echo "✅ CDK FFI crate found"; \
   else \
     echo "❌ CDK FFI crate not found in {{CDK_DIR}}/crates/cdk-ffi"; \
   fi; \
 else \
   echo "❌ CDK directory not found at {{CDK_DIR}}"; \
   echo ""; \
   echo "Setup instructions:"; \
   echo "1. Clone CDK repository: git clone https://github.com/cashubtc/cdk.git"; \
   echo "2. Set CDK_DIR environment variable:"; \
   echo "   export CDK_DIR=/path/to/cdk"; \
   echo "   OR place CDK repo at ../cdk relative to this project"; \
 fi

[group("Development")]
[doc("Show information about the CDK FFI crate.")]
info:
 @echo "CDK Swift Bindings"
 @echo "=================="
 @echo "CDK FFI crate: {{CDK_DIR}}/crates/cdk-ffi"
 @echo "Swift package: $(pwd)"
 @echo "Generated bindings: Sources/CashuDevKit/"
 @echo ""
 @echo "Environment:"
 @echo "CDK_DIR = {{CDK_DIR}}"
 @if [ -d "{{CDK_DIR}}" ]; then echo "✅ CDK directory exists"; else echo "❌ CDK directory not found at {{CDK_DIR}}"; fi
 @echo ""
 @echo "Host Architecture:"
 @HOST_ARCH=$(uname -m); echo "Architecture: $HOST_ARCH"; \
  if [ "$HOST_ARCH" = "arm64" ]; then \
    echo "Build targets: aarch64-apple-ios, aarch64-apple-ios-sim, aarch64-apple-darwin"; \
  elif [ "$HOST_ARCH" = "x86_64" ]; then \
    echo "Build targets: aarch64-apple-ios, x86_64-apple-ios, x86_64-apple-darwin"; \
  fi
 @echo ""
 @echo "XCFramework:"
 @if [ -d "cdkFFI.xcframework" ]; then echo "✅ cdkFFI.xcframework exists"; else echo "❌ cdkFFI.xcframework not found - run 'just build'"; fi
 @echo ""
 @echo "Generated Swift bindings:"
 @if [ -f "Sources/CashuDevKit/CashuDevKit.swift" ]; then echo "✅ Swift bindings exist"; else echo "❌ Swift bindings not found - run 'just generate'"; fi
