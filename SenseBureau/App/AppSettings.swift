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
    }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
        }
    }

    init() {
        let storedLanguage = UserDefaults.standard.string(forKey: Keys.language)
        language = AppLanguage(rawValue: storedLanguage ?? "") ?? .simplifiedChinese
    }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        let localizedBundle = path.flatMap(Bundle.init(path:)) ?? .main
        let format = localizedBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: language.locale, arguments: arguments)
    }
}
