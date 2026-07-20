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

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let language = "appLanguage"
        static let theme = "appTheme"
        static let soundEnabled = "appSoundEnabled"
        static let hapticsEnabled = "appHapticsEnabled"
        static let alertThreshold = "appAlertThreshold"
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
        hasSeenMagneticGuide = defaults.bool(forKey: Keys.hasSeenMagneticGuide)
    }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        let localizedBundle = path.flatMap(Bundle.init(path:)) ?? .main
        let format = localizedBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: language.locale, arguments: arguments)
    }
}
