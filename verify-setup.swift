#!/usr/bin/env swift

// verify-setup.swift
// Simple script to verify that cdk-swift is properly set up

import Foundation

#if canImport(CashuDevKit)
import CashuDevKit

print("✅ CashuDevKit module imported successfully")

do {
    // Test mnemonic generation
    let mnemonic = try generateMnemonic()
    print("✅ Mnemonic generation works: \(mnemonic.prefix(20))...")
    
    // Test basic types
    let amount = Amount(value: 1000)
    print("✅ Amount type works: \(amount.value)")
    
    let config = WalletConfig(workDir: "/tmp/test", targetProofCount: nil)
    print("✅ WalletConfig type works: \(config.workDir)")
    
    print("\n🎉 Setup verification completed successfully!")
    print("📖 Check the README.md for usage examples")
    
} catch {
    print("❌ Error during verification: \(error)")
    exit(1)
}

#else
print("❌ CashuDevKit module not found")
print("💡 Make sure you've built the XCFramework with: just build")
print("💡 And that you're running this from the cdk-swift directory")
exit(1)
#endif