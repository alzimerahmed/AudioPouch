import Foundation
import SwiftUI
import PocketCastsUtils

class ImportViewModel: OnboardingModel {
    var navigationController: UINavigationController?
    let availableSources: [ImportSource]

    var showSubtitle: Bool = true

    init() {
        self.availableSources = supportedSources.filter { $0.isSourceAvailable }
    }

    func didAppear() {
        OnboardingFlow.shared.track(.onboardingImportShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        OnboardingFlow.shared.track(.onboardingImportDismissed)
    }

    @objc func dismissTapped() {
        OnboardingFlow.shared.track(.onboardingImportDismissed)
        navigationController?.dismiss(animated: true)
    }

    // MARK: - Import apps
    let supportedSources: [ImportSource] = [
        .init(id: .applePodcasts, displayName: "Apple Podcasts", steps: L10n.importInstructionsApplePodcastsSteps),
        .init(id: .breaker, displayName: "Breaker", steps: L10n.importInstructionsBreaker),
        .init(id: .castro, displayName: "Castro", steps: L10n.importInstructionsCastro),
        .init(id: .castbox, displayName: "Castbox", steps: L10n.importInstructionsCastbox),
        .init(id: .overcast, displayName: "Overcast", steps: L10n.importInstructionsOvercast),
        .init(id: .other, displayName: "other apps", steps: L10n.importPodcastsDescriptionNew),
        .init(id: .opmlFromURL, displayName: "URL", steps: L10n.importOpmlFromUrl),
        .init(id: .opmlFromFile, displayName: L10n.importOpmlFileName, steps: L10n.importOpmlFromFile)
    ]

    enum ImportSourceId: String, AnalyticsDescribable {
        case breaker, castbox = "wazecastbox", overcast, other, opmlFromURL, opmlFromFile
        case castro = "co.supertop.Castro-2"
        case applePodcasts = "https://pocketcasts.com/import-from-apple-podcasts"

        var analyticsDescription: String {
            switch self {
            case .breaker:
                return "breaker"
            case .castbox:
                return "castbox"
            case .overcast:
                return "overcast"
            case .other:
                return "other"
            case .castro:
                return "castro"
            case .applePodcasts:
                return "apple_podcasts"
            case .opmlFromURL:
                return "opml_from_url"
            case .opmlFromFile:
                return "opml_from_file"
            }
        }
    }

    struct ImportSource: Identifiable, CustomDebugStringConvertible, Hashable {
        let id: ImportSourceId
        let displayName: String
        let steps: String

        var isSourceAvailable: Bool {
            #if targetEnvironment(simulator)
            return true
            #else
            // Always available - Others and opml from url are always available
            // Note: Even if Apple podcasts has been uninstalled by the user, the system will always report
            // that it's installed.
            if [.other, .applePodcasts, .opmlFromURL, .opmlFromFile].contains(id) {
                return true
            }

            guard let url else {
                return false
            }

            return UIApplication.shared.canOpenURL(url)
            #endif
        }

        var hideButton: Bool {
            switch id {
            case .other:
                return true
            default:
                return false
            }
        }

        func openApp() {
            guard let url else { return }

            UIApplication.shared.open(url)
        }

        private var url: URL? {
            if id == .other || id == .opmlFromURL || id == .opmlFromFile { return nil }

            let string: String
            if id == .applePodcasts {
                string = id.rawValue
            } else {
                string = id.rawValue + "://"
            }

            return URL(string: string)
        }

        var debugDescription: String {
            return "\(displayName): \(isSourceAvailable ? "Yes" : "No")"
        }
    }
}


extension ImportViewModel {
    static func make(in navigationController: UINavigationController? = nil, source: String? = nil, showSubtitle: Bool = true) -> UIViewController {
        let viewModel = ImportViewModel()
        viewModel.showSubtitle = showSubtitle

        let controller = ImportHostingController(rootView: ImportLandingView(viewModel: viewModel).setupDefaultEnvironment())

        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        controller.viewModel = viewModel

        if let source {
            OnboardingFlow.shared.updateAnalyticsSource(PlusUpgradeViewSource.from(string: source))
        }
        return navigationController == nil ? navController : controller
    }
}

// MARK: - Landing View
extension ImportViewModel {
    func didSelect(_ importsource: ImportSource) {
        guard let navigationController else { return }
        OnboardingFlow.shared.track(.onboardingImportAppSelected, properties: ["app": importsource.id])

        let controller = ImportHostingController(rootView: ImportDetailsView(importSource: importsource, viewModel: self).setupDefaultEnvironment())
        controller.viewModel = self

        navigationController.pushViewController(controller, animated: true)
    }
}


// MARK: - Details
extension ImportViewModel {
    func openApp(_ app: ImportSource) {
        OnboardingFlow.shared.track(.onboardingImportOpenAppTapped, properties: ["app": app.id])

        app.openApp()
    }
}

// MARK: - OPML from URL
extension ImportViewModel {
    func importFromURL(_ url: URL, completion: @escaping ((Bool) -> Void)) {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data else {
                print("Error downloading data: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileURL = temporaryDirectory.appendingPathComponent("feed.opml")

            do {
                try data.write(to: fileURL)
                print("File downloaded to: \(fileURL)")
                self.importPodcastsFromOPML(url: fileURL)
            } catch {
                print("Error saving file: \(error.localizedDescription)")
                completion(false)
            }
        }

        task.resume()
    }

    func importPodcastsFromOPML(url: URL) {
        PodcastManager.shared.importPodcastsFromOpml(url)
    }

    /// Imports an OPML file picked locally via `.fileImporter`. Reads the file contents
    /// (no download) and feeds the same `OpmlImporter` pipeline as the URL import.
    func importFromFile(_ sourceURL: URL, completion: @escaping ((Bool) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            let secured = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if secured {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: sourceURL)
                let fileURL = Self.temporaryOpmlFileURL()
                try data.write(to: fileURL)
                DispatchQueue.main.async {
                    self.importPodcastsFromOPML(url: fileURL)
                    completion(true)
                }
            } catch {
                FileLog.shared.addMessage("Error importing OPML file: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    /// Unique temp file per import so concurrent imports can't clobber each other.
    private static func temporaryOpmlFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".opml")
    }
}
