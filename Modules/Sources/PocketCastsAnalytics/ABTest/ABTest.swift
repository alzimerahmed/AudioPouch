import Foundation

/// Local replacement for the ExPlat variation type. Without a remote
/// experiment service every lookup resolves to `control`.
public enum Variation: Equatable {
    case control
    case treatment
    case customTreatment(name: String)
}

public enum ABTest: String, CaseIterable {
    case pocketcastsPaywallAATest = "pocketcasts_paywall_ios_aa_test"
    case pocketcastsPaywallUpgradeIOSABTest = "pocketcasts_paywall_upgrade_ios_ab_test"
    case pocketcastsNewOnboardingIOSABTest = "pocketcasts_new_onboarding_ios_ab_test_v2"
}
