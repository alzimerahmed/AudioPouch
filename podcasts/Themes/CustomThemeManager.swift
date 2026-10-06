import Combine
import Foundation
import PocketCastsServer
import PocketCastsUtils
import UIKit

/// Bridges user-imported custom themes (persisted via `CustomThemeStore`)
/// into the app's theme system.
///
/// A custom theme rides on a built-in base theme (`light` or `dark`): all
/// `Themeable` screens keep working through the standard `ThemeColor` tokens,
/// and the custom accent color is applied on top while the custom theme is
/// active. Selecting any built-in theme deactivates the custom one.
final class CustomThemeManager: ObservableObject {
    static let activeCustomThemeIDKey = "activeCustomThemeID"
    static let shared = CustomThemeManager()

    private let store: CustomThemeStore
    private let defaults: UserDefaults

    @Published private(set) var themes: [CustomThemeStore.Entry]
    @Published private(set) var activeCustomTheme: CustomThemeStore.Entry?

    init(store: CustomThemeStore = CustomThemeStore(), defaults: UserDefaults = .standard) {
        self.store = store
        self.defaults = defaults
        themes = store.themes()
        if let idString = defaults.string(forKey: Self.activeCustomThemeIDKey), let id = UUID(uuidString: idString) {
            activeCustomTheme = store.entry(id: id)
        }

        // If the user picks a built-in theme from anywhere else in the app,
        // the custom theme is no longer active.
        NotificationCenter.default.addObserver(forName: Constants.Notifications.themeChanged, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.activeCustomTheme != nil else { return }
            let expectedBase: ThemeType = Theme.systemIsDark ? .dark : .light
            if Theme.shared.activeTheme != expectedBase {
                self.deactivate()
            }
        }
    }

    /// The accent color of the active custom theme, resolved for the current
    /// dark/light interface mode, or nil when no custom theme is active.
    var activeAccentColor: UIColor? {
        guard let active = activeCustomTheme else { return nil }
        let hex = Theme.isDarkTheme ? active.dark[CustomThemeToken.primaryInteractive01.rawValue] : active.light[CustomThemeToken.primaryInteractive01.rawValue]
        return Self.color(fromHex: hex ?? active.accentColor)
    }

    /// Activates a custom theme: sets the base theme type (respecting the
    /// current dark/light mode) and remembers the active custom theme.
    func activate(_ entry: CustomThemeStore.Entry) {
        activeCustomTheme = entry
        defaults.set(entry.id.uuidString, forKey: Self.activeCustomThemeIDKey)
        let baseType: ThemeType = Theme.isDarkTheme ? .dark : .light
        if Theme.shared.activeTheme != baseType {
            Theme.shared.activeTheme = baseType
        }
    }

    /// Deactivates any custom theme (used when a built-in theme is applied
    /// from the gallery or the theme is deleted).
    func deactivate() {
        activeCustomTheme = nil
        defaults.removeObject(forKey: Self.activeCustomThemeIDKey)
    }

    /// Validates and imports a theme file, refreshing the theme list.
    func importTheme(from data: Data) throws -> CustomThemeStore.Entry {
        let file = try CustomThemeValidator.parse(data)
        let entry = try store.save(file)
        themes = store.themes()
        return entry
    }

    /// Deletes a user theme. If it was active, the custom accent is removed.
    func delete(_ entry: CustomThemeStore.Entry) {
        if activeCustomTheme?.id == entry.id {
            deactivate()
        }
        store.delete(id: entry.id)
        themes = store.themes()
    }

    /// Parses `#RRGGBB` / `#RRGGBBAA` into a UIColor (nil if invalid).
    static func color(fromHex hex: String?) -> UIColor? {
        guard let hex else { return nil }
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        guard value.count == 6 || value.count == 8, let scalar = UInt64(value, radix: 16) else { return nil }

        // Normalize to 8 digits so the bit layout is always RRGGBBAA.
        let hasAlpha = value.count == 8
        let rgba = hasAlpha ? scalar : (scalar << 8) | 0xFF

        let r = CGFloat((rgba >> 24) & 0xFF) / 255.0
        let g = CGFloat((rgba >> 16) & 0xFF) / 255.0
        let b = CGFloat((rgba >> 8) & 0xFF) / 255.0
        let a = CGFloat(rgba & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
