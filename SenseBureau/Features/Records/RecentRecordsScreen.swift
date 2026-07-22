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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.senseTheme) private var theme
    @Query(sort: \MeasurementRecord.capturedAt, order: .reverse) private var records: [MeasurementRecord]
    @State private var isConfirmingClear = false
    @State private var isShowingError = false

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
                    Button { isConfirmingClear = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(theme.colors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
                    }
                    .disabled(records.isEmpty)
                    .accessibilityLabel(settings.text("records.clear"))
                    .accessibilityIdentifier("records.clear")

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
                    List {
                        ForEach(records) { record in
                            MeasurementRecordRow(record: record)
                                .listRowInsets(EdgeInsets(
                                    top: 0,
                                    leading: 20,
                                    bottom: SenseTheme.Spacing.small,
                                    trailing: 20
                                ))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label(settings.text("records.delete"), systemImage: "trash")
                                    }
                                    .tint(theme.colors.critical)
                                    .accessibilityIdentifier("records.delete")
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, 20, for: .scrollContent)
                    .accessibilityIdentifier("records.list")
                }
            }
        }
        .alert(settings.text("settings.data.confirm.title"), isPresented: $isConfirmingClear) {
            Button(settings.text("settings.data.confirm.cancel"), role: .cancel) {}
            Button(settings.text("settings.data.confirm.delete"), role: .destructive) {
                clearAll()
            }
        } message: {
            Text(settings.text("settings.data.confirm.message"))
        }
        .alert(settings.text("records.error"), isPresented: $isShowingError) {
            Button(settings.text("records.error.ok"), role: .cancel) {}
        }
    }

    private func delete(_ record: MeasurementRecord) {
        do {
            try MeasurementRecordStore(context: modelContext).delete(record)
        } catch {
            isShowingError = true
        }
    }

    private func clearAll() {
        do {
            try MeasurementRecordStore(context: modelContext).deleteAll()
        } catch {
            isShowingError = true
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
