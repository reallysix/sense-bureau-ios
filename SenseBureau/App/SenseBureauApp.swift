import SwiftUI

@main
struct SenseBureauApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MagneticFieldScreen()
                .environmentObject(settings)
                .environment(\.locale, settings.language.locale)
                .preferredColorScheme(.dark)
        }
    }
}
