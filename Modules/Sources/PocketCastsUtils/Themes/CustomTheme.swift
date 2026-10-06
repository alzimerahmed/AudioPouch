import Foundation

/// Versioned, user-importable theme file (Phase 6, gap #4).
///
/// Schema v1 example:
/// ```json
/// {
///   "schemaVersion": 1,
///   "name": "Midnight",
///   "accentColor": "#7C4DFF",
///   "light": { "primaryUi01": "#FFFFFF", "primaryText01": "#111111", "...": "..." },
///   "dark":  { "primaryUi01": "#101014", "primaryText01": "#F2F2F2", "...": "..." }
/// }
/// ```
///
/// Both a light and a dark palette are mandatory so the theme works in the
/// app's dark/light handling (system-follow and manual). Colors are hex
/// strings (`#RRGGBB` or `#RRGGBBAA`) keyed by semantic token names matching
/// the design system (`ThemeStyle` family).
public struct CustomThemeFile: Codable, Equatable {
    public static let currentVersion = 1

    public var schemaVersion: Int
    public var name: String
    public var accentColor: String
    public var light: [String: String]
    public var dark: [String: String]

    public init(schemaVersion: Int = CustomThemeFile.currentVersion, name: String, accentColor: String, light: [String: String], dark: [String: String]) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.accentColor = accentColor
        self.light = light
        self.dark = dark
    }
}

/// Semantic color tokens a custom theme must define for each palette.
/// These map onto the design-system tokens resolved by `ThemeColor`.
public enum CustomThemeToken: String, CaseIterable, Sendable {
    case primaryUi01
    case primaryUi02
    case primaryText01
    case primaryText02
    case primaryIcon01
    case primaryInteractive01
}

/// Validation failures for an imported theme. Localized messages are rendered
/// by the UI layer; the cases carry the details needed for that.
public enum CustomThemeError: Error, Equatable {
    case unsupportedVersion(Int)
    case missingName
    case nameTooLong
    case missingPalette(String)
    case missingToken(token: String, palette: String)
    case invalidColor(String)
    case insufficientContrast(palette: String, ratio: Double)
    case decodingFailed
}

public enum CustomThemeValidator {
    /// Maximum length of a theme name.
    public static let maxNameLength = 40
    /// Minimum WCAG contrast ratio required between `primaryText01` and
    /// `primaryUi01` in each palette. Deliberately lenient (2.0) so expressive
    /// themes pass while unreadable ones are rejected.
    public static let minimumContrastRatio = 2.0

    /// Parses raw JSON data into a validated `CustomThemeFile`.
    /// Throws the first validation error found.
    public static func parse(_ data: Data) throws -> CustomThemeFile {
        let file: CustomThemeFile
        do {
            file = try JSONDecoder().decode(CustomThemeFile.self, from: data)
        } catch {
            throw CustomThemeError.decodingFailed
        }

        let errors = validate(file)
        if let first = errors.first {
            throw first
        }

        return file
    }

    /// Returns all validation problems with the given file (empty = valid).
    public static func validate(_ file: CustomThemeFile) -> [CustomThemeError] {
        var errors: [CustomThemeError] = []

        if file.schemaVersion != CustomThemeFile.currentVersion {
            errors.append(.unsupportedVersion(file.schemaVersion))
            return errors
        }

        let trimmedName = file.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errors.append(.missingName)
        } else if trimmedName.count > maxNameLength {
            errors.append(.nameTooLong)
        }

        if !isValidHex(file.accentColor) {
            errors.append(.invalidColor(file.accentColor))
        }

        for (key, palette) in [("light", file.light), ("dark", file.dark)] {
            guard !palette.isEmpty else {
                errors.append(.missingPalette(key))
                continue
            }
            for token in CustomThemeToken.allCases {
                guard let value = palette[token.rawValue] else {
                    errors.append(.missingToken(token: token.rawValue, palette: key))
                    continue
                }
                if !isValidHex(value) {
                    errors.append(.invalidColor(value))
                }
            }
        }

        for (key, palette) in [("light", file.light), ("dark", file.dark)] {
            if let background = palette[CustomThemeToken.primaryUi01.rawValue],
               let text = palette[CustomThemeToken.primaryText01.rawValue],
               isValidHex(background), isValidHex(text) {
                let ratio = contrastRatio(background, text) ?? 0
                if ratio < minimumContrastRatio {
                    errors.append(.insufficientContrast(palette: key, ratio: ratio))
                }
            }
        }

        return errors
    }

    /// Whether `hex` is a valid `#RRGGBB` or `#RRGGBBAA` color string.
    public static func isValidHex(_ hex: String) -> Bool {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("#") else { return false }
        let digits = trimmed.dropFirst()
        guard digits.count == 6 || digits.count == 8 else { return false }
        return digits.allSatisfy { $0.isHexDigit }
    }

    /// WCAG relative-luminance contrast ratio between two hex colors,
    /// or nil if either is invalid.
    public static func contrastRatio(_ hexA: String, _ hexB: String) -> Double? {
        guard let a = relativeLuminance(hexA), let b = relativeLuminance(hexB) else { return nil }
        let lighter = max(a, b)
        let darker = min(a, b)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ hex: String) -> Double? {
        let digits = hex.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst()
        guard digits.count >= 6 else { return nil }

        func channel(_ index: Int) -> Double? {
            let start = digits.index(digits.startIndex, offsetBy: index)
            let value = digits[start...digits.index(start, offsetBy: 1)]
            guard let component = Double(String(value), radix: 16) else { return nil }
            let normalized = component / 255.0
            return normalized <= 0.03928 ? normalized / 12.92 : pow((normalized + 0.055) / 1.055, 2.4)
        }

        guard let r = channel(0), let g = channel(2), let b = channel(4) else { return nil }
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
