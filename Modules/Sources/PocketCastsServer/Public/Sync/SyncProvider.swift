import Foundation
import PocketCastsUtils

/// Abstraction seam for sync backends (ADR-005, prototype).
///
/// The goal is *not* to replace the upstream Pocket Casts sync — it is to give
/// future providers (gPodder/Nextcloud, a self-hosted Pocket Casts-compatible
/// server) a single, narrow seam to plug into, without the app target knowing
/// which backend is active.
///
/// Protocol coverage expectations per provider:
/// - subscriptions (add/remove)
/// - playback progress / episode actions
/// - Up Next queue
/// - filters (optional — gPodder has no equivalent)
public protocol SyncProvider: AnyObject {
    /// Stable identifier, e.g. "pocketcasts", "gpodder_nextcloud".
    var identifier: String { get }

    /// Human-readable name for settings UI.
    var displayName: String { get }

    /// Whether this provider has credentials/configuration and can sync.
    var isConfigured: Bool { get }

    /// Kick off a sync. Returns false when the provider cannot sync right now
    /// (not configured, offline, unsupported operation).
    @discardableResult
    func syncNow(reason: SyncManager.SyncingReason) -> Bool
}

/// Default provider: the existing upstream Pocket Casts sync path.
/// Thin adapter only — all real work stays in `SyncManager`/`SyncTask`.
public final class PocketCastsSyncProvider: SyncProvider {
    /// Optional hook the app target can install to trigger its existing sync
    /// flow (the app owns the sync scheduling today). Receives the sync reason
    /// so providers can distinguish e.g. `login` from `add`. When nil,
    /// `syncNow` reports that syncing is unavailable rather than guessing.
    public var syncTrigger: ((SyncManager.SyncingReason) -> Bool)?

    public init() {}

    public var identifier: String { "pocketcasts" }

    public var displayName: String { "AudioPouch" }

    public var isConfigured: Bool {
        SyncManager.isUserLoggedIn()
    }

    @discardableResult
    public func syncNow(reason: SyncManager.SyncingReason) -> Bool {
        guard isConfigured else { return false }
        return syncTrigger?(reason) ?? false
    }
}

/// Registry of available sync providers. Holds a shared provider instance so
/// hooks installed on it (e.g. `syncTrigger`) survive between lookups.
/// Future providers register here behind `FeatureFlag.syncProviderOptions`.
public enum SyncProviderRegistry {
    /// Shared upstream provider instance.
    public private(set) static var defaultProvider: SyncProvider = PocketCastsSyncProvider()

    /// All providers the build knows about. Only the upstream provider exists
    /// today; future providers are added here behind `FeatureFlag.syncProviderOptions`.
    public static var availableProviders: [SyncProvider] {
        [defaultProvider]
    }

    /// The provider the app should use. While `syncProviderOptions` is off
    /// (default), this always returns the upstream provider — behavior is
    /// unchanged from before the seam existed.
    public static var activeProvider: SyncProvider {
        defaultProvider
    }
}
