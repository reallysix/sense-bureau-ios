import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.senseTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let previewValue: Int

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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, SenseTheme.Spacing.xLarge)
                    .padding(.bottom, SenseTheme.Spacing.xxLarge)
                }
            }
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
