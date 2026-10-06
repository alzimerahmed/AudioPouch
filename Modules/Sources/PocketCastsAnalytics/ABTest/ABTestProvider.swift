public struct ABTestProvider: ABTestProviding {

    /// A singleton instance of the current provider
    public static let shared = ABTestProvider()

    /// Analytics are local-only, so there is no remote experiment service.
    /// Every lookup resolves to `control`.
    public func variation(for abTest: ABTest) -> Variation {
        .control
    }

    public func start() async {}

    public func reloadExPlat(platform: String, oAuthToken: String? = nil, userAgent: String? = nil, anonId: String? = nil) {}
}
