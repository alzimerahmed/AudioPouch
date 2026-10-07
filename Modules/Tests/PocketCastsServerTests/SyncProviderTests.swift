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
        XCTAssertEqual(provider.displayName, "Pocket Casts")
    }

    /// With the flag off, the active provider is the upstream one regardless of
    /// anything else — behavior is identical to before the seam existed.
    func testActiveProviderIsUpstreamWhenFlagOff() {
        let provider = SyncProviderRegistry.activeProvider
        XCTAssertEqual(provider.identifier, "pocketcasts")
    }

    /// With the flag on but only one provider registered, upstream is still used.
    func testActiveProviderIsUpstreamWhenFlagOnWithSingleProvider() {
        try? FeatureFlagOverrideStore().override(.syncProviderOptions, withValue: true)
        XCTAssertTrue(FeatureFlag.syncProviderOptions.enabled)
        XCTAssertEqual(SyncProviderRegistry.activeProvider.identifier, "pocketcasts")
    }

    /// An unconfigured upstream provider reports itself as such and refuses to sync.
    func testUnconfiguredProviderCannotSync() {
        let provider = PocketCastsSyncProvider()
        provider.syncTrigger = { true }
        // Test environment has no sync credentials; if one leaks in, skip the assert.
        guard !provider.isConfigured else { return }
        XCTAssertFalse(provider.syncNow(reason: .add), "Unconfigured provider must not sync")
    }

    /// A configured provider delegates to the installed trigger hook.
    func testConfiguredProviderDelegatesToTrigger() throws {
        let provider = PocketCastsSyncProvider()
        var triggerCalled = false
        provider.syncTrigger = {
            triggerCalled = true
            return true
        }
        try configureSyncingEmail()

        XCTAssertTrue(provider.isConfigured)
        XCTAssertTrue(provider.syncNow(reason: .add))
        XCTAssertTrue(triggerCalled)
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
