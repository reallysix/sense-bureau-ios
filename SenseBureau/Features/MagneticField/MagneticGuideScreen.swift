import SwiftUI

struct MagneticGuideScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.senseTheme) private var theme

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            theme.colors.canvasPrimary.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: SenseTheme.Spacing.large) {
                    header
                    hero
                    capabilityPanel
                    preparationPanel
                }
                .padding(.horizontal, 20)
                .padding(.top, SenseTheme.Spacing.small)
                .padding(.bottom, SenseTheme.Spacing.xLarge)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: onComplete) {
                Label(settings.text("guide.begin"), systemImage: "scope")
                    .font(SenseTheme.Typography.instrument(11))
                    .tracking(0.8)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.colors.textOnSignal)
            .background(theme.colors.signalPrimary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
            .padding(.horizontal, 20)
            .padding(.vertical, SenseTheme.Spacing.small)
            .background(theme.colors.canvasPrimary)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(theme.colors.strokeSubtle)
                    .frame(height: 1)
            }
            .accessibilityIdentifier("guide.begin")
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        HStack(spacing: SenseTheme.Spacing.small) {
            Text(settings.text("guide.status"))
                .font(SenseTheme.Typography.instrument(10))
                .tracking(0.9)
                .foregroundStyle(theme.colors.textOnSignal)
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(theme.colors.signalPrimary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))

            Spacer(minLength: 8)

            Text(settings.text("guide.title"))
                .font(SenseTheme.Typography.instrument(14))
                .tracking(1.8)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .accessibilityIdentifier("guide.title")

            Spacer(minLength: 8)

            Button(action: onComplete) {
                Text(settings.text("guide.skip"))
                    .font(SenseTheme.Typography.instrument(9))
                    .foregroundStyle(theme.colors.textSecondary)
                    .frame(minWidth: 52, minHeight: 28)
                    .background(theme.colors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("guide.skip")
        }
        .frame(height: 36)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.large) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 40, weight: .semibold))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: SenseTheme.Spacing.small) {
                Text(settings.text("guide.hero.title"))
                    .font(.system(size: 24, weight: .bold))
                Text(settings.text("guide.hero.detail"))
                    .font(.system(size: 15, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.76)
            }
        }
        .foregroundStyle(theme.colors.textOnSignal)
        .padding(SenseTheme.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 208, alignment: .bottomLeading)
        .background(theme.colors.signalPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var capabilityPanel: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            sectionTitle("guide.capability.section")
            GuideFactRow(
                systemImage: "checkmark.circle",
                title: settings.text("guide.can.title"),
                detail: settings.text("guide.can.detail")
            )
            Divider().overlay(theme.colors.strokeSubtle)
            GuideFactRow(
                systemImage: "xmark.circle",
                title: settings.text("guide.cannot.title"),
                detail: settings.text("guide.cannot.detail")
            )
        }
        .padding(SenseTheme.Spacing.large)
        .background(theme.colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private var preparationPanel: some View {
        VStack(alignment: .leading, spacing: SenseTheme.Spacing.medium) {
            sectionTitle("guide.prepare.section")
            GuideStep(number: "01", text: settings.text("guide.prepare.remove"))
            GuideStep(number: "02", text: settings.text("guide.prepare.clear"))
            GuideStep(number: "03", text: settings.text("guide.prepare.still"))
        }
        .padding(SenseTheme.Spacing.large)
        .background(theme.colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium))
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(settings.text(key))
            .font(SenseTheme.Typography.instrument(11))
            .tracking(1.2)
            .foregroundStyle(theme.colors.textSecondary)
    }
}

private struct GuideFactRow: View {
    @Environment(\.senseTheme) private var theme
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: SenseTheme.Spacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.colors.signalPrimary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct GuideStep: View {
    @Environment(\.senseTheme) private var theme
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: SenseTheme.Spacing.medium) {
            Text(number)
                .font(SenseTheme.Typography.instrument(10))
                .foregroundStyle(theme.colors.textOnSignal)
                .frame(width: 36, height: 36)
                .background(theme.colors.signalPrimary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))

            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
