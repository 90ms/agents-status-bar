import Foundation

enum CostDisplayCurrency: String, CaseIterable, Identifiable {
    case usd
    case krw

    var id: String { self.rawValue }

    static var defaultValue: Self {
        Locale.current.currency?.identifier == "KRW" ? .krw : .usd
    }
}
