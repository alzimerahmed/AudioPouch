import Foundation
import PocketCastsUtils
import XCTest

final class CustomThemeTests: XCTestCase {
    private let validJSON = """
    {
      "schemaVersion": 1,
      "name": "Midnight",
      "accentColor": "#7C4DFF",
      "light": {
        "primaryUi01": "#FFFFFF",
        "primaryUi02": "#F4F4F4",
        "primaryText01": "#111111",
        "primaryText02": "#555555",
        "primaryIcon01": "#222222",
        "primaryInteractive01": "#7C4DFF"
      },
      "dark": {
        "primaryUi01": "#101014",
        "primaryUi02": "#1C1C22",
        "primaryText01": "#F2F2F2",
        "primaryText02": "#AAAAAA",
        "primaryIcon01": "#DDDDDD",
        "primaryInteractive01": "#7C4DFF"
      }
    }
    """.data(using: .utf8)!

    func testParseValidTheme() throws {
        let file = try CustomThemeValidator.parse(validJSON)
        XCTAssertEqual(file.name, "Midnight")
        XCTAssertEqual(file.schemaVersion, 1)
        XCTAssertEqual(file.accentColor, "#7C4DFF")
        XCTAssertEqual(file.light.count, 6)
        XCTAssertEqual(file.dark.count, 6)
    }

