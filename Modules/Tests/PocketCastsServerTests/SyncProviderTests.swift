import XCTest
@testable import PocketCastsServer
import PocketCastsUtils

class SyncProviderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        FeatureFlagOverrideStore().resetOverrides()
    }

    /// The syncProviderOptions flag ships default-off (prototype seam only).
    func testSyncProviderOptionsFlagDefaultsOff() {
        XCTAssertFalse(FeatureFlag.syncProviderOptions.enabled, "syncProviderOptions must default off")
    }

    /// The upstream Pocket Casts provider is always present and is the default.
    func testDefaultProviderIsPocketCasts() {
        let provider = SyncProviderRegistry.defaultProvider
        XCTAssertEqual(provider.identifier, "pocketcasts")
        XCTAssertEqual(provider.displayName, "AudioPouch")
    }

    /// With the flag off, the active provider is the upstream one regardless of
    /// anything else — behavior is identical to before the seam existed.
    func testActiveProviderIsUpstreamWhenFlagOff() {
        let provider = SyncProviderRegistry.activeProvider
        XCTAssertEqual(provider.identifier, "pocketcasts")
    }

    /// With the flag on but only one provider registered, upstream is still used.
    func testActiveProviderIsUpstreamWhenFlagOnWithSingleProvider() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.syncProviderOptions, withValue: true)
        XCTAssertTrue(FeatureFlag.syncProviderOptions.enabled)
        XCTAssertEqual(SyncProviderRegistry.activeProvider.identifier, "pocketcasts")
    }

    /// An unconfigured upstream provider reports itself as such and refuses to sync.
    func testUnconfiguredProviderCannotSync() throws {
        let provider = PocketCastsSyncProvider()
        provider.syncTrigger = { _ in true }
        // Test environment has no sync credentials; if one leaks in, skip the assert.
        guard !provider.isConfigured else {
            throw XCTSkip("Sync credentials leaked into test environment")
        }
        XCTAssertFalse(provider.syncNow(reason: .add), "Unconfigured provider must not sync")
    }

    /// A configured provider delegates to the installed trigger hook, forwarding the reason.
    func testConfiguredProviderDelegatesToTrigger() throws {
        let provider = PocketCastsSyncProvider()
        var receivedReason: SyncManager.SyncingReason?
        provider.syncTrigger = { reason in
            receivedReason = reason
            return true
        }
        try configureSyncingEmail()

        XCTAssertTrue(provider.isConfigured)
        XCTAssertTrue(provider.syncNow(reason: .add))
        XCTAssertEqual(receivedReason, .add)
    }

    /// A configured provider with no trigger installed reports unavailability
    /// rather than guessing.
    func testConfiguredProviderWithoutTriggerReportsUnavailable() throws {
        let provider = PocketCastsSyncProvider()
        try configureSyncingEmail()

        XCTAssertFalse(provider.syncNow(reason: .login))
    }

    /// The syncing email lives in the keychain; if the test host cannot access
    /// it (CI signing), skip rather than fail on an environment limitation.
    private func configureSyncingEmail() throws {
        ServerSettings.setSyncingEmail(email: "sync-provider-test@example.com")
        guard PocketCastsSyncProvider().isConfigured else {
            ServerSettings.setSyncingEmail(email: nil)
            throw XCTSkip("Keychain unavailable in test host")
        }
    }

    override func tearDown() {
        super.tearDown()
        ServerSettings.setSyncingEmail(email: nil)
        FeatureFlagOverrideStore().resetOverrides()
    }
}
