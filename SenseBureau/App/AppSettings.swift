import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        }
    }
}

enum PressureUnit: String, CaseIterable, Identifiable {
    case hectopascals
    case kilopascals

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .hectopascals: "hPa"
        case .kilopascals: "kPa"
        }
    }

    func value(fromKPa value: Double) -> Double {
        switch self {
        case .hectopascals: value * 10
        case .kilopascals: value
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let language = "appLanguage"
        static let theme = "appTheme"
        static let soundEnabled = "appSoundEnabled"
        static let hapticsEnabled = "appHapticsEnabled"
        static let alertThreshold = "appAlertThreshold"
        static let pressureUnit = "appPressureUnit"
        static let hasSeenMagneticGuide = "hasSeenMagneticGuide"
    }

    private let defaults: UserDefaults

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
        }
    }

    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
        }
    }

    @Published var alertThreshold: Double {
        didSet {
            defaults.set(alertThreshold, forKey: Keys.alertThreshold)
        }
    }

    @Published var pressureUnit: PressureUnit {
        didSet {
            defaults.set(pressureUnit.rawValue, forKey: Keys.pressureUnit)
        }
    }

    @Published var hasSeenMagneticGuide: Bool {
        didSet {
            defaults.set(hasSeenMagneticGuide, forKey: Keys.hasSeenMagneticGuide)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedLanguage = defaults.string(forKey: Keys.language)
        let storedTheme = defaults.string(forKey: Keys.theme)
        language = AppLanguage(rawValue: storedLanguage ?? "") ?? .simplifiedChinese
        theme = AppTheme(rawValue: storedTheme ?? "") ?? .techSignal
        soundEnabled = defaults.object(forKey: Keys.soundEnabled) == nil
            ? true
            : defaults.bool(forKey: Keys.soundEnabled)
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) == nil
            ? true
            : defaults.bool(forKey: Keys.hapticsEnabled)
        alertThreshold = defaults.object(forKey: Keys.alertThreshold) == nil
            ? 30
            : defaults.double(forKey: Keys.alertThreshold)
        pressureUnit = PressureUnit(
            rawValue: defaults.string(forKey: Keys.pressureUnit) ?? ""
        ) ?? .hectopascals
        hasSeenMagneticGuide = defaults.bool(forKey: Keys.hasSeenMagneticGuide)
    }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        let localizedBundle = path.flatMap(Bundle.init(path:)) ?? .main
        let format = localizedBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: language.locale, arguments: arguments)
    }
}
