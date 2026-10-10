import SwiftUI
import UniformTypeIdentifiers

struct ImportDetailsView: View {
    enum OPMLImportResult {
        case none
        case success
        case failure
    }

    @EnvironmentObject var theme: Theme
    @Environment(\.presentationMode) var presentationMode

    @State var opmlURLText = ""
    @State var opmlImportResult: OPMLImportResult = .none
    @State var opmlImportInProgress: Bool = false
    @State var showOpmlFileImporter = false
    @State var observerTokens: [NSObjectProtocol] = []

    let importSource: ImportViewModel.ImportSource
    let viewModel: ImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollViewIfNeeded {
                VStack(alignment: .leading, spacing: 16) {
                    Image(importSource.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)

                    Text(L10n.importInstructionsImportFrom(importSource.displayName))
                        .font(size: 31, style: .largeTitle, weight: .bold, maxSizeCategory: .extraExtraExtraLarge)
                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                        .fixedSize(horizontal: false, vertical: true)

                    appInstructions

                    if importSource.id == .opmlFromURL {
                        opmlImportView
                    }

                    if importSource.id == .opmlFromFile {
                        fileImportView
                    }

                    Spacer()
                }.padding([.leading, .trailing], Constants.horizontalPadding)
            }

            // Hide button for other
            if !importSource.hideButton {
                if importSource.id == .opmlFromURL {
                   opmlViewButton
                } else if importSource.id == .opmlFromFile {
                    fileImportButton
                } else {
                    Button(importSource.id == .applePodcasts ? L10n.importInstructionsInstallShortcut : L10n.importInstructionsOpenIn(importSource.displayName)) {
                        viewModel.openApp(importSource)
                    }
                    .buttonStyle(RoundedButtonStyle(theme: theme))
                    .padding([.leading, .trailing], Constants.horizontalPadding)
                }
            }
        }.padding(.top, 16).padding(.bottom)
            .background(AppTheme.color(for: .primaryUi01, theme: theme).ignoresSafeArea())
            .onAppear {
                OnboardingFlow.shared.track(.onboardingImportAppSelected, properties: ["app": importSource.id])
                observeOpmlImportNotifications()
            }
            .onDisappear {
                observerTokens.forEach { NotificationCenter.default.removeObserver($0) }
                observerTokens = []
            }
    }

    @ViewBuilder
    private var appInstructions: some View {
        let lines = importSource.steps.split(separator: "\n").map { String($0).trim() }
        VStack(alignment: .leading, spacing: 20) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(style: .subheadline, maxSizeCategory: .extraExtraExtraLarge)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Result/progress display shared by the URL and file import paths.
    @ViewBuilder
    private var importResultView: some View {
        switch opmlImportResult {
        case .none: EmptyView()
        case .success:
            Text(L10n.opmlImportSucceededTitle)
                .foregroundColor((ThemeColor.support02(for: theme.activeTheme).color))
        case .failure:
            Text(L10n.opmlImportFailedTitle)
                .foregroundColor(ThemeColor.support05(for: theme.activeTheme).color)
        }

        if opmlImportInProgress {
            ProgressView(L10n.opmlImporting)
        }
    }

    @ViewBuilder
    private var opmlImportView: some View {
        VStack {
            TextField("https://...", text: $opmlURLText)
                .autocapitalization(.none)
                .requiredStyle(opmlImportResult == .failure)
                .keyboardType(.URL)
                .accessibilityLabel(L10n.importOpmlUrlFieldAccessibilityLabel)
                .accessibilityIdentifier("import_opml_url")

            importResultView
        }
    }

    /// Result/progress display for the local OPML file import.
    private var fileImportView: some View {
        importResultView
    }

    private func dismissSelf() {
        if let navigationController = viewModel.navigationController {
            navigationController.dismiss(animated: true)
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private var fileImportButton: some View {
        Button(action: {
            if opmlImportResult == .success {
                dismissSelf()
                return
            }
            showOpmlFileImporter = true
        }, label: {
            Text(opmlImportResult == .success ? L10n.done : L10n.importOpmlChooseFile)
        })
        .buttonStyle(RoundedButtonStyle(theme: theme))
        .padding([.leading, .trailing], Constants.horizontalPadding)
        .accessibilityIdentifier("import_opml_file")
        .fileImporter(isPresented: $showOpmlFileImporter, allowedContentTypes: Self.opmlContentTypes) { result in
            switch result {
            case .success(let url):
                opmlImportResult = .none
                opmlImportInProgress = true
                viewModel.importFromFile(url) { success in
                    if !success {
                        opmlImportResult = .failure
                        opmlImportInProgress = false
                    }
                }
            case .failure:
                opmlImportResult = .failure
                opmlImportInProgress = false
            }
        }
    }

    /// Listens for the completion/failure notifications posted by the OPML importer.
    /// Registered once in `.onAppear`; tokens removed in `.onDisappear`.
    private func observeOpmlImportNotifications() {
        observerTokens.append(NotificationCenter.default.addObserver(forName: podcasts.Constants.Notifications.opmlImportCompleted, object: nil, queue: nil) { _ in
            opmlImportResult = .success
            opmlImportInProgress = false
        })
        observerTokens.append(NotificationCenter.default.addObserver(forName: podcasts.Constants.Notifications.opmlImportFailed, object: nil, queue: nil) { _ in
            opmlImportResult = .failure
            opmlImportInProgress = false
        })
    }

    /// OPML has no system-provided UTType; accept files with an `.opml` extension
    /// (conforming to XML) plus plain XML as a fallback.
    private static var opmlContentTypes: [UTType] {
        var types: [UTType] = []
        if let opml = UTType(tag: "opml", tagClass: .filenameExtension, conformingTo: .xml) {
            types.append(opml)
        }
        types.append(.xml)
        return types
    }

    private var opmlViewButton: some View {
        Button(action: {
            if opmlImportResult == .success {
                dismissSelf()
                return
            }
            opmlImportResult = .none

            guard let url = URL(string: opmlURLText) else {
                opmlImportResult = .failure
                opmlImportInProgress = false
                return
            }

            opmlImportInProgress = true
            viewModel.importFromURL(url) { success in
                if !success {
                    opmlImportResult = .failure
                    opmlImportInProgress = false
                }
            }
        }, label: {
            Text(opmlImportResult == .success ? L10n.done : L10n.import)
        })
        .buttonStyle(RoundedButtonStyle(theme: theme))
        .padding([.leading, .trailing], Constants.horizontalPadding)
    }

    private enum Constants {
        static let horizontalPadding = 24.0
    }
}
