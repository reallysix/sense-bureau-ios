import Charts
import SwiftUI

struct MagneticFieldScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @StateObject private var model = MagneticFieldViewModel()
    @State private var isShowingSettings = false

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: SenseTheme.Spacing.medium) {
                    InstrumentHeader(
                        status: localizedStatus,
                        title: settings.text("screen.title"),
                        module: settings.text("screen.module"),
                        settingsLabel: settings.text("settings.open"),
                        onShowSettings: { isShowingSettings = true }
                    )
                    SignalPanel(model: model)
                    MetricStrip(model: model)
                    HistoryPanel(samples: model.samples)
                    CapabilityNote(isDemo: model.isDemo)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ControlDeck(model: model)
        }
        .task { model.start() }
        .onDisappear { model.stop() }
        .sheet(isPresented: $isShowingSettings) {
            SettingsScreen(previewValue: Int(model.fieldStrength.rounded()))
                .environmentObject(settings)
        }
    }

    private var localizedStatus: String {
        switch model.state {
        case .idle:
            settings.text("status.ready")
        case let .calibrating(progress):
            settings.text("status.calibrating", Int(progress * 100))
        case .active:
            settings.text(model.isDemo ? "status.demo" : "status.live")
        case .paused:
            settings.text("status.paused")
        case .unsupported:
            settings.text("status.unsupported")
        case .failed:
            settings.text("status.error")
        }
    }
}

private struct InstrumentHeader: View {
    @Environment(\.senseTheme) private var theme
    let status: String
    let title: String
    let module: String
    let settingsLabel: String
    let onShowSettings: () -> Void

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.small) {
            TagLabel(text: status, emphasized: true)
            Spacer(minLength: 8)
            Text(title)
                .font(SenseTheme.Typography.instrument(14))
                .tracking(2.2)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("screenTitle")
            Spacer(minLength: 8)
            HStack(spacing: SenseTheme.Spacing.xSmall) {
                TagLabel(text: module)
                Button(action: onShowSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.colors.textPrimary)
                        .frame(width: 36, height: 28)
                        .background(theme.colors.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
                }
                .accessibilityLabel(settingsLabel)
                .accessibilityIdentifier("settingsButton")
            }
        }
        .frame(height: 36)
    }
}

private struct TagLabel: View {
    @Environment(\.senseTheme) private var theme
    let text: String
    var emphasized = false

    var body: some View {
        Text(text)
            .font(SenseTheme.Typography.instrument(10))
            .tracking(0.9)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(emphasized ? theme.colors.textOnSignal : theme.colors.textSecondary)
            .padding(.horizontal, 9)
            .frame(height: 28)
            .background(emphasized ? theme.colors.signalPrimary : theme.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
    }
}

private struct SignalPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: MagneticFieldViewModel

    private var normalizedChange: Double {
        min(1, model.relativeChange / 70)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(settings.text("screen.fieldStrength"))
                    .font(SenseTheme.Typography.instrument(12))
                    .tracking(1.2)
                Spacer()
                Text(localizedSignalLevel)
                    .font(SenseTheme.Typography.instrument(11))
                    .tracking(1.2)
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(model.state == .unsupported ? "—" : String(Int(model.fieldStrength.rounded())))
                    .font(SenseTheme.Typography.displayDot(76))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("μT")
                    .font(SenseTheme.Typography.instrument(17))
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(settings.text("accessibility.fieldStrength", Int(model.fieldStrength.rounded())))

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    SmallReading(label: settings.text("screen.delta"), value: model.relativeChange, unit: "μT")
                    SmallReading(label: settings.text("screen.alert"), value: model.alertThreshold, unit: "μT")
                }
                .padding(.bottom, 14)

                Spacer(minLength: 0)

                RadialFieldGauge(progress: normalizedChange, value: model.relativeChange)
                    .frame(width: 188, height: 188)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(theme.colors.textOnSignal)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 326, alignment: .topLeading)
        .background(theme.colors.signalPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var localizedSignalLevel: String {
        switch model.relativeChange {
        case ..<12:
            settings.text("signal.low")
        case ..<model.alertThreshold:
            settings.text("signal.medium")
        default:
            settings.text("signal.strong")
        }
    }
}

private struct SmallReading: View {
    let label: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(SenseTheme.Typography.instrument(10))
                .tracking(1)
                .opacity(0.64)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(String(Int(value.rounded())))
                    .font(SenseTheme.Typography.instrument(22, weight: .bold))
                    .monospacedDigit()
                Text(unit)
                    .font(SenseTheme.Typography.instrument(10))
            }
        }
    }
}

