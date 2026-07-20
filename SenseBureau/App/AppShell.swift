import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case lab
    case field
    case settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .lab: "square.grid.2x2"
        case .field: "scope"
        case .settings: "gearshape"
        }
    }

    var titleKey: String {
        switch self {
        case .lab: "nav.lab"
        case .field: "nav.field"
        case .settings: "nav.settings"
        }
    }
}

struct AppShell: View {
    @Environment(\.senseTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var magneticModel = MagneticFieldViewModel()
    @State private var selection: AppSection = .lab

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            switch selection {
            case .lab:
                LabHomeScreen {
                    select(.field)
                }
            case .field:
                MagneticFieldScreen(model: magneticModel)
            case .settings:
                SettingsScreen(
                    previewValue: Int(magneticModel.fieldStrength.rounded()),
                    showsCloseButton: false
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppNavigationBar(selection: $selection)
        }
        .onAppear(perform: updateMeasurementActivity)
        .onChange(of: selection) { _, _ in
            updateMeasurementActivity()
        }
        .onChange(of: scenePhase) { _, _ in
            updateMeasurementActivity()
        }
    }

    private func select(_ section: AppSection) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            selection = section
        }
    }

    private func updateMeasurementActivity() {
        if selection == .field, scenePhase == .active {
            magneticModel.start()
        } else {
            magneticModel.stop()
        }
    }
}

private struct AppNavigationBar: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @Binding var selection: AppSection

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon)
                            .font(.system(size: 17, weight: .semibold))
                        Text(settings.text(section.titleKey))
                            .font(SenseTheme.Typography.instrument(9))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        selection == section
                            ? theme.colors.signalPrimary
                            : theme.colors.navigationText
                    )
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("nav.\(section.rawValue)")
                .accessibilityValue(
                    selection == section ? settings.text("nav.selected") : ""
                )
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 64)
        .background(theme.colors.navigationSurface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.navigation))
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(theme.colors.canvasPrimary)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.colors.strokeSubtle)
                .frame(height: 1)
        }
    }
}
