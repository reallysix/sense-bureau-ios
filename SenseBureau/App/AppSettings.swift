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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedLanguage = defaults.string(forKey: Keys.language)
        let storedTheme = defaults.string(forKey: Keys.theme)
        language = AppLanguage(rawValue: storedLanguage ?? "") ?? .simplifiedChinese
        theme = AppTheme(rawValue: storedTheme ?? "") ?? .techSignal
    }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        let localizedBundle = path.flatMap(Bundle.init(path:)) ?? .main
        let format = localizedBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: language.locale, arguments: arguments)
    }
}
