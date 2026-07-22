import SwiftData
import SwiftUI

struct RecentRecordsSection: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    @Query(sort: \MeasurementRecord.capturedAt, order: .reverse) private var records: [MeasurementRecord]
    @State private var isShowingAllRecords = false

    var body: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            HStack {
                Text(settings.text("records.recent"))
                    .font(SenseTheme.Typography.instrument(11))
                    .tracking(1.1)
                Spacer()
                Text(settings.text("records.count", records.count))
                    .font(SenseTheme.Typography.instrument(9))
                    .foregroundStyle(theme.colors.textSecondary)
            }

            if records.isEmpty {
                RecordsEmptyState(compact: true)
            } else {
                VStack(spacing: 1) {
                    ForEach(records.prefix(3)) { record in
                        MeasurementRecordRow(record: record)
                    }
                }
                .background(theme.colors.strokeSubtle)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

                Button {
                    isShowingAllRecords = true
                } label: {
                    Label(settings.text("records.viewAll"), systemImage: "clock.arrow.circlepath")
                        .font(SenseTheme.Typography.instrument(10))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.colors.textPrimary)
                .background(theme.colors.surfacePrimary)
                .overlay {
                    RoundedRectangle(cornerRadius: theme.radius.medium)
                        .stroke(theme.colors.strokeSubtle, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                .accessibilityLabel(settings.text("records.viewAll"))
                .accessibilityIdentifier("records.open")
            }
        }
        .foregroundStyle(theme.colors.textPrimary)
        .fullScreenCover(isPresented: $isShowingAllRecords) {
            RecentRecordsScreen()
                .environmentObject(settings)
        }
    }
}

struct RecentRecordsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.senseTheme) private var theme
    @Query(sort: \MeasurementRecord.capturedAt, order: .reverse) private var records: [MeasurementRecord]

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(settings.text("records.title"))
                        .font(SenseTheme.Typography.instrument(15))
                        .tracking(1.8)
                        .accessibilityIdentifier("records.title")
                    Spacer()
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(theme.colors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                    }
                    .accessibilityLabel(settings.text("records.close"))
                    .accessibilityIdentifier("records.close")
                }
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, SenseTheme.Spacing.small)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(theme.colors.strokeSubtle).frame(height: 1)
                }

                if records.isEmpty {
                    RecordsEmptyState(compact: false)
                        .padding(20)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(records) { record in
                                MeasurementRecordRow(record: record)
                            }
                        }
                        .background(theme.colors.strokeSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                        .padding(20)
                    }
                    .accessibilityIdentifier("records.list")
                }
            }
        }
    }
}

private struct MeasurementRecordRow: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let record: MeasurementRecord

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.colors.textOnSignal)
                .frame(width: 42, height: 42)
                .background(theme.colors.signalPrimary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))

            VStack(alignment: .leading, spacing: 3) {
                Text(settings.text(kindKey))
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(record.capturedAt.formatted(
                    .dateTime
                        .month(.abbreviated)
                        .day()
                        .hour()
                        .minute()
                        .locale(settings.language.locale)
                ))
                .font(.caption)
                .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer(minLength: 8)

            Text(formattedValue)
                .font(SenseTheme.Typography.instrument(13, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(theme.colors.textPrimary)
        .padding(.horizontal, SenseTheme.Spacing.medium)
        .frame(minHeight: 68)
        .background(theme.colors.surfacePrimary)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("records.row")
    }

    private var formattedValue: String {
        switch record.kind {
        case .barometer:
            let value = settings.pressureUnit.value(fromKPa: record.value)
            let format = settings.pressureUnit == .hectopascals ? "%.1f %@" : "%.2f %@"
            return String(format: format, value, settings.pressureUnit.symbol)
        case .level:
            return String(format: "%.1f %@", record.value, record.unit)
        case .magneticField, .vibration:
            return String(format: "%.0f %@", record.value, record.unit)
        }
    }

    private var kindKey: String {
        switch record.kind {
        case .magneticField: "records.kind.magnetic"
        case .vibration: "records.kind.vibration"
        case .level: "records.kind.level"
        case .barometer: "records.kind.barometer"
        }
    }

    private var icon: String {
        switch record.kind {
        case .magneticField: "scope"
        case .vibration: "waveform"
        case .level: "level"
        case .barometer: "gauge.with.needle"
        }
    }
}

private struct RecordsEmptyState: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme
    let compact: Bool

    var body: some View {
        VStack(spacing: SenseTheme.Spacing.small) {
            Image(systemName: "archivebox")
                .font(.system(size: compact ? 22 : 30, weight: .semibold))
                .foregroundStyle(theme.colors.signalPrimary)
            Text(settings.text("records.empty.title"))
                .font(.body.weight(.semibold))
            Text(settings.text("records.empty.detail"))
                .font(.footnote)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(theme.colors.textPrimary)
        .frame(maxWidth: .infinity, minHeight: compact ? 112 : 180)
        .padding(SenseTheme.Spacing.large)
        .background(theme.colors.surfacePrimary)
        .overlay {
            RoundedRectangle(cornerRadius: theme.radius.medium)
                .stroke(theme.colors.strokeSubtle, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
        .accessibilityLabel(settings.text("records.empty.title"))
        .accessibilityIdentifier("records.empty")
    }
}
