import Foundation

/// Persists user-imported custom themes as one JSON file per theme.
/// Pure Foundation so it is unit-testable on any platform.
public final class CustomThemeStore {
    public struct Entry: Codable, Equatable, Identifiable {
        public let id: UUID
        public let name: String
        public let accentColor: String
        public let light: [String: String]
        public let dark: [String: String]
        public let importedDate: Date
    }

    private let directory: URL
    private let fileExtension = "json"
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    /// - Parameter directory: where theme files are stored. Defaults to
    ///   `<Application Support>/CustomThemes`, created on demand. Inject a
    ///   temporary directory in tests.
    public init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            self.directory = base?.appendingPathComponent("CustomThemes", isDirectory: true)
                ?? FileManager.default.temporaryDirectory.appendingPathComponent("CustomThemes", isDirectory: true)
        }
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder = enc
    }

    /// All saved themes, newest import first.
    public func themes() -> [Entry] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else { return [] }

        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == fileExtension }
            .compactMap { try? decoder.decode(Entry.self, from: Data(contentsOf: $0)) }
            .sorted { $0.importedDate > $1.importedDate }
    }

    /// Validates and persists a parsed theme file, returning the stored entry.
    @discardableResult
    public func save(_ file: CustomThemeFile, now: Date = Date()) throws -> Entry {
        let entry = Entry(
            id: UUID(),
            name: file.name.trimmingCharacters(in: .whitespacesAndNewlines),
            accentColor: file.accentColor,
            light: file.light,
            dark: file.dark,
            importedDate: now
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(entry.id.uuidString).\(fileExtension)")
        try encoder.encode(entry).write(to: url, options: .atomic)
        return entry
    }

    /// Deletes a saved theme by id. Returns whether a file was removed.
    @discardableResult
    public func delete(id: UUID) -> Bool {
        let url = directory.appendingPathComponent("\(id.uuidString).\(fileExtension)")
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        return (try? FileManager.default.removeItem(at: url)) != nil
    }

    /// Loads a single entry by id, if it still exists on disk.
    public func entry(id: UUID) -> Entry? {
        themes().first { $0.id == id }
    }
}
