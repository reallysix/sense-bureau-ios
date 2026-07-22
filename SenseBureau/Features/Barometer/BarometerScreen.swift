import Charts
import SwiftData
import SwiftUI

struct BarometerScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: BarometerViewModel
    @State private var recordSaveState: SensorRecordSaveState = .ready

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: SenseTheme.Spacing.medium) {
                    SensorModuleHeader(
                        status: localizedStatus,
                        title: settings.text("barometer.title"),
                        module: settings.text("barometer.module")
                    )
                    BarometerSignalPanel(model: model)
                    SensorStateNotice(state: model.state)
                    BarometerMetricStrip(model: model)
                    BarometerHistoryPanel(samples: model.samples)
                    if model.isDemo {
                        SensorDemoNote(
                            isDemo: true,
                            textKey: "barometer.demo.note"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BarometerControlDeck(
                model: model,
                recordSaveState: recordSaveState,
                onSave: saveRecord
            )
        }
    }

    private func saveRecord() {
        guard model.hasReading, recordSaveState != .saved else { return }
        let record = MeasurementRecord(
            kind: .barometer,
            value: model.pressureKPa,
            unit: "kPa"
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

private struct BarometerSignalPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: BarometerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            HStack {
                Text(settings.text("barometer.pressure"))
                Spacer()
                Text(settings.text(model.hasReading ? "barometer.state.tracking" : "barometer.state.waiting"))
            }
            .font(SenseTheme.Typography.instrument(11))
            .tracking(1.1)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(pressureText)
                    .font(SenseTheme.Typography.displayDot(62))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.67)
                Text(settings.pressureUnit.symbol)
                    .font(SenseTheme.Typography.instrument(15))
                    .padding(.bottom, 8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(settings.text(
                "barometer.accessibility.pressure",
                pressureValue,
                settings.pressureUnit.symbol
            ))
            .accessibilityIdentifier("barometer.pressure")

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(settings.text("barometer.relativeHeight"))
                    .font(SenseTheme.Typography.instrument(10))
                    .tracking(1)
                Spacer()
                Text(model.hasReading ? String(format: "%+.1f", model.relativeAltitudeMeters) : "—")
                    .font(SenseTheme.Typography.instrument(34, weight: .semibold))
                    .monospacedDigit()
                Text("m")
                    .font(SenseTheme.Typography.instrument(11))
                    .padding(.bottom, 4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("barometer.altitude")
        }
        .foregroundStyle(theme.colors.textOnSignal)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 248, alignment: .topLeading)
        .background(theme.colors.signalPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var pressureValue: Double {
        settings.pressureUnit.value(fromKPa: model.pressureKPa)
    }

    private var pressureText: String {
        guard model.hasReading, !model.state.preventsMeasurementDisplay else { return "—" }
        return String(format: settings.pressureUnit == .hectopascals ? "%.1f" : "%.2f", pressureValue)
    }
}

private struct BarometerMetricStrip: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: BarometerViewModel

    var body: some View {
        HStack(spacing: 0) {
            metric(
                settings.text("barometer.pressureChange"),
                pressureChangeText,
                settings.pressureUnit.symbol
            )
            Rectangle().fill(theme.colors.strokeSubtle).frame(width: 1, height: 90)
            metric(
                settings.text("barometer.peakHeight"),
                model.hasReading ? String(format: "%.1f", model.peakAltitudeMeters) : "—",
                "m"
            )
            Rectangle().fill(theme.colors.strokeSubtle).frame(width: 1, height: 90)
            metric(
                settings.text("barometer.samples"),
                model.hasReading ? String(model.samples.count) : "—",
                ""
            )
        }
        .frame(minHeight: 90)
        .background(theme.colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var pressureChangeText: String {
        guard model.hasReading else { return "—" }
        let value = settings.pressureUnit.value(fromKPa: model.pressureChangeKPa)
        return String(format: settings.pressureUnit == .hectopascals ? "%+.1f" : "%+.2f", value)
    }

    private func metric(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(SenseTheme.Typography.instrument(8))
                .tracking(0.6)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(SenseTheme.Typography.instrument(21, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(unit)
                .font(SenseTheme.Typography.instrument(8))
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SenseTheme.Spacing.medium)
    }
}

private struct BarometerHistoryPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let samples: [BarometerSample]

    var body: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            HStack {
                Text(settings.text("barometer.history"))
                Spacer()
                Text(settings.text("barometer.historyRange"))
            }
            .font(SenseTheme.Typography.instrument(10))
            .tracking(1)

            Chart {
                ForEach(samples) { sample in
                    AreaMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Height", sample.relativeAltitudeMeters)
                    )
                    .foregroundStyle(theme.colors.textOnData.opacity(0.12))
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Height", sample.relativeAltitudeMeters)
                    )
                    .foregroundStyle(theme.colors.textOnData)
                    .lineStyle(StrokeStyle(lineWidth: 1.8))
                }
                RuleMark(y: .value("Baseline", 0))
                    .foregroundStyle(theme.colors.signalPrimary.opacity(0.7))
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(theme.colors.textOnData.opacity(0.14))
                    AxisValueLabel().foregroundStyle(theme.colors.textOnData.opacity(0.65))
                }
            }
            .frame(height: 146)
            .accessibilityIdentifier("barometer.history")
        }
        .foregroundStyle(theme.colors.textOnData)
        .padding(SenseTheme.Spacing.large)
        .background(theme.colors.surfaceData)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }
}

private struct BarometerControlDeck: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: BarometerViewModel
    let recordSaveState: SensorRecordSaveState
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.small) {
            Button(action: onSave) {
                SensorDeckButtonLabel(title: settings.text("action.save"), systemImage: "archivebox")
            }
            .buttonStyle(SensorDeckButtonStyle(isPrimary: false))
            .disabled(!model.hasReading || recordSaveState == .saved)
            .accessibilityIdentifier("barometer.save")

            Button(action: model.setBaseline) {
                SensorDeckButtonLabel(title: settings.text("barometer.baseline"), systemImage: "scope")
            }
            .buttonStyle(SensorDeckButtonStyle(isPrimary: false))
            .disabled(model.state != .active || !model.hasReading)
            .accessibilityIdentifier("barometer.baseline")

            Button(action: model.togglePause) {
                SensorDeckButtonLabel(
                    title: settings.text(model.state == .paused ? "action.resume" : "action.pause"),
                    systemImage: model.state == .paused ? "play.fill" : "pause.fill"
                )
            }
            .buttonStyle(SensorDeckButtonStyle(isPrimary: true))
            .disabled(model.state != .active && model.state != .paused)
            .accessibilityIdentifier("barometer.pause")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, SenseTheme.Spacing.small)
        .background(theme.colors.canvasPrimary)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.colors.strokeSubtle).frame(height: 1)
        }
    }
}