    func testParseRejectsUnsupportedVersion() {
        let json = """
        {"schemaVersion": 99, "name": "X", "accentColor": "#000000", "light": {}, "dark": {}}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try CustomThemeValidator.parse(json)) { error in
            XCTAssertEqual(error as? CustomThemeError, .unsupportedVersion(99))
        }
    }

    func testParseRejectsMalformedJSON() {
        XCTAssertThrowsError(try CustomThemeValidator.parse("not json".data(using: .utf8)!)) { error in
            XCTAssertEqual(error as? CustomThemeError, .decodingFailed)
        }
    }

    func testValidateMissingDarkPalette() {
        let file = CustomThemeFile(
            name: "Half",
            accentColor: "#000000",
            light: Self.completePalette(),
            dark: [:]
        )
        XCTAssertTrue(CustomThemeValidator.validate(file).contains(.missingPalette("dark")))
    }

    func testValidateMissingRequiredToken() {
        var palette = Self.completePalette()
        palette.removeValue(forKey: "primaryText01")
        let file = CustomThemeFile(name: "Broken", accentColor: "#000000", light: palette, dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains(.missingToken(token: "primaryText01", palette: "light")))
    }

    func testValidateInvalidHex() {
        let file = CustomThemeFile(name: "Bad", accentColor: "purple", light: Self.completePalette(), dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains(.invalidColor("purple")))
    }

    func testValidateMissingName() {
        let file = CustomThemeFile(name: "  ", accentColor: "#000000", light: Self.completePalette(), dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains(.missingName))
    }

    func testValidateNameTooLong() {
        let file = CustomThemeFile(name: String(repeating: "a", count: 41), accentColor: "#000000", light: Self.completePalette(), dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains(.nameTooLong))
    }

    func testValidateRejectsUnreadableContrast() {
        var palette = Self.completePalette()
        palette["primaryText01"] = "#222222" // dark text on dark background
        palette["primaryUi01"] = "#1A1A1A"
        let file = CustomThemeFile(name: "Dim", accentColor: "#000000", light: Self.completePalette(), dark: palette)
        XCTAssertTrue(CustomThemeValidator.validate(file).contains { $0.isInsufficientContrast(palette: "dark") })
    }

    func testValidateRejectsLowContrastSecondaryText() {
        var palette = Self.completePalette()
        palette["primaryText02"] = "#999999" // ~2.8:1 on white
        let file = CustomThemeFile(name: "Faded", accentColor: "#000000", light: palette, dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains { $0.isInsufficientContrast(palette: "light") })
    }

    func testValidateRejectsLowContrastInteractiveColor() {
        var palette = Self.completePalette()
        palette["primaryInteractive01"] = "#CCCCCC" // ~1.6:1 on white
        let file = CustomThemeFile(name: "Washed", accentColor: "#000000", light: palette, dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains { $0.isInsufficientContrast(palette: "light") })
    }

    func testValidateRejectsLowContrastAccentColor() {
        let file = CustomThemeFile(name: "Pale", accentColor: "#CCCCCC", light: Self.completePalette(), dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains { $0.isInsufficientContrast(palette: "light") })
    }

    func testValidateRejectsTranslucentTextCollapsingContrast() {
        var palette = Self.completePalette()
        // 50% alpha black text over white composites to ~#888888 (~3.5:1) — below AA.
        palette["primaryText01"] = "#11111180"
        let file = CustomThemeFile(name: "Ghost", accentColor: "#000000", light: palette, dark: Self.completePalette())
        XCTAssertTrue(CustomThemeValidator.validate(file).contains { $0.isInsufficientContrast(palette: "light") })
    }

    func testValidateAcceptsTranslucentTextWithSufficientContrast() {
        var palette = Self.completePalette()
        // 90% alpha black text over white composites to ~#212121 (~16:1) — passes AA.
        palette["primaryText01"] = "#111111E6"
        let file = CustomThemeFile(name: "Solid", accentColor: "#000000", light: palette, dark: Self.completePalette())
        XCTAssertEqual(CustomThemeValidator.validate(file), [])
    }

    func testValidThemeHasNoErrors() {
        let file = CustomThemeFile(name: "OK", accentColor: "#F44336", light: Self.completePalette(), dark: Self.completePalette())
        XCTAssertEqual(CustomThemeValidator.validate(file), [])
    }

    func testHexValidation() {
        XCTAssertTrue(CustomThemeValidator.isValidHex("#FFFFFF"))
        XCTAssertTrue(CustomThemeValidator.isValidHex("#FFFFFF80"))
        XCTAssertFalse(CustomThemeValidator.isValidHex("FFFFFF"))
        XCTAssertFalse(CustomThemeValidator.isValidHex("#FFF"))
        XCTAssertFalse(CustomThemeValidator.isValidHex("#GGHHII"))
    }

    func testContrastRatioBlackOnWhite() {
        let ratio = CustomThemeValidator.contrastRatio("#000000", "#FFFFFF")
        XCTAssertNotNil(ratio)
        XCTAssertGreaterThan(ratio ?? 0, 20)
    }

    // MARK: - Store

    func testStoreSaveListDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = CustomThemeStore(directory: directory)

        XCTAssertEqual(store.themes().count, 0)

        let entry = try store.save(try CustomThemeValidator.parse(validJSON))
        XCTAssertEqual(entry.name, "Midnight")
        XCTAssertEqual(store.themes().count, 1)
        XCTAssertEqual(store.entry(id: entry.id)?.name, "Midnight")

        XCTAssertTrue(store.delete(id: entry.id))
        XCTAssertEqual(store.themes().count, 0)
        XCTAssertFalse(store.delete(id: entry.id))
    }

    func testStoreNewestFirstOrdering() throws {
        let store = CustomThemeStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let first = try store.save(CustomThemeFile(name: "First", accentColor: "#000000", light: Self.completePalette(), dark: Self.completePalette()), now: Date(timeIntervalSinceNow: -100))
        let second = try store.save(CustomThemeFile(name: "Second", accentColor: "#000000", light: Self.completePalette(), dark: Self.completePalette()), now: Date())
        XCTAssertEqual(store.themes().map(\.name), ["Second", "First"])
        XCTAssertEqual(store.themes().map(\.id), [second.id, first.id])
    }

    // MARK: - Helpers

    private static func completePalette() -> [String: String] {
        [
            "primaryUi01": "#FFFFFF",
            "primaryUi02": "#F4F4F4",
            "primaryText01": "#111111",
            "primaryText02": "#555555",
            "primaryIcon01": "#222222",
            "primaryInteractive01": "#7C4DFF"
        ]
    }
}

extension CustomThemeError {
    func isInsufficientContrast(palette: String) -> Bool {
        if case let .insufficientContrast(p, _) = self, p == palette { return true }
        return false
    }
}
