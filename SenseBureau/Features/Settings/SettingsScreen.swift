import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TechSignalTheme.Colors.canvasPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: TechSignalTheme.Spacing.medium) {
                        Text(settings.text("settings.language.section"))
                            .font(.system(.caption, design: .monospaced).weight(.semibold))
                            .tracking(1.2)
                            .foregroundStyle(TechSignalTheme.Colors.textSecondary)

                        VStack(spacing: 1) {
                            ForEach(AppLanguage.allCases) { language in
                                languageRow(language)
                            }
                        }
                        .background(TechSignalTheme.Colors.strokeSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: TechSignalTheme.Radius.medium))

                        Text(settings.text("settings.language.description"))
                            .font(.footnote)
                            .foregroundStyle(TechSignalTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, TechSignalTheme.Spacing.xLarge)
                    .padding(.bottom, TechSignalTheme.Spacing.xxLarge)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            Text(settings.text("settings.title"))
                .font(.system(.headline, design: .monospaced).weight(.semibold))
                .tracking(1.8)
                .foregroundStyle(TechSignalTheme.Colors.textPrimary)
                .accessibilityIdentifier("settingsTitle")

            Spacer()

            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(TechSignalTheme.Colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(TechSignalTheme.Colors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: TechSignalTheme.Radius.medium))
            }
            .accessibilityLabel(settings.text("settings.close"))
            .accessibilityIdentifier("closeSettingsButton")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, TechSignalTheme.Spacing.small)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TechSignalTheme.Colors.strokeSubtle)
                .frame(height: 1)
        }
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            settings.language = language
        } label: {
            HStack(spacing: TechSignalTheme.Spacing.medium) {
                Text(language.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(TechSignalTheme.Colors.textPrimary)

                Spacer()

                if settings.language == language {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TechSignalTheme.Colors.textOnSignal)
                        .frame(width: 28, height: 28)
                        .background(TechSignalTheme.Colors.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: TechSignalTheme.Radius.small))
                        .accessibilityLabel(settings.text("settings.language.selected"))
                }
            }
            .padding(.horizontal, TechSignalTheme.Spacing.large)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .background(TechSignalTheme.Colors.surfacePrimary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("language.\(language.rawValue)")
    }
}
