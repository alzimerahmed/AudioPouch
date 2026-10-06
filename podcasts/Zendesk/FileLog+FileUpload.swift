import Foundation
import PocketCastsUtils
import SwiftUI

extension FileLog {
    static let genericErrorMessage = "No log file uploaded: Error generating logs"

    static let noWearableLogsAvailable = "No wearable logs were available"

    public func encryptedLogUUID() async -> String {
        // Remote log upload was removed (privacy-first, local-only telemetry).
        // Logs stay on device and can be shared manually via support.
        return FileLog.genericErrorMessage
    }

    /// Returns the watchOS log contents as a string, using the same flow as support uploads
    func watchLogFileAsString() async -> String? {
        await WatchManager.shared.requestLogFile()
    }

    /// Writes the watchOS log to a file, returning the path it was written
    /// to, or `nil` if the watch had no logs to give.
    func watchLogFileForUpload() async throws -> String? {
        guard let wearableLog = await WatchManager.shared.requestLogFile() else {
            return nil
        }

        let file = LogFilePaths.watchUploadLog
        do {
            try wearableLog.write(toFile: file, atomically: true, encoding: .utf8)
        } catch {
            throw LogError.logGenerationFailed
        }

        return file
    }

    public func encryptedWatchLogUUID() async -> String {
        // Remote log upload was removed (privacy-first, local-only telemetry).
        return FileLog.noWearableLogsAvailable
    }
}
