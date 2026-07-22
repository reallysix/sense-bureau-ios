import Charts
import SwiftData
import SwiftUI

struct VibrationScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: VibrationViewModel
    @State private var recordSaveState: SensorRecordSaveState = .ready

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: SenseTheme.Spacing.medium) {
                    SensorModuleHeader(
                        status: localizedStatus,
                        title: settings.text("vibration.title"),
                        module: settings.text("vibration.module")
                    )
                    VibrationSignalPanel(model: model)
                    SensorStateNotice(state: model.state)
                    VibrationMetricStrip(model: model)
                    VibrationHistoryPanel(samples: model.samples)
                    SensorDemoNote(isDemo: model.isDemo)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VibrationControlDeck(
                model: model,
                recordSaveState: recordSaveState,
                onSave: saveRecord
            )
        }
    }

    private func saveRecord() {
        guard !model.samples.isEmpty, recordSaveState != .saved else { return }
        let record = MeasurementRecord(
            kind: .vibration,
            value: model.rmsMagnitude,
            unit: "mg RMS",
            peakValue: model.peakMagnitude
        )

        do {
            try MeasurementRecordStore(context: modelContext).save(record)
            recordSaveState = .saved
        } catch {
            recordSaveState = .failed
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            recordSaveState = .ready
        }
    }

    private var localizedStatus: String {
        if recordSaveState == .saved { return settings.text("status.saved") }
        if recordSaveState == .failed { return settings.text("status.saveError") }
        return switch model.state {
        case .idle: settings.text("status.ready")
        case let .calibrating(progress): settings.text("status.calibrating", Int(progress * 100))
        case .active: settings.text(model.isDemo ? "status.demo" : "status.live")
        case .paused: settings.text("status.paused")
        case .unsupported: settings.text("status.unsupported")
        case .denied: settings.text("status.denied")
        case .failed: settings.text("status.error")
        }
    }
}

private struct VibrationSignalPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: VibrationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            HStack {
                Text(settings.text("vibration.current"))
                    .font(SenseTheme.Typography.instrument(12))
                    .tracking(1.2)
                Spacer()
                Text(settings.text(intensityKey))
                    .font(SenseTheme.Typography.instrument(11))
                    .tracking(1.2)
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(model.state.preventsMeasurementDisplay ? "—" : String(Int(model.currentMagnitude.rounded())))
                    .font(SenseTheme.Typography.displayDot(72))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("mg")
                    .font(SenseTheme.Typography.instrument(16))
                    .padding(.bottom, 9)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(settings.text("vibration.accessibility.current", Int(model.currentMagnitude.rounded())))
            .accessibilityIdentifier("vibration.current")

            Chart(Array(model.samples.suffix(44))) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Vibration", sample.magnitude)
                )
                .foregroundStyle(theme.colors.textOnSignal)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 92)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.colors.textOnSignal.opacity(0.3))
                    .frame(height: 1)
            }
        }
        .foregroundStyle(theme.colors.textOnSignal)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 284, alignment: .topLeading)
        .background(theme.colors.signalPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var intensityKey: String {
        switch model.currentMagnitude {
        case ..<8: "vibration.level.still"
        case ..<30: "vibration.level.light"
        default: "vibration.level.strong"
        }
    }
}

private struct VibrationMetricStrip: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: VibrationViewModel

    var body: some View {
        HStack(spacing: 0) {
            metric(settings.text("vibration.rms"), model.rmsMagnitude, "mg")
            divider
            metric(settings.text("vibration.peak"), model.peakMagnitude, "mg")
            divider
            metric(settings.text("vibration.samples"), Double(model.samples.count), "")
        }
        .frame(minHeight: 96)
        .background(theme.colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private func metric(_ label: String, _ value: Double, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(SenseTheme.Typography.instrument(9))
                .tracking(0.8)
                .foregroundStyle(theme.colors.textSecondary)
            Text(String(Int(value.rounded())))
                .font(SenseTheme.Typography.instrument(24, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(theme.colors.textPrimary)
            Text(unit)
                .font(SenseTheme.Typography.instrument(8))
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SenseTheme.Spacing.medium)
    }

    private var divider: some View {
        Rectangle().fill(theme.colors.strokeSubtle).frame(width: 1, height: 96)
    }
}

private struct VibrationHistoryPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let samples: [VibrationSample]

    var body: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            HStack {
                Text(settings.text("vibration.history"))
                Spacer()
                Text(settings.text("vibration.window"))
            }
            .font(SenseTheme.Typography.instrument(10))
            .tracking(1)

            Chart(samples) { sample in
                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Magnitude", sample.magnitude)
                )
                .foregroundStyle(theme.colors.textOnData.opacity(0.12))
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Magnitude", sample.magnitude)
                )
                .foregroundStyle(theme.colors.textOnData)
                .lineStyle(StrokeStyle(lineWidth: 1.8))
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(theme.colors.textOnData.opacity(0.14))
                    AxisValueLabel().foregroundStyle(theme.colors.textOnData.opacity(0.6))
                }
            }
            .frame(height: 150)
            .accessibilityIdentifier("vibration.history")
        }
        .foregroundStyle(theme.colors.textOnData)
        .padding(SenseTheme.Spacing.large)
        .background(theme.colors.surfaceData)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }
}

private struct VibrationControlDeck: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: VibrationViewModel
    let recordSaveState: SensorRecordSaveState
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.small) {
            Button(action: onSave) {
                SensorDeckButtonLabel(
                    title: settings.text("action.save"),
                    systemImage: "archivebox"
                )
            }
            .buttonStyle(deckStyle(isPrimary: false))
            .disabled(model.samples.isEmpty || recordSaveState == .saved)
            .accessibilityIdentifier("vibration.save")

            Button(action: model.calibrate) {
                SensorDeckButtonLabel(
                    title: settings.text("vibration.calibrate"),
                    systemImage: "scope"
                )
            }
            .buttonStyle(deckStyle(isPrimary: false))
            .disabled(model.state != .active)
            .accessibilityIdentifier("vibration.calibrate")

            Button(action: model.togglePause) {
                SensorDeckButtonLabel(
                    title: settings.text(model.state == .paused ? "action.resume" : "action.pause"),
                    systemImage: model.state == .paused ? "play.fill" : "pause.fill"
                )
            }
            .buttonStyle(deckStyle(isPrimary: true))
            .disabled(model.state != .active && model.state != .paused)
            .accessibilityIdentifier("vibration.pause")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, SenseTheme.Spacing.small)
        .background(theme.colors.canvasPrimary)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.colors.strokeSubtle).frame(height: 1)
        }
    }

    private func deckStyle(isPrimary: Bool) -> SensorDeckButtonStyle {
        SensorDeckButtonStyle(isPrimary: isPrimary)
    }
}
