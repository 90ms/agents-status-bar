import Foundation

public enum UsageSummary {
    public static func minimumRemainingPercent(in snapshots: [ProviderSnapshot]) -> Double? {
        snapshots
            .filter { $0.availability == .available }
            .flatMap(\.quotaWindows)
            .map(\.remainingPercent)
            .min()
    }
}
