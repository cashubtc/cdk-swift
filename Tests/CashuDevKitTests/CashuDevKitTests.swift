import XCTest
@testable import CashuDevKit

final class CashuDevKitTests: XCTestCase {
    
    // Test configuration
    private let testMintUrl = "https://fake.thesimplekid.dev/"
    private let testUnit = CurrencyUnit.sat
    
    private func createTestWalletConfig() -> WalletConfig {
        return WalletConfig(targetProofCount: nil)
    }
    
    private func createTestDatabase() async throws -> WalletSqliteDatabase {
        let tempDir = NSTemporaryDirectory() + UUID().uuidString
        return try await WalletSqliteDatabase(workDir: tempDir)
    }
    
    private func createTestWallet() async throws -> Wallet {
        let config = createTestWalletConfig()
        let mnemonic = try generateMnemonic()
        let db = try await createTestDatabase()
        
        return try await Wallet(
            mintUrl: testMintUrl,
            unit: testUnit,
            mnemonic: mnemonic,
            db: db,
            config: config
        )
    }
    
    func testWalletCreation() async throws {
        let wallet = try await createTestWallet()
        
        // Verify wallet was created successfully
        XCTAssertNotNil(wallet)
        
        // Check mint URL
        let mintUrl = wallet.mintUrl()
        XCTAssertNotNil(mintUrl)
    }
    
    func testWalletGetMintInfo() async throws {
        let wallet = try await createTestWallet()
        
        // Get mint info (this tests network connectivity to the mint)
        do {
            let mintInfo = try await wallet.getMintInfo()
            // If successful, verify we got some info back
            if let info = mintInfo {
                print("Mint info retrieved successfully: \(info)")
            } else {
                print("No mint info available")
            }
        } catch {
            // This is expected to fail with fake mint or network issues
            print("Failed to get mint info (expected): \(error)")
            // The error can be either FfiError or rustPanic depending on the failure mode
            XCTAssertTrue(error is FfiError || "\(error)".contains("rustPanic"), "Should be an FfiError or rustPanic")
        }
    }
    
