import SwiftUI

struct LabHomeScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme

    let onOpenMagneticField: () -> Void
    let onOpenVibration: () -> Void
    let onOpenLevel: () -> Void
    let onOpenBarometer: () -> Void

    private var tools: [LabTool] {
        [
            LabTool(
                id: .magneticField,
                name: settings.text("tool.magnetic.name"),
                detail: settings.text("tool.magnetic.detail"),
                icon: "dot.radiowaves.left.and.right",
                status: settings.text("tool.status.ready"),
                isAvailable: true
            ),
            LabTool(
                id: .vibration,
                name: settings.text("tool.vibration.name"),
                detail: settings.text("tool.vibration.detail"),
                icon: "waveform",
                status: settings.text("tool.status.ready"),
                isAvailable: true
            ),
            LabTool(
                id: .level,
                name: settings.text("tool.level.name"),
                detail: settings.text("tool.level.detail"),
                icon: "level",
                status: settings.text("tool.status.ready"),
                isAvailable: true
            ),
            LabTool(
                id: .barometer,
                name: settings.text("tool.barometer.name"),
                detail: settings.text("tool.barometer.detail"),
                icon: "gauge.with.needle",
                status: settings.text("tool.status.ready"),
                isAvailable: true
            ),
        ]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: SenseTheme.Spacing.medium) {
                header
                heroPanel

                RecentRecordsSection()
                    .padding(.top, SenseTheme.Spacing.small)

                HStack {
                    Text(settings.text("home.tools"))
                        .font(SenseTheme.Typography.instrument(11))
                        .tracking(1.2)
                        .foregroundStyle(theme.colors.textPrimary)
                    Spacer()
                    Text(settings.text("home.readyCount", 4, tools.count))
                        .font(SenseTheme.Typography.instrument(9))
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(.top, SenseTheme.Spacing.small)

                VStack(spacing: SenseTheme.Spacing.small) {
                    ForEach(tools) { tool in
                        Button {
                            switch tool.id {
                            case .magneticField:
                                onOpenMagneticField()
                            case .vibration:
                                onOpenVibration()
                            case .level:
                                onOpenLevel()
                            case .barometer:
                                onOpenBarometer()
                            }
                        } label: {
                            LabToolCard(tool: tool)
                        }
                        .buttonStyle(.plain)
                        .disabled(!tool.isAvailable)
                        .accessibilityIdentifier("tool.\(tool.id.rawValue)")
                    }
                }

            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, SenseTheme.Spacing.xLarge)
        }
        .accessibilityIdentifier("labHomeScreen")
    }

    private var header: some View {
        HStack(spacing: SenseTheme.Spacing.small) {
            Text(settings.text("home.status"))
                .font(SenseTheme.Typography.instrument(10))
                .tracking(0.9)
                .foregroundStyle(theme.colors.textOnSignal)
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(theme.colors.signalPrimary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))

            Spacer(minLength: 8)

            Text(settings.text("home.title"))
                .font(SenseTheme.Typography.instrument(14))
                .tracking(2.2)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .accessibilityIdentifier("homeTitle")

            Spacer(minLength: 8)

            Text(settings.text("home.module"))
                .font(SenseTheme.Typography.instrument(10))
                .tracking(0.9)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(theme.colors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
        }
        .frame(height: 36)
    }

    private var heroPanel: some View {
        HStack(alignment: .bottom, spacing: SenseTheme.Spacing.large) {
            VStack(alignment: .leading, spacing: SenseTheme.Spacing.small) {
                Text(settings.text("home.hero.title"))
                    .font(SenseTheme.Typography.instrument(12))
                    .tracking(1.2)

                Text(settings.text("home.hero.detail"))
                    .font(.system(size: 14, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.74)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(String(tools.count))
                    .font(SenseTheme.Typography.displayDot(72))
                Text(settings.text("home.hero.unit"))
                    .font(SenseTheme.Typography.instrument(10))
                    .padding(.bottom, 9)
            }
        }
        .foregroundStyle(theme.colors.textOnSignal)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .bottomLeading)
        .background(theme.colors.signalPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }
}

private struct LabToolCard: View {
    @Environment(\.senseTheme) private var theme
    let tool: LabTool

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.medium) {
            Image(systemName: tool.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    tool.isAvailable
                        ? theme.colors.textOnSignal
                        : theme.colors.textSecondary
                )
                .frame(width: 44, height: 44)
                .background(
                    tool.isAvailable
                        ? theme.colors.signalPrimary
                        : theme.colors.surfaceRaised
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                Text(tool.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Text(tool.status)
                .font(SenseTheme.Typography.instrument(9))
                .tracking(0.6)
                .foregroundStyle(
                    tool.isAvailable
                        ? theme.colors.textOnSignal
                        : theme.colors.textSecondary
                )
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(
                    tool.isAvailable
                        ? theme.colors.signalPrimary
                        : theme.colors.surfaceRaised
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
        }
        .padding(.horizontal, SenseTheme.Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(theme.colors.surfacePrimary)
        .overlay {
            RoundedRectangle(cornerRadius: theme.radius.medium)
                .stroke(theme.colors.strokeSubtle, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
        .opacity(tool.isAvailable ? 1 : 0.76)
    }
}

private struct LabTool: Identifiable {
    let id: MeasurementKind
    let name: String
    let detail: String
    let icon: String
    let status: String
    let isAvailable: Bool
}
