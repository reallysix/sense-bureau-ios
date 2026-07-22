import SwiftData
import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.senseTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [MeasurementRecord]
    @State private var isConfirmingDelete = false
    @State private var dataClearFailed = false

    let previewValue: Int
    let showsCloseButton: Bool

    init(previewValue: Int, showsCloseButton: Bool = true) {
        self.previewValue = previewValue
        self.showsCloseButton = showsCloseButton
    }

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: SenseTheme.Spacing.xLarge) {
                        settingsSection(title: settings.text("settings.language.section")) {
                            VStack(spacing: 1) {
                                ForEach(AppLanguage.allCases) { language in
                                    languageRow(language)
                                }
                            }
                            .background(theme.colors.strokeSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                            Text(settings.text("settings.language.description"))
                                .font(.footnote)
                                .foregroundStyle(theme.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        settingsSection(title: settings.text("settings.measurement.section")) {
                            VStack(spacing: 1) {
                                SettingToggleRow(
                                    title: settings.text("settings.sound"),
                                    systemImage: "speaker.wave.2",
                                    isOn: $settings.soundEnabled
                                )
                                .accessibilityIdentifier("settings.sound")

                                SettingToggleRow(
                                    title: settings.text("settings.haptics"),
                                    systemImage: "iphone.radiowaves.left.and.right",
                                    isOn: $settings.hapticsEnabled
                                )
                                .accessibilityIdentifier("settings.haptics")
                            }
                            .background(theme.colors.strokeSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                            VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
                                HStack {
                                    Label(
                                        settings.text("settings.threshold"),
                                        systemImage: "gauge.with.needle"
                                    )
                                    .font(.body.weight(.medium))
                                    Spacer()
                                    Text("\(Int(settings.alertThreshold)) μT")
                                        .font(SenseTheme.Typography.instrument(13))
                                        .foregroundStyle(theme.colors.signalPrimary)
                                        .accessibilityIdentifier("thresholdValue")
                                }

                                Slider(
                                    value: $settings.alertThreshold,
                                    in: 10...100,
                                    step: 5
                                )
                                .tint(theme.colors.signalPrimary)
                                .accessibilityIdentifier("settings.threshold")

                                HStack {
                                    Text("10 μT")
                                    Spacer()
                                    Text("100 μT")
                                }
                                .font(SenseTheme.Typography.instrument(9))
                                .foregroundStyle(theme.colors.textSecondary)
                            }
                            .foregroundStyle(theme.colors.textPrimary)
                            .padding(SenseTheme.Spacing.large)
                            .background(theme.colors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                            Text(settings.text("settings.measurement.description"))
                                .font(.footnote)
                                .foregroundStyle(theme.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        settingsSection(title: settings.text("settings.units.section")) {
                            VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
                                Label(
                                    settings.text("settings.pressureUnit"),
                                    systemImage: "gauge.with.needle"
                                )
                                .font(.body.weight(.medium))
                                .foregroundStyle(theme.colors.textPrimary)

                                HStack(spacing: SenseTheme.Spacing.small) {
                                    ForEach(PressureUnit.allCases) { unit in
                                        pressureUnitButton(unit)
                                    }
                                }
                            }
                            .padding(SenseTheme.Spacing.large)
                            .background(theme.colors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                            Text(settings.text("settings.units.description"))
                                .font(.footnote)
                                .foregroundStyle(theme.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        settingsSection(title: settings.text("settings.theme.section")) {
                            HStack(spacing: SenseTheme.Spacing.medium) {
                                ForEach(AppTheme.allCases) { option in
                                    ThemePreviewCard(
                                        name: settings.text(option.nameKey),
                                        reading: previewValue,
                                        theme: option.definition,
                                        isSelected: settings.theme == option
                                    ) {
                                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                                            settings.theme = option
                                        }
                                    }
                                    .accessibilityIdentifier("theme.\(option.rawValue)")
                                    .accessibilityValue(
                                        settings.theme == option
                                            ? settings.text("settings.theme.selected")
                                            : ""
                                    )
                                }
                            }

                            Text(settings.text("settings.theme.description"))
                                .font(.footnote)
                                .foregroundStyle(theme.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        settingsSection(title: settings.text("settings.capability.section")) {
                            VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
                                Label(
                                    settings.text("settings.capability.title"),
                                    systemImage: "info.circle"
                                )
                                .font(.body.weight(.semibold))
                                .foregroundStyle(theme.colors.textPrimary)

                                Text(settings.text("settings.capability.description"))
                                    .font(.footnote)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    settings.hasSeenMagneticGuide = false
                                } label: {
                                    Label(
                                        settings.text("settings.guide.show"),
                                        systemImage: "book.pages"
                                    )
                                    .font(SenseTheme.Typography.instrument(10))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(theme.colors.textOnSignal)
                                .background(theme.colors.signalPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                                .accessibilityIdentifier("settings.showGuide")
                            }
                            .padding(SenseTheme.Spacing.large)
                            .background(theme.colors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                        }

                        settingsSection(title: settings.text("settings.data.section")) {
                            VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
                                HStack {
                                    Label(
                                        settings.text("settings.data.title"),
                                        systemImage: "lock.shield"
                                    )
                                    .font(.body.weight(.semibold))
                                    Spacer()
                                    Text(settings.text("records.count", records.count))
                                        .font(SenseTheme.Typography.instrument(9))
                                        .foregroundStyle(theme.colors.textSecondary)
                                }

                                Text(settings.text("settings.data.description"))
                                    .font(.footnote)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    isConfirmingDelete = true
                                } label: {
                                    Label(
                                        settings.text("settings.data.clear"),
                                        systemImage: "trash"
                                    )
                                    .font(SenseTheme.Typography.instrument(10))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(theme.colors.critical)
                                .background(theme.colors.surfaceRaised)
                                .overlay {
                                    RoundedRectangle(cornerRadius: theme.radius.medium)
                                        .stroke(theme.colors.critical, lineWidth: 1)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                                .disabled(records.isEmpty)
                                .opacity(records.isEmpty ? 0.45 : 1)
                                .accessibilityIdentifier("settings.data.clear")

                                if dataClearFailed {
                                    Text(settings.text("settings.data.error"))
                                        .font(.footnote)
                                        .foregroundStyle(theme.colors.critical)
                                        .accessibilityIdentifier("settings.data.error")
                                }
                            }
                            .foregroundStyle(theme.colors.textPrimary)
                            .padding(SenseTheme.Spacing.large)
                            .background(theme.colors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, SenseTheme.Spacing.xLarge)
                    .padding(.bottom, SenseTheme.Spacing.xxLarge)
                }
            }
        }
        .alert(settings.text("settings.data.confirm.title"), isPresented: $isConfirmingDelete) {
            Button(settings.text("settings.data.confirm.cancel"), role: .cancel) {}
            Button(settings.text("settings.data.confirm.delete"), role: .destructive) {
                deleteAllRecords()
            }
        } message: {
            Text(settings.text("settings.data.confirm.message"))
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            Text(title)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(theme.colors.textSecondary)
            content()
        }
    }

    private var header: some View {
        HStack {
            Text(settings.text("settings.title"))
                .font(.system(.headline, design: .monospaced).weight(.semibold))
                .tracking(1.8)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityIdentifier("settingsTitle")

            Spacer()

            if showsCloseButton {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(theme.colors.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                }
                .accessibilityLabel(settings.text("settings.close"))
                .accessibilityIdentifier("closeSettingsButton")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, SenseTheme.Spacing.small)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.colors.strokeSubtle)
                .frame(height: 1)
        }
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            settings.language = language
        } label: {
            HStack(spacing: SenseTheme.Spacing.medium) {
                Text(language.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()

                if settings.language == language {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.colors.textOnSignal)
                        .frame(width: 28, height: 28)
                        .background(theme.colors.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
                        .accessibilityLabel(settings.text("settings.language.selected"))
                }
            }
            .padding(.horizontal, SenseTheme.Spacing.large)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .background(theme.colors.surfacePrimary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("language.\(language.rawValue)")
    }

    private func pressureUnitButton(_ unit: PressureUnit) -> some View {
        Button {
            settings.pressureUnit = unit
        } label: {
            Text(unit.symbol)
                .font(SenseTheme.Typography.instrument(11))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(
                    settings.pressureUnit == unit
                        ? theme.colors.textOnSignal
                        : theme.colors.textPrimary
                )
                .background(
                    settings.pressureUnit == unit
                        ? theme.colors.signalPrimary
                        : theme.colors.surfaceRaised
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings.pressureUnit.\(unit.rawValue)")
        .accessibilityValue(
            settings.pressureUnit == unit ? settings.text("settings.units.selected") : ""
        )
    }

    private func deleteAllRecords() {
        do {
            try MeasurementRecordStore(context: modelContext).deleteAll()
            dataClearFailed = false
        } catch {
            dataClearFailed = true
        }
    }
}

private struct SettingToggleRow: View {
    @Environment(\.senseTheme) private var theme
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(theme.colors.textPrimary)
        }
        .tint(theme.colors.signalPrimary)
        .padding(.horizontal, SenseTheme.Spacing.large)
        .frame(minHeight: 60)
        .background(theme.colors.surfacePrimary)
    }
}

private struct ThemePreviewCard: View {
    let name: String
    let reading: Int
    let theme: ThemeDefinition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SenseTheme.Spacing.small) {
                ZStack {
                    theme.colors.canvasPrimary

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            RoundedRectangle(cornerRadius: theme.radius.small)
                                .fill(theme.colors.surfaceRaised)
                                .frame(width: 34, height: 7)
                            Spacer()
                            Circle()
                                .fill(theme.colors.signalPrimary)
                                .frame(width: 9, height: 9)
                        }

                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text(String(reading))
                                .font(SenseTheme.Typography.displayDot(42))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("μT")
                                .font(SenseTheme.Typography.instrument(8))
                                .padding(.bottom, 5)
                        }
                        .foregroundStyle(theme.colors.textOnSignal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 9)
                        .frame(height: 56)
                        .background(theme.colors.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { index in
                                Capsule()
                                    .fill(index < 3 ? theme.colors.textOnData : theme.colors.strokeSubtle)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(10)
                }
                .frame(height: 106)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.colors.textOnSignal)
                            .frame(width: 20, height: 20)
                            .background(theme.colors.signalPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(8)
            .background(theme.colors.surfacePrimary)
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius.large)
                    .stroke(
                        isSelected ? theme.colors.signalPrimary : theme.colors.strokeSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.large))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .frame(maxWidth: .infinity)
    }
}
