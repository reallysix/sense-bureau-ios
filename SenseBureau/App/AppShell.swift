import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case lab
    case field
    case vibration
    case level
    case settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .lab: "square.grid.2x2"
        case .field: "scope"
        case .vibration: "waveform"
        case .level: "level"
        case .settings: "gearshape"
        }
    }

    var titleKey: String {
        switch self {
        case .lab: "nav.lab"
        case .field: "nav.field"
        case .vibration: "nav.vibration"
        case .level: "nav.level"
        case .settings: "nav.settings"
        }
    }
}

struct AppShell: View {
    private enum LabRoute {
        case home
        case barometer
    }

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    @StateObject private var magneticModel = MagneticFieldViewModel()
    @StateObject private var vibrationModel = VibrationViewModel()
    @StateObject private var levelModel = LevelViewModel()
    @StateObject private var barometerModel = BarometerViewModel()
    @State private var selection: AppSection = .lab
    @State private var labRoute: LabRoute = .home
    @State private var didResetUITestRecords = false

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            switch selection {
            case .lab:
                switch labRoute {
                case .home:
                    LabHomeScreen(
                        onOpenMagneticField: { select(.field) },
                        onOpenVibration: { select(.vibration) },
                        onOpenLevel: { select(.level) },
                        onOpenBarometer: {
                            labRoute = .barometer
                        }
                    )
                case .barometer:
                    BarometerScreen(model: barometerModel)
                }
            case .field:
                MagneticFieldScreen(model: magneticModel)
            case .vibration:
                VibrationScreen(model: vibrationModel)
            case .level:
                LevelScreen(model: levelModel)
            case .settings:
                SettingsScreen(
                    previewValue: Int(magneticModel.fieldStrength.rounded()),
                    showsCloseButton: false
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppNavigationBar(selection: selection, onSelect: select)
        }
        .onAppear {
            resetRecordsForUITestsIfNeeded()
            updateMeasurementActivity()
        }
        .onChange(of: selection) { _, _ in
            updateMeasurementActivity()
        }
        .onChange(of: labRoute) { _, _ in
            updateMeasurementActivity()
        }
        .onChange(of: scenePhase) { _, _ in
            updateMeasurementActivity()
        }
        .onChange(of: settings.soundEnabled) { _, _ in
            updateMeasurementActivity()
        }
        .onChange(of: settings.hapticsEnabled) { _, _ in
            updateMeasurementActivity()
        }
        .onChange(of: settings.alertThreshold) { _, _ in
            updateMeasurementActivity()
        }
        .onChange(of: settings.hasSeenMagneticGuide) { _, _ in
            updateMeasurementActivity()
        }
    }

    private func select(_ section: AppSection) {
        if section == .lab {
            labRoute = .home
        }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            selection = section
        }
    }

    private func updateMeasurementActivity() {
        magneticModel.configureFeedback(
            soundEnabled: settings.soundEnabled,
            hapticsEnabled: settings.hapticsEnabled,
            alertThreshold: settings.alertThreshold
        )
        vibrationModel.configureFeedback(
            soundEnabled: settings.soundEnabled,
            hapticsEnabled: settings.hapticsEnabled
        )
        levelModel.configureFeedback(
            soundEnabled: settings.soundEnabled,
            hapticsEnabled: settings.hapticsEnabled
        )

        if selection == .field,
           scenePhase == .active,
           settings.hasSeenMagneticGuide {
            magneticModel.start()
        } else {
            magneticModel.stop()
        }

        if selection == .vibration, scenePhase == .active {
            vibrationModel.start()
        } else {
            vibrationModel.stop()
        }

        if selection == .level, scenePhase == .active {
            levelModel.start()
        } else {
            levelModel.stop()
        }

        if selection == .lab, labRoute == .barometer, scenePhase == .active {
            barometerModel.start()
        } else {
            barometerModel.stop()
        }
    }

    private func resetRecordsForUITestsIfNeeded() {
        #if DEBUG
        guard !didResetUITestRecords,
              ProcessInfo.processInfo.arguments.contains("-uiTestResetRecords") else { return }
        didResetUITestRecords = true
        try? MeasurementRecordStore(context: modelContext).deleteAll()
        #endif
    }
}

private struct AppNavigationBar: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let selection: AppSection
    let onSelect: (AppSection) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppSection.allCases) { section in
                Button {
                    onSelect(section)
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
