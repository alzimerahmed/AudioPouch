import PocketCastsServer
import PocketCastsUtils
import SwiftUI
import UniformTypeIdentifiers

/// Phase 6 (gap #4): gallery of built-in + user-imported themes.
/// Lists preview swatches, imports theme JSON via the file picker,
/// deletes user themes, and applies/selects themes.
struct ThemeGalleryView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject private var manager = CustomThemeManager.shared

    /// Called when a locked (Plus-only) built-in theme is tapped. The
    /// presenter is expected to dismiss the gallery and show the upsell,
    /// matching `ThemeSelectorView`'s gating.
    var onLockedTheme = {}

    /// Called by the close button — the presenter dismisses the modal.
    var dismissAction = {}

    @State private var showingImporter = false
    @State private var deleteCandidate: CustomThemeStore.Entry?
    @State private var errorTitle: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColor.primaryUi01(for: theme.activeTheme).color.ignoresSafeArea()

                List {
                    if !manager.themes.isEmpty {
                        Section(header: Text(L10n.themeGalleryImportedHeader)) {
                            ForEach(manager.themes) { entry in
                                row(
                                    title: entry.name,
                                    lightColor: entry.light[CustomThemeToken.primaryUi01.rawValue],
                                    darkColor: entry.dark[CustomThemeToken.primaryUi01.rawValue],
                                    accent: entry.accentColor,
                                    isSelected: manager.activeCustomTheme?.id == entry.id,
                                    isLocked: false,
                                    deletable: true
                                ) {
                                    manager.activate(entry)
                                } delete: {
                                    deleteCandidate = entry
                                }
                            }
                        }
                    }

                    Section(header: Text(L10n.themeGalleryBuiltInHeader)) {
                        ForEach(ThemeType.displayOrder, id: \.rawValue) { themeType in
                            let isLocked = themeType.isPlusOnly && !SubscriptionHelper.hasActiveSubscription()
                            row(
                                title: themeType.description,
                                lightColor: nil,
                                darkColor: nil,
                                accent: nil,
                                isSelected: manager.activeCustomTheme == nil && theme.activeTheme == themeType,
                                isLocked: isLocked,
                                deletable: false
                            ) {
                                if isLocked {
                                    onLockedTheme()
                                } else {
                                    manager.deactivate()
                                    if themeType.isDark {
                                        Theme.setPreferredDarkTheme(themeType, systemIsDark: Theme.systemIsDark, userInitiated: true)
                                    } else {
                                        Theme.setPreferredLightTheme(themeType, systemIsDark: Theme.systemIsDark)
                                    }
                                    theme.activeTheme = themeType
                                }
                            } delete: {}
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle(L10n.themeGalleryTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismissAction()
                    } label: {
                        Image("cancel")
                            .renderingMode(.template)
                    }
                    .navThemed()
                    .accessibilityLabel(L10n.accessibilityCloseDialog)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .accessibilityLabel(L10n.themeGalleryImport)
                    }
                }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            importTheme(result: result)
        }
        .alert(
            deleteCandidate?.name ?? "",
            isPresented: deleteBinding,
            actions: {
                Button(L10n.themeGalleryDelete, role: .destructive) {
                    if let candidate = deleteCandidate {
                        manager.delete(candidate)
                    }
                    deleteCandidate = nil
                }
                Button(L10n.cancel, role: .cancel) { deleteCandidate = nil }
            },
            message: {
                Text(L10n.themeGalleryDeleteConfirmMessage)
            }
        )
        .alert(errorTitle ?? L10n.themeGalleryErrorTitle, isPresented: errorBinding, actions: {}, message: {
            Text(errorMessage ?? "")
        })
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { deleteCandidate != nil }, set: { if !$0 { deleteCandidate = nil } })
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func row(title: String, lightColor: String?, darkColor: String?, accent: String?, isSelected: Bool, isLocked: Bool, deletable: Bool, apply: @escaping () -> Void, delete: @escaping () -> Void) -> some View {
        Button(action: apply) {
            HStack(spacing: 12) {
                ThemeSwatchView(
                    light: Self.color(lightColor, fallback: .systemBackground),
                    dark: Self.color(darkColor, fallback: .systemBackground),
                    accent: Self.color(accent, fallback: AppTheme.appTintColor)
                )
                .frame(width: 44, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ThemeColor.primaryUi05(for: theme.activeTheme).color, lineWidth: 1))
                .accessibilityHidden(true)

                Text(title)
                    .font(.body)
                    .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)

                Spacer()

                if isLocked {
                    Image("plusGoldCircle")
                        .accessibilityHidden(true)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(ThemeColor.primaryIcon02Selected(for: theme.activeTheme).color)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.5 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? L10n.themeGalleryCurrent : "")
        .accessibilityHint(isLocked ? L10n.accessibilityPlusOnly : "")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if deletable {
                Button(role: .destructive) {
                    delete()
                } label: {
                    Label(L10n.themeGalleryDelete, systemImage: "trash")
                }
            }
        }
    }

    private func importTheme(result: Result<URL, Error>) {
        switch result {
        case .failure:
            errorTitle = L10n.themeGalleryErrorTitle
            errorMessage = L10n.themeGalleryInvalidFile
        case .success(let url):
            let secured = url.startAccessingSecurityScopedResource()
            defer {
                if secured { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                _ = try manager.importTheme(from: data)
            } catch {
                errorTitle = L10n.themeGalleryErrorTitle
                errorMessage = Self.message(for: error)
            }
        }
    }

    private static func message(for error: Error) -> String {
        switch error as? CustomThemeError {
        case .decodingFailed, .none:
            L10n.themeGalleryInvalidFile
        case .unsupportedVersion:
            L10n.themeGalleryInvalidVersion
        case .missingPalette, .missingToken:
            L10n.themeGalleryMissingColors
        case .invalidColor:
            L10n.themeGalleryInvalidColor
        case .missingName, .nameTooLong:
            L10n.themeGalleryMissingName
        case .insufficientContrast:
            L10n.themeGalleryInsufficientContrast
        }
    }

    private static func color(_ hex: String?, fallback: UIColor) -> Color {
        Color(uiColor: hex.flatMap { CustomThemeManager.color(fromHex: $0) } ?? fallback)
    }
}

/// Light/dark swatch pair with an accent stripe, used for theme previews.
struct ThemeSwatchView: View {
    let light: Color
    let dark: Color
    let accent: Color

    var body: some View {
        HStack(spacing: 0) {
            light
            dark
        }
        .overlay(alignment: .bottom) {
            accent.frame(height: 5)
        }
    }
}
