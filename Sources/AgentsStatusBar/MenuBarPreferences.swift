import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconOnly
    case lowestRemaining
    case monthlyCost
    case selectedProvider

    var id: String { self.rawValue }

    var localizedName: String {
        AppLocalization.string("settings.menuBar.mode.\(self.rawValue)")
    }
}
