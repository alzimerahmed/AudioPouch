@testable import podcasts
import UIKit
import XCTest

final class ShowNotesFormatterTests: XCTestCase {
    func testFormatRemovesExecutableAndUnsafeHTMLWhilePreservingSafeContent() {
        let showNotes = """
        <p onclick="steal()"><strong>Episode notes</strong></p>
        <script>steal()</script>
        <img src="https://example.com/image.png" onerror="steal()">
        <a href="javascript:steal()">Unsafe link</a>
        <a href="https://example.com">Safe link</a>
        <iframe src="https://example.com"></iframe>
        """

        let formatted = ShowNotesFormatter.format(
            showNotes: showNotes,
            tintColor: .blue,
            convertTimesToLinks: false,
            bgColor: nil,
            textColor: .black
        )

        XCTAssertFalse(formatted.localizedCaseInsensitiveContains("<script"))
        XCTAssertFalse(formatted.localizedCaseInsensitiveContains("onclick"))
        XCTAssertFalse(formatted.localizedCaseInsensitiveContains("onerror"))
        XCTAssertFalse(formatted.localizedCaseInsensitiveContains("javascript:"))
        XCTAssertFalse(formatted.localizedCaseInsensitiveContains("<iframe"))
        XCTAssertTrue(formatted.contains("Episode notes"))
        XCTAssertTrue(formatted.contains("Safe link"))
    }
}