private struct RadialFieldGauge: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let progress: Double
    let value: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.colors.canvasPrimary)
                .overlay {
                    Circle().stroke(theme.colors.textOnSignal, lineWidth: 2)
                }

            ForEach(0..<48, id: \.self) { index in
                let isMajor = index.isMultiple(of: 6)
                let isActive = Double(index) / 47 <= progress
                Capsule()
                    .fill(isActive ? theme.colors.signalPrimary : theme.colors.strokeSubtle)
                    .frame(width: isMajor ? 3 : 1.5, height: isMajor ? 17 : 10)
                    .offset(y: -78)
                    .rotationEffect(.degrees(Double(index) * 7.5))
            }

            VStack(spacing: 2) {
                Text(settings.text("screen.delta"))
                    .font(SenseTheme.Typography.instrument(10))
                    .tracking(1.4)
                    .foregroundStyle(theme.colors.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(Int(value.rounded())))
                        .font(SenseTheme.Typography.instrument(38, weight: .medium))
                        .monospacedDigit()
                    Text("μT")
                        .font(SenseTheme.Typography.instrument(10))
                }
                .foregroundStyle(theme.colors.textPrimary)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct MetricStrip: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: MagneticFieldViewModel

    var body: some View {
        HStack(spacing: 1) {
            MetricCell(label: settings.text("screen.base"), value: model.baseline)
            MetricCell(label: settings.text("screen.peak"), value: model.peakChange)
            MetricCell(label: settings.text("screen.samples"), text: String(model.samples.count))
        }
        .background(theme.colors.strokeSubtle)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }
}

private struct MetricCell: View {
    @Environment(\.senseTheme) private var theme
    let label: String
    var value: Double?
    var text: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SenseTheme.Typography.instrument(9))
                .tracking(0.9)
                .foregroundStyle(theme.colors.textSecondary)
            Text(text ?? String(Int((value ?? 0).rounded())))
                .font(SenseTheme.Typography.instrument(22, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(theme.colors.textPrimary)
            if value != nil {
                Text("μT")
                    .font(SenseTheme.Typography.instrument(9))
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .padding(.horizontal, 12)
        .background(theme.colors.surfacePrimary)
    }
}

private struct HistoryPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let samples: [MagneticFieldSample]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(settings.text("screen.history"))
                    .font(SenseTheme.Typography.instrument(11))
                    .tracking(1.2)
                Spacer()
                Text(settings.text("screen.historyRange"))
                    .font(SenseTheme.Typography.instrument(9))
                    .tracking(0.8)
                    .opacity(0.62)
            }

            Chart {
                ForEach(samples) { sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Delta", sample.magnitude)
                    )
                    .foregroundStyle(theme.colors.textOnData)
                    .lineStyle(StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                }
                RuleMark(y: .value("Alert", 30))
                    .foregroundStyle(theme.colors.signalPrimary.opacity(0.9))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6))
                        .foregroundStyle(theme.colors.textOnData.opacity(0.28))
                    AxisValueLabel()
                        .font(SenseTheme.Typography.instrument(8))
                        .foregroundStyle(theme.colors.textOnData.opacity(0.68))
                }
            }
            .chartYScale(domain: 0...max(40, (samples.map(\.magnitude).max() ?? 40) * 1.15))
            .frame(height: 106)
        }
        .foregroundStyle(theme.colors.textOnData)
        .padding(14)
        .background(theme.colors.surfaceData)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(settings.text("accessibility.history", samples.count))
    }
}

private struct CapabilityNote: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let isDemo: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isDemo ? "waveform.path.ecg" : "info.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.colors.signalPrimary)
                .accessibilityHidden(true)
            Text(settings.text(isDemo ? "screen.capability.demo" : "screen.capability.real"))
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }
}

private struct ControlDeck: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: MagneticFieldViewModel

    var body: some View {
        HStack(spacing: 10) {
            Button(action: model.calibrate) {
                Label(settings.text("action.calibrate"), systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InstrumentButtonStyle(kind: .secondary))
            .accessibilityIdentifier("calibrateButton")
            .disabled(model.state == .unsupported)

            Button(action: model.togglePause) {
                Label(
                    settings.text(model.state == .paused ? "action.resume" : "action.pause"),
                    systemImage: model.state == .paused ? "play.fill" : "pause.fill"
                )
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InstrumentButtonStyle(kind: .primary))
            .accessibilityIdentifier("pauseResumeButton")
            .disabled(model.state != .active && model.state != .paused)
        }
        .font(SenseTheme.Typography.instrument(11))
        .tracking(0.7)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(theme.colors.canvasPrimary)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.colors.strokeSubtle)
                .frame(height: 1)
        }
    }
}

private struct InstrumentButtonStyle: ButtonStyle {
    @Environment(\.senseTheme) private var theme
    enum Kind { case primary, secondary }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(kind == .primary ? theme.colors.textOnSignal : theme.colors.textPrimary)
            .frame(height: 48)
            .background(kind == .primary ? theme.colors.signalPrimary : theme.colors.surfacePrimary)
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius.medium)
                    .stroke(kind == .primary ? Color.clear : theme.colors.strokeSubtle, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
