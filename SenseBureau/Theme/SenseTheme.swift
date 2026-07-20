import CoreText
import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case techSignal
    case cartoonExplorer

    var id: String { rawValue }

    var nameKey: String {
        switch self {
        case .techSignal: "settings.theme.tech"
        case .cartoonExplorer: "settings.theme.cartoon"
        }
    }

    var definition: ThemeDefinition {
        switch self {
        case .techSignal: .techSignal
        case .cartoonExplorer: .cartoonExplorer
        }
    }
}

struct ThemeDefinition {
    let id: AppTheme
    let colors: ThemeColors
    let radius: ThemeRadius
    let colorScheme: ColorScheme

    static let techSignal = ThemeDefinition(
        id: .techSignal,
        colors: ThemeColors(
            canvasPrimary: Color(hex: 0x1A1919),
            surfacePrimary: Color(hex: 0x202224),
            surfaceRaised: Color(hex: 0x2B2C2E),
            surfaceData: Color(hex: 0x595E63),
            signalPrimary: Color(hex: 0xF63101),
            signalPressed: Color(hex: 0xD92B00),
            textPrimary: Color(hex: 0xF5F5F2),
            textSecondary: Color(hex: 0xA09FA3),
            textOnSignal: Color(hex: 0x151515),
            textOnData: Color(hex: 0x111315),
            strokeSubtle: Color(hex: 0x3D3C42)
        ),
        radius: ThemeRadius(small: 6, medium: 10, large: 16, navigation: 22),
        colorScheme: .dark
    )

    static let cartoonExplorer = ThemeDefinition(
        id: .cartoonExplorer,
        colors: ThemeColors(
            canvasPrimary: Color(hex: 0xDADADF),
            surfacePrimary: Color(hex: 0xF7F5F7),
            surfaceRaised: Color(hex: 0xE9E5EA),
            surfaceData: Color(hex: 0xC7C7CD),
            signalPrimary: Color(hex: 0xF94921),
            signalPressed: Color(hex: 0xD92B00),
            textPrimary: Color(hex: 0x242326),
            textSecondary: Color(hex: 0x66636A),
            textOnSignal: Color(hex: 0x171517),
            textOnData: Color(hex: 0x242326),
            strokeSubtle: Color(hex: 0xB6B3BA)
        ),
        radius: ThemeRadius(small: 8, medium: 14, large: 18, navigation: 22),
        colorScheme: .light
    )
}

struct ThemeColors {
    let canvasPrimary: Color
    let surfacePrimary: Color
    let surfaceRaised: Color
    let surfaceData: Color
    let signalPrimary: Color
    let signalPressed: Color
    let textPrimary: Color
    let textSecondary: Color
    let textOnSignal: Color
    let textOnData: Color
    let strokeSubtle: Color
}

struct ThemeRadius {
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    let navigation: CGFloat
}

enum SenseTheme {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }

    enum Typography {
        static func displayDot(_ size: CGFloat) -> Font {
            let variationAttribute = UIFontDescriptor.AttributeName(
                rawValue: kCTFontVariationAttribute as String
            )
            let descriptor = UIFontDescriptor(name: "Doto", size: size).addingAttributes([
                variationAttribute: [
                    NSNumber(value: UInt32(0x524F4E44)): NSNumber(value: 100),
                    NSNumber(value: UInt32(0x77676874)): NSNumber(value: 500),
                ],
            ])
            return Font(UIFont(descriptor: descriptor, size: size))
        }

        static func instrument(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }
}

private struct SenseThemeKey: EnvironmentKey {
    static let defaultValue = ThemeDefinition.techSignal
}

extension EnvironmentValues {
    var senseTheme: ThemeDefinition {
        get { self[SenseThemeKey.self] }
        set { self[SenseThemeKey.self] = newValue }
    }
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
