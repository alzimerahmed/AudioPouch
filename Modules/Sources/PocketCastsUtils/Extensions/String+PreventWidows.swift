import Foundation

public extension String {
    /// A non-breaking space
    static let nbsp = "\u{00a0}"

    /// Replaces all spaces with non-breaking spaces
    func nonBreakingSpaces() -> String {
        self.replacingOccurrences(of: Constants.space, with: Self.nbsp)
    }

    /// Prevents widows and orphans by applying a non-breaking space between the final words.
    func preventWidows() -> String {
        let returnText = self
        let components = returnText.components(separatedBy: Constants.space)

        guard components.count > 1 else {
            return returnText
        }

        let count = components.count - 1
        var builder: [String] = []

        for (index, word) in components.enumerated() {
            if index > 0 {
                let isLast = index == count
                builder.append(isLast ? .nbsp : Constants.space)
            }
            builder.append(word)
        }

        return builder.joined()
    }

    private enum Constants {
        static let space = " "
    }
}