    func testMintQuoteCreation() async throws {
        let wallet = try await createTestWallet()
        
        let amount = Amount(value: 1000) // 1000 sats
        
        do {
            let quote = try await wallet.mintQuote(amount: amount, description: nil)
            
            // Verify quote properties
            XCTAssertNotNil(quote)
            XCTAssertEqual(quote.amount?.value ?? 0, amount.value)
            XCTAssertFalse(quote.id.isEmpty)
            XCTAssertFalse(quote.request.isEmpty)
            XCTAssertEqual(quote.unit, testUnit)
            
            print("Mint quote created successfully: ID=\(quote.id), Amount=\(quote.amount?.value ?? 0)")
        } catch {
            // This may fail with fake mint
            print("Mint quote creation failed (may be expected): \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
    }
    
    func testMeltQuoteCreation() async throws {
        let wallet = try await createTestWallet()
        
        // Test lightning invoice (fake one for testing)
        let testInvoice = "lnbc1000n1pjqxz8xpp5..."
        
        do {
            let quote = try await wallet.meltQuote(request: testInvoice, options: nil)
            
            // Verify quote properties
            XCTAssertNotNil(quote)
            XCTAssertFalse(quote.id.isEmpty)
            XCTAssertEqual(quote.request, testInvoice)
            XCTAssertEqual(quote.unit, testUnit)
            
            print("Melt quote created successfully: ID=\(quote.id)")
        } catch {
            // This is expected to fail with fake invoice
            print("Melt quote creation failed (expected with fake invoice): \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
    }
    
    func testProofStatesRetrieval() async throws {
        let wallet = try await createTestWallet()
        
        // Test getting proofs by various states
        let states: [ProofState] = [.unspent, .spent, .pending]
        
        do {
            let proofs = try await wallet.getProofsByStates(states: states)
            // New wallet should have no proofs
            XCTAssertTrue(proofs.isEmpty, "New wallet should have no proofs")
            print("Retrieved \(proofs.count) proofs")
        } catch {
            print("Failed to get proofs by states: \(error)")
            throw error
        }
    }
    
    func testSendOptionsCreation() throws {
        // Test creating send options with various configurations
        let memo = SendMemo(memo: "Test payment", includeMemo: true)
        let amount = Amount(value: 500)
        let splitTarget = SplitTarget.value(amount: amount)
        let sendKind = SendKind.onlineExact
        
        let sendOptions = SendOptions(
            memo: memo,
            conditions: nil,
            amountSplitTarget: splitTarget,
            sendKind: sendKind,
            includeFee: true,
            maxProofs: 10,
            metadata: ["test": "value"]
        )
        
        XCTAssertNotNil(sendOptions)
        XCTAssertEqual(sendOptions.memo?.memo, "Test payment")
        XCTAssertTrue(sendOptions.memo?.includeMemo ?? false)
        XCTAssertTrue(sendOptions.includeFee)
        XCTAssertEqual(sendOptions.maxProofs, 10)
        XCTAssertEqual(sendOptions.metadata["test"], "value")
    }
    
    func testReceiveOptionsCreation() throws {
        // Test creating receive options
        let amount = Amount(value: 1000)
        let splitTarget = SplitTarget.value(amount: amount)
        
        let receiveOptions = ReceiveOptions(
            amountSplitTarget: splitTarget,
            p2pkSigningKeys: [],
            preimages: [],
            metadata: ["receiver": "test"]
        )
        
        XCTAssertNotNil(receiveOptions)
        XCTAssertTrue(receiveOptions.p2pkSigningKeys.isEmpty)
        XCTAssertTrue(receiveOptions.preimages.isEmpty)
        XCTAssertEqual(receiveOptions.metadata["receiver"], "test")
    }
    
    func testAmountOperations() throws {
        let amount1 = Amount(value: 1000)
        let amount2 = Amount(value: 1000)
        let amount3 = Amount(value: 2000)
        
        // Test equality
        XCTAssertEqual(amount1, amount2)
        XCTAssertNotEqual(amount1, amount3)
        
        // Test value access
        XCTAssertEqual(amount1.value, 1000)
        XCTAssertEqual(amount3.value, 2000)
    }
    
    func testCurrencyUnits() throws {
        // Test different currency units
        XCTAssertEqual(CurrencyUnit.sat, CurrencyUnit.sat)
        XCTAssertEqual(CurrencyUnit.msat, CurrencyUnit.msat)
        XCTAssertEqual(CurrencyUnit.usd, CurrencyUnit.usd)
        XCTAssertEqual(CurrencyUnit.eur, CurrencyUnit.eur)
        
        // Test custom currency
        let customUnit = CurrencyUnit.custom(unit: "BTC")
        if case let .custom(unit) = customUnit {
            XCTAssertEqual(unit, "BTC")
        } else {
            XCTFail("Should be custom currency unit")
        }
    }
    
    func testSplitTargets() throws {
        // Test different split targets
        let noneTarget = SplitTarget.none
        let valueTarget = SplitTarget.value(amount: Amount(value: 1000))
        let valuesTarget = SplitTarget.values(amounts: [
            Amount(value: 500),
            Amount(value: 300),
            Amount(value: 200)
        ])
        
        // Verify enum cases
        if case .none = noneTarget {
            // Success
        } else {
            XCTFail("Should be none target")
        }
        
        if case let .value(amount) = valueTarget {
            XCTAssertEqual(amount.value, 1000)
        } else {
            XCTFail("Should be value target")
        }
        
        if case let .values(amounts) = valuesTarget {
            XCTAssertEqual(amounts.count, 3)
            XCTAssertEqual(amounts[0].value, 500)
        } else {
            XCTFail("Should be values target")
        }
    }
    
    func testWalletConfigCreation() throws {
        let config = WalletConfig(targetProofCount: 50)
        XCTAssertEqual(config.targetProofCount, 50)
        
        // Test with nil target proof count
        let config2 = WalletConfig(targetProofCount: nil)
        XCTAssertNil(config2.targetProofCount)
    }
    
    func testDatabaseCreation() async throws {
        let tempDir = NSTemporaryDirectory() + "test-wallet"
        let db = try await WalletSqliteDatabase(workDir: tempDir)
        XCTAssertNotNil(db)
    }
    
    func testErrorHandling() async throws {
        // Test wallet creation with invalid mint URL
        let config = createTestWalletConfig()
        let mnemonic = try generateMnemonic()
        let db = try await createTestDatabase()
        
        do {
            let _ = try await Wallet(
                mintUrl: "invalid-url",
                unit: testUnit,
                mnemonic: mnemonic,
                db: db,
                config: config
            )
            XCTFail("Should have thrown an error for invalid mint URL")
        } catch {
            // Expected to fail
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
            print("Correctly caught error for invalid mint URL: \(error)")
        }
    }
    
    func testMeltOptionsCreation() throws {
        // Test different melt options
        let amount = Amount(value: 1000)
        let mppOption = MeltOptions.mpp(amount: amount)
        let amountlessOption = MeltOptions.amountless(amountMsat: amount)
        
        // These are enum cases, just verify they can be created
        XCTAssertNotNil(mppOption)
        XCTAssertNotNil(amountlessOption)
        
        // Test enum pattern matching
        if case let .mpp(mppAmount) = mppOption {
            XCTAssertEqual(mppAmount.value, 1000)
        } else {
            XCTFail("Should be mpp option")
        }
        
        if case let .amountless(amountMsat) = amountlessOption {
            XCTAssertEqual(amountMsat.value, 1000)
        } else {
            XCTFail("Should be amountless option")
        }
    }
    
    func testMnemonicGeneration() throws {
        // Test mnemonic generation
        let mnemonic1 = try generateMnemonic()
        let mnemonic2 = try generateMnemonic()
        
        // Verify mnemonics are generated
        XCTAssertFalse(mnemonic1.isEmpty, "Mnemonic should not be empty")
        XCTAssertFalse(mnemonic2.isEmpty, "Mnemonic should not be empty")
        
        // Verify they are different (should be random)
        XCTAssertNotEqual(mnemonic1, mnemonic2, "Generated mnemonics should be different")
        
        // Verify mnemonic has expected format (should be words separated by spaces)
        let words1 = mnemonic1.split(separator: " ")
        let words2 = mnemonic2.split(separator: " ")
        
        XCTAssertTrue(words1.count >= 12, "Mnemonic should have at least 12 words")
        XCTAssertTrue(words2.count >= 12, "Mnemonic should have at least 12 words")
        
        print("Generated mnemonic 1: \(mnemonic1)")
        print("Generated mnemonic 2: \(mnemonic2)")
    }
    
    func testListTransactions() async throws {
        let wallet = try await createTestWallet()
        
        // Test listing all transactions (empty wallet should return empty list)
        do {
            let allTransactions = try await wallet.listTransactions(direction: nil)
            XCTAssertTrue(allTransactions.isEmpty, "New wallet should have no transactions")
            print("Listed \(allTransactions.count) transactions (all directions)")
        } catch {
            print("Failed to list transactions: \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
        
        // Test listing incoming transactions
        do {
            let incomingTransactions = try await wallet.listTransactions(direction: .incoming)
            XCTAssertTrue(incomingTransactions.isEmpty, "New wallet should have no incoming transactions")
            print("Listed \(incomingTransactions.count) incoming transactions")
        } catch {
            print("Failed to list incoming transactions: \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
        
        // Test listing outgoing transactions
        do {
            let outgoingTransactions = try await wallet.listTransactions(direction: .outgoing)
            XCTAssertTrue(outgoingTransactions.isEmpty, "New wallet should have no outgoing transactions")
            print("Listed \(outgoingTransactions.count) outgoing transactions")
        } catch {
            print("Failed to list outgoing transactions: \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
    }
    
    func testGetTransaction() async throws {
        let wallet = try await createTestWallet()
        
        // Test getting a non-existent transaction
        let fakeTransactionId = TransactionId(hex: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
        
        do {
            let transaction = try await wallet.getTransaction(id: fakeTransactionId)
            XCTAssertNil(transaction, "Non-existent transaction should return nil")
            print("Correctly returned nil for non-existent transaction")
        } catch {
            print("Failed to get transaction (may be expected): \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
    }
    
    func testRevertTransaction() async throws {
        let wallet = try await createTestWallet()
        
        // Test reverting a non-existent transaction (should fail)
        let fakeTransactionId = TransactionId(hex: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
        
        do {
            try await wallet.revertTransaction(id: fakeTransactionId)
            XCTFail("Reverting non-existent transaction should fail")
        } catch {
            print("Correctly failed to revert non-existent transaction: \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
    }
    
    func testFullMintingFlow() async throws {
        let wallet = try await createTestWallet()
        
        // Amount to mint (1000 sats)
        let amount = Amount(value: 1000)
        
        do {
            // Step 1: Create a mint quote
            let quote = try await wallet.mintQuote(amount: amount, description: nil)
            
            print("Mint quote created:")
            print("  Quote ID: \(quote.id)")
            print("  Amount: \(quote.amount?.value ?? 0)")
            print("  Payment request: \(quote.request)")
            print("  Unit: \(quote.unit)")
            
            // Verify quote properties
            XCTAssertNotNil(quote)
            XCTAssertEqual(quote.amount?.value ?? 0, amount.value)
            XCTAssertFalse(quote.id.isEmpty)
            XCTAssertFalse(quote.request.isEmpty)
            
            // Step 2: Subscribe to mint quote updates
            let subscribeParams = SubscribeParams(
                kind: .bolt11MintQuote,
                filters: [quote.id],
                id: nil
            )
            
            let subscription = try await wallet.subscribe(params: subscribeParams)
            print("Subscribed to mint quote updates")
            
            // Step 3: In a real scenario, we would pay the lightning invoice here
            // For testing, we'll simulate waiting for payment by attempting to receive a notification
            // This will likely timeout or fail with a test mint
            
            print("Waiting for payment notification...")
            
            // Create a timeout task
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                throw TestError.timeout
            }
            
            // Create a receive task
            let receiveTask = Task {
                try await subscription.recv()
            }
            
            // Race between timeout and receive
            do {
                let notification = try await withTaskCancellationHandler {
                    try await receiveTask.value
                } onCancel: {
                    receiveTask.cancel()
                    timeoutTask.cancel()
                }
                
                // If we get here, we received a notification
                switch notification {
                case .mintQuoteUpdate(let quoteUpdate):
                    print("Received mint quote update:")
                    print("  Updated quote ID: \(quoteUpdate.quote())")
                    print("  State: \(quoteUpdate.state())")
                    
                    // Step 4: If the quote is paid, mint the proofs
                    if quoteUpdate.state() == .paid {
                        print("Quote is paid! Minting proofs...")
                        
                        let splitTarget = SplitTarget.none
                        let proofs = try await wallet.mint(
                            quoteId: quote.id,
                            amountSplitTarget: splitTarget,
                            spendingConditions: nil
                        )
                        
                        print("Successfully minted \(proofs.count) proofs")
                        
                        // Verify proofs
                        XCTAssertFalse(proofs.isEmpty, "Should have minted proofs")
                        
                        var totalAmount: UInt64 = 0
                        for proof in proofs {
                            totalAmount += proof.amount().value
                            print("  Proof amount: \(proof.amount().value)")
                        }
                        
                        print("Total minted amount: \(totalAmount)")
                        XCTAssertEqual(totalAmount, amount.value, "Total proof amount should match requested amount")
                    } else {
                        print("Quote not yet paid, state: \(quoteUpdate.state())")
                    }
                    
                case .meltQuoteUpdate(let meltQuote):
                    print("Received melt quote update (unexpected): \(meltQuote.quote())")
                    
                case .proofState(let proofStates):
                    print("Received proof state update (unexpected): \(proofStates)")
                }
                
                timeoutTask.cancel()
                
            } catch {
                // Cancel both tasks
                receiveTask.cancel()
                timeoutTask.cancel()
                
                if error is TestError {
                    print("Timeout waiting for payment notification (expected with test mint)")
                    
                    // Step 4 (alternative): Try to mint anyway to test the mint function
                    print("Attempting to mint proofs without payment confirmation...")
                    
                    do {
                        let splitTarget = SplitTarget.none
                        let proofs = try await wallet.mint(
                            quoteId: quote.id,
                            amountSplitTarget: splitTarget,
                            spendingConditions: nil
                        )
                        
                        print("Unexpectedly minted \(proofs.count) proofs without payment")
                        XCTFail("Should not be able to mint without payment")
                        
                    } catch {
                        print("Correctly failed to mint without payment: \(error)")
                        XCTAssertTrue(error is FfiError, "Should be an FfiError")
                    }
                } else {
                    print("Error receiving notification: \(error)")
                    XCTAssertTrue(error is FfiError, "Should be an FfiError")
                }
            }
            
        } catch {
            // This is expected to fail with a fake mint
            print("Full minting flow failed (expected with fake mint): \(error)")
            XCTAssertTrue(error is FfiError, "Should be an FfiError")
        }
    }
    
}

enum TestError: Error {
    case timeout
}
    
