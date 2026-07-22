import SwiftUI

enum SensorHelpKind: String {
    case magnetic
    case vibration
    case level
    case barometer

    var icon: String {
        switch self {
        case .magnetic: "scope"
        case .vibration: "waveform"
        case .level: "level"
        case .barometer: "gauge.with.needle"
        }
    }

    var keyPrefix: String { "help.\(rawValue)" }
}

struct SensorHelpCard: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme

    let kind: SensorHelpKind
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: SenseTheme.Spacing.medium) {
                Image(systemName: kind.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.colors.textOnSignal)
                    .frame(width: 46, height: 46)
                    .background(theme.colors.signalPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                VStack(alignment: .leading, spacing: SenseTheme.Spacing.xSmall) {
                    Text(settings.text("help.card.title"))
                        .font(SenseTheme.Typography.instrument(10))
                        .tracking(0.8)
                    Text(settings.text("\(kind.keyPrefix).summary"))
                        .font(.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.colors.signalPrimary)
            }
            .foregroundStyle(theme.colors.textPrimary)
            .padding(SenseTheme.Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
            .background(theme.colors.surfacePrimary)
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius.medium)
                    .stroke(theme.colors.strokeSubtle, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(settings.text("help.open.accessibility", settings.text("\(kind.keyPrefix).title")))
        .accessibilityIdentifier("help.card.\(kind.rawValue)")
    }
}

struct SensorHelpScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.senseTheme) private var theme

    let kind: SensorHelpKind

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: SenseTheme.Spacing.medium) {
                        hero
                        helpSection(titleKey: "help.useCases", keys: numberedKeys("use", count: 3))
                        helpSection(titleKey: "help.steps", keys: numberedKeys("step", count: 3), numbered: true)
                        if kind == .barometer {
                            barometerReadingGuide
                        }
                        helpSection(titleKey: "help.limits", keys: numberedKeys("limit", count: 2))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, SenseTheme.Spacing.medium)
                    .padding(.bottom, SenseTheme.Spacing.xLarge)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(settings.text("help.title"))
                .font(SenseTheme.Typography.instrument(15))
                .tracking(1.8)
                .accessibilityIdentifier("help.title")
            Spacer()
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(theme.colors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
            }
            .accessibilityLabel(settings.text("help.close"))
            .accessibilityIdentifier("help.close")
        }
        .foregroundStyle(theme.colors.textPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, SenseTheme.Spacing.small)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.colors.strokeSubtle).frame(height: 1)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.large) {
            Image(systemName: kind.icon)
                .font(.system(size: 30, weight: .semibold))
            Text(settings.text("\(kind.keyPrefix).title"))
                .font(SenseTheme.Typography.instrument(23))
                .tracking(1.2)
            Text(settings.text("\(kind.keyPrefix).summary"))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(theme.colors.textOnSignal)
        .padding(SenseTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, minHeight: 196, alignment: .leading)
        .background(theme.colors.signalPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.large))
    }

    private func helpSection(titleKey: String, keys: [String], numbered: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            Text(settings.text(titleKey))
                .font(SenseTheme.Typography.instrument(11))
                .tracking(1.1)

            ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                HStack(alignment: .top, spacing: SenseTheme.Spacing.medium) {
                    Text(numbered ? String(index + 1) : "•")
                        .font(SenseTheme.Typography.instrument(12))
                        .foregroundStyle(theme.colors.signalPrimary)
                        .frame(width: 20, alignment: .leading)
                    Text(settings.text(key))
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .foregroundStyle(theme.colors.textPrimary)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var barometerReadingGuide: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            Text(settings.text("help.reference"))
                .font(SenseTheme.Typography.instrument(11))
                .tracking(1.1)

            referenceRow(icon: "water.waves", titleKey: "help.barometer.reference.pressure.title", detailKey: "help.barometer.reference.pressure.detail")
            referenceRow(icon: "ear", titleKey: "help.barometer.reference.body.title", detailKey: "help.barometer.reference.body.detail")
            referenceRow(icon: "arrow.up.and.down", titleKey: "help.barometer.reference.height.title", detailKey: "help.barometer.reference.height.detail")
        }
        .foregroundStyle(theme.colors.textOnData)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surfaceData)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
        .accessibilityIdentifier("help.barometer.reference")
    }

    private func referenceRow(icon: String, titleKey: String, detailKey: String) -> some View {
        HStack(alignment: .top, spacing: SenseTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: SenseTheme.Spacing.xSmall) {
                Text(settings.text(titleKey))
                    .font(.subheadline.weight(.semibold))
                Text(settings.text(detailKey))
                    .font(.footnote)
                    .opacity(0.72)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func numberedKeys(_ component: String, count: Int) -> [String] {
        (1...count).map { "\(kind.keyPrefix).\(component)\($0)" }
    }
}
