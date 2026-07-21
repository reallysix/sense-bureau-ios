import Foundation
import SwiftData
import SwiftUI

struct LevelScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: LevelViewModel
    @State private var recordSaveState: SensorRecordSaveState = .ready

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: SenseTheme.Spacing.medium) {
                    SensorModuleHeader(
                        status: localizedStatus,
                        title: settings.text("level.title"),
                        module: settings.text("level.module")
                    )
                    LevelSignalPanel(model: model)
                    LevelAxisStrip(attitude: model.attitude)
                    LevelGuidancePanel(model: model)
                    SensorDemoNote(isDemo: model.isDemo)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LevelControlDeck(
                model: model,
                recordSaveState: recordSaveState,
                onSave: saveRecord
            )
        }
    }

    private func saveRecord() {
        guard (model.state == .active || model.state == .paused),
              recordSaveState != .saved else { return }
        let record = MeasurementRecord(
            kind: .level,
            value: model.tiltMagnitude,
            unit: "°"
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
        case let .calibrating(progress): settings.text("level.zeroing", Int(progress * 100))
        case .active: settings.text(model.isDemo ? "status.demo" : "status.live")
        case .paused: settings.text("status.paused")
        case .unsupported: settings.text("status.unsupported")
        case .failed: settings.text("status.error")
        }
    }
}

private struct LevelSignalPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: LevelViewModel

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: SenseTheme.Spacing.small) {
                Text(settings.text("level.tilt"))
                    .font(SenseTheme.Typography.instrument(12))
                    .tracking(1.2)
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(model.state == .unsupported ? "—" : String(format: "%.1f", model.tiltMagnitude))
                        .font(SenseTheme.Typography.displayDot(60))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("°")
                        .font(SenseTheme.Typography.instrument(18))
                        .padding(.bottom, 8)
                }
                Text(settings.text(levelKey))
                    .font(SenseTheme.Typography.instrument(11))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LevelBubble(attitude: model.attitude)
                .frame(width: 150, height: 150)
        }
        .foregroundStyle(theme.colors.textOnSignal)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 250)
        .background(theme.colors.signalPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.text("level.accessibility.tilt", model.tiltMagnitude))
        .accessibilityIdentifier("level.tilt")
    }

    private var levelKey: String {
        switch model.tiltMagnitude {
        case ..<0.5: "level.state.level"
        case ..<2: "level.state.near"
        default: "level.state.tilted"
        }
    }
}

private struct LevelBubble: View {
    @Environment(\.senseTheme) private var theme
    let attitude: LevelAttitude

    private var offset: CGSize {
        CGSize(
            width: min(1, max(-1, attitude.xDegrees / 15)) * 47,
            height: min(1, max(-1, attitude.yDegrees / 15)) * 47
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.colors.textOnSignal.opacity(0.42), lineWidth: 2)
            Circle()
                .stroke(theme.colors.textOnSignal.opacity(0.2), lineWidth: 1)
                .frame(width: 70, height: 70)
            Rectangle()
                .fill(theme.colors.textOnSignal.opacity(0.24))
                .frame(width: 1)
            Rectangle()
                .fill(theme.colors.textOnSignal.opacity(0.24))
                .frame(height: 1)
            Circle()
                .fill(theme.colors.textOnSignal)
                .frame(width: 24, height: 24)
                .offset(offset)
                .animation(.easeOut(duration: 0.16), value: offset)
        }
    }
}

private struct LevelAxisStrip: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let attitude: LevelAttitude

    var body: some View {
        HStack(spacing: 0) {
            axis(label: "X", value: attitude.xDegrees)
            Rectangle().fill(theme.colors.strokeSubtle).frame(width: 1, height: 84)
            axis(label: "Y", value: attitude.yDegrees)
        }
        .frame(minHeight: 84)
        .background(theme.colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private func axis(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(settings.text("level.axis", label))
                .font(SenseTheme.Typography.instrument(9))
                .foregroundStyle(theme.colors.textSecondary)
            Text(String(format: "%+.1f°", value))
                .font(SenseTheme.Typography.instrument(26, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(theme.colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SenseTheme.Spacing.large)
        .accessibilityIdentifier("level.axis.\(label.lowercased())")
    }
}

private struct LevelGuidancePanel: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: LevelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            HStack {
                Text(settings.text("level.guidance"))
                    .font(SenseTheme.Typography.instrument(10))
                    .tracking(1)
                Spacer()
                Image(systemName: model.tiltMagnitude < 0.5 ? "checkmark.circle.fill" : "arrow.up.and.down.and.arrow.left.and.right")
            }
            Text(settings.text(guidanceKey))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text(settings.text("level.zero.description"))
                .font(.footnote)
                .foregroundStyle(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(theme.colors.textOnData)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surfaceData)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var guidanceKey: String {
        switch model.tiltMagnitude {
        case ..<0.5: "level.guidance.level"
        case ..<2: "level.guidance.near"
        default: "level.guidance.tilted"
        }
    }
}

private struct LevelControlDeck: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @ObservedObject var model: LevelViewModel
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
            .buttonStyle(SensorDeckButtonStyle(isPrimary: false))
            .disabled(
                (model.state != .active && model.state != .paused)
                    || recordSaveState == .saved
            )
            .accessibilityIdentifier("level.save")

            Button(action: model.zero) {
                SensorDeckButtonLabel(title: settings.text("level.zero"), systemImage: "scope")
            }
            .buttonStyle(SensorDeckButtonStyle(isPrimary: false))
            .disabled(model.state != .active)
            .accessibilityIdentifier("level.zero")

            Button(action: model.togglePause) {
                SensorDeckButtonLabel(
                    title: settings.text(model.state == .paused ? "action.resume" : "action.pause"),
                    systemImage: model.state == .paused ? "play.fill" : "pause.fill"
                )
            }
            .buttonStyle(SensorDeckButtonStyle(isPrimary: true))
            .disabled(model.state != .active && model.state != .paused)
            .accessibilityIdentifier("level.pause")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, SenseTheme.Spacing.small)
        .background(theme.colors.canvasPrimary)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.colors.strokeSubtle).frame(height: 1)
        }
    }

}
