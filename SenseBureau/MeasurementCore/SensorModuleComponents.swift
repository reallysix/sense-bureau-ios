import SwiftUI

struct SensorModuleHeader: View {
    @Environment(\.senseTheme) private var theme

    let status: String
    let title: String
    let module: String

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.small) {
            Text(status)
                .font(SenseTheme.Typography.instrument(10))
                .tracking(0.9)
                .foregroundStyle(theme.colors.textOnSignal)
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(theme.colors.signalPrimary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
                .accessibilityIdentifier("sensor.status")

            Spacer(minLength: 8)

            Text(title)
                .font(SenseTheme.Typography.instrument(14))
                .tracking(2.0)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .accessibilityIdentifier("screenTitle")

            Spacer(minLength: 8)

            Text(module)
                .font(SenseTheme.Typography.instrument(10))
                .tracking(0.9)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(theme.colors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
        }
        .frame(height: 36)
    }
}

struct SensorDemoNote: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme

    let isDemo: Bool
    var textKey = "sensor.demo.note"

    var body: some View {
        if isDemo {
            Label(settings.text(textKey), systemImage: "waveform.path")
                .font(.footnote)
                .foregroundStyle(theme.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SenseTheme.Spacing.small)
        }
    }
}

struct SensorStateNotice: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme

    let state: MeasurementSessionState

    var body: some View {
        if let content {
            HStack(alignment: .top, spacing: SenseTheme.Spacing.medium) {
                Image(systemName: content.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.critical)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: SenseTheme.Spacing.xSmall) {
                    Text(settings.text(content.titleKey))
                        .font(.body.weight(.semibold))
                    Text(settings.text(content.detailKey))
                        .font(.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .foregroundStyle(theme.colors.textPrimary)
            .padding(SenseTheme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.surfacePrimary)
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius.medium)
                    .stroke(theme.colors.critical, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
            .accessibilityIdentifier("sensor.stateNotice")
        }
    }

    private var content: (titleKey: String, detailKey: String, icon: String)? {
        switch state {
        case .unsupported:
            ("sensor.unsupported.title", "sensor.unsupported.detail", "sensor.slash")
        case .denied:
            ("sensor.denied.title", "sensor.denied.detail", "hand.raised")
        case .failed:
            ("sensor.failed.title", "sensor.failed.detail", "exclamationmark.triangle")
        default:
            nil
        }
    }
}

enum SensorRecordSaveState {
    case ready
    case saved
    case failed
}

struct SensorDeckButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
            Text(title)
                .font(SenseTheme.Typography.instrument(9))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
    }
}

struct SensorDeckButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.senseTheme) private var theme
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isPrimary ? theme.colors.textOnSignal : theme.colors.textPrimary)
            .background(isPrimary ? theme.colors.signalPrimary : theme.colors.surfacePrimary)
            .overlay {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: theme.radius.medium)
                        .stroke(theme.colors.strokeSubtle, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.45)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1)
    }
}
