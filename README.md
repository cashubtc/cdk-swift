# CDK Swift

Swift language bindings for the [Cashu Development Kit (CDK)](https://github.com/cashubtc/cdk).

## Overview

`cdk-swift` provides Swift/iOS bindings for CDK, enabling developers to integrate Cashu ecash functionality into their iOS and macOS applications.

## Installation

### Swift Package Manager (Recommended)

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cashubtc/cdk-swift.git", from: "0.0.6")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "CashuDevKit", package: "cdk-swift")
        ]
    )
]
```

### Xcode Integration

1. Open your Xcode project
2. Go to **File → Add Package Dependencies**
3. Enter the repository URL: `https://github.com/cashubtc/cdk-swift.git`
4. Select the version you want to use
5. Add `CashuDevKit` to your target

### Local Development Setup

For contributors or those who want to build from source:

1. **Clone and build the package locally**:
   ```bash
   git clone https://github.com/cashubtc/cdk-swift.git
   cd cdk-swift
   just build
   ```

2. **Add as a local package dependency** in your `Package.swift`:
   ```swift
   dependencies: [
       .package(path: "/path/to/cdk-swift")
   ]
   ```

3. **Or use Xcode's local package integration**:
   - Open your Xcode project
   - Go to **File → Add Package Dependencies**
   - Click **Add Local...** and select the `cdk-swift` directory
   - Add `CashuDevKit` to your target

## Supported Platforms

- **macOS**: 12.0+ (Intel and Apple Silicon)
- **iOS**: 15.0+ (Device and Simulator)
- **Swift**: 5.5+

## Basic Usage

### Import the Library

```swift
import CashuDevKit
```

### Generate a Mnemonic

```swift
let mnemonic = try generateMnemonic()
print("Generated mnemonic: \(mnemonic)")
```

### Create a Wallet

```swift
// Configure wallet  
let config = WalletConfig(targetProofCount: nil)

// Create database
let db = try await WalletSqliteDatabase(workDir: "/path/to/wallet/data")

// Create wallet with generated mnemonic
let wallet = try Wallet(
    mintUrl: "https://mint.example.com/",
    unit: CurrencyUnit.sat,
    mnemonic: mnemonic,
    db: db,
    config: config
)
```

### Get Mint Information

```swift
let mintInfo = try await wallet.getMintInfo()
if let info = mintInfo {
    print("Mint name: \(info.name ?? "Unknown")")
    print("Supported units: \(info.nuts)")
}
```

### Mint Tokens

```swift
// Create a mint quote
let amount = Amount(value: 1000) // 1000 sats
let quote = try await wallet.mintQuote(
    amount: amount, 
    description: "My payment"
)

// Mint tokens after paying the quote
let proofs = try await wallet.mint(
    quoteId: quote.id,
    amountSplitTarget: SplitTarget.none,
    spendingConditions: nil
)

print("Minted \(proofs.count) proofs")
```

### Send Tokens

```swift
// Configure send options
let sendOptions = SendOptions(
    memo: SendMemo(memo: "Payment for coffee", includeMemo: true),
    conditions: nil,
    amountSplitTarget: SplitTarget.none,
    sendKind: SendKind.onlineExact,
    includeFee: true,
    maxProofs: nil,
    metadata: [:]
)

// Prepare the send
let preparedSend = try await wallet.prepareSend(
    amount: Amount(value: 500),
    options: sendOptions
)

// Get the token to share
let token = try await preparedSend.confirm(memo: "Coffee payment")
print("Token to send: \(token)")
```

### Receive Tokens

```swift
// Configure receive options
let receiveOptions = ReceiveOptions(
    amountSplitTarget: SplitTarget.none,
    p2pkSigningKeys: [],
    preimages: [],
    metadata: [:]
)

// Receive the token
let receivedAmount = try await wallet.receive(
    token: token,
    options: receiveOptions
)

print("Received: \(receivedAmount.value) sats")
```

### Manage Transactions

```swift
// List all transactions
let allTransactions = try await wallet.listTransactions(direction: nil)

// List only incoming transactions (mint, receive)
let incomingTransactions = try await wallet.listTransactions(direction: .incoming)

// List only outgoing transactions (send, melt)
let outgoingTransactions = try await wallet.listTransactions(direction: .outgoing)

// Get a specific transaction by ID
let transactionId = TransactionId(hex: "your_transaction_id_here")
let transaction = try await wallet.getTransaction(id: transactionId)

// Revert a transaction if needed
try await wallet.revertTransaction(id: transactionId)
```

### Melt Tokens (Lightning Payments)

```swift
let invoice = "lnbc1000n1..." // Lightning invoice
let meltQuote = try await wallet.meltQuote(
    request: invoice,
    options: nil
)

// Pay the Lightning invoice
let melted = try await wallet.melt(quoteId: meltQuote.id)
print("Payment sent, preimage: \(melted.preimage ?? "None")")
```

### Error Handling

```swift
do {
    let wallet = try Wallet(
        mintUrl: "https://mint.example.com/",
        unit: CurrencyUnit.sat,
        mnemonic: mnemonic,
        db: db,
        config: config
    )
} catch let error as FfiError {
    switch error {
    case .generic(let message):
        print("CDK Error: \(message)")
    case .insufficientFunds(let message):
        print("Insufficient funds: \(message)")
    case .network(let message):
        print("Network error: \(message)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## Contributing

We welcome contributions! If you're interested in contributing to the development of CDK Swift:

1. **Fork and clone** the repository
2. **Set up your development environment** (see Development section below)
3. **Make your changes** and ensure tests pass
4. **Submit a pull request**

### Development Setup (For Contributors)

Prerequisites:
- [Rust](https://rustup.rs/) with cargo
- Xcode and Xcode Command Line Tools
- [Just](https://github.com/casey/just) task runner (optional but recommended)

Setup:
```bash
# Clone the CDK repository (required for development)
git clone https://github.com/cashubtc/cdk.git

# Clone this repository
git clone https://github.com/cashubtc/cdk-swift.git
cd cdk-swift

# Generate Swift bindings and build
just generate
just build
just test
```

## License

This project is licensed under the same license as the CDK project.
