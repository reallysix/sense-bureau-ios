import CoreText
import SwiftUI
import UIKit

enum TechSignalTheme {
    enum Colors {
        static let canvasPrimary = Color(hex: 0x1A1919)
        static let surfacePrimary = Color(hex: 0x202224)
        static let surfaceRaised = Color(hex: 0x2B2C2E)
        static let surfaceData = Color(hex: 0x595E63)
        static let signalPrimary = Color(hex: 0xF63101)
        static let signalPressed = Color(hex: 0xD92B00)
        static let textPrimary = Color(hex: 0xF5F5F2)
        static let textSecondary = Color(hex: 0xA09FA3)
        static let textOnSignal = Color(hex: 0x151515)
        static let textOnData = Color(hex: 0x111315)
        static let strokeSubtle = Color(hex: 0x3D3C42)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 16
        static let navigation: CGFloat = 22
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

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
