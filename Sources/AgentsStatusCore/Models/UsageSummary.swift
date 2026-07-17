import Foundation

public enum UsageSummary {
    public static func minimumRemainingPercent(in snapshots: [ProviderSnapshot]) -> Double? {
        snapshots
            .filter { $0.availability == .available }
            .flatMap(\.quotaWindows)
            .map(\.remainingPercent)
            .min()
    }

    public static func minimumRemainingPercent(
        in snapshots: [ProviderSnapshot],
        for providerID: ProviderID) -> Double?
    {
        self.minimumRemainingPercent(in: snapshots.filter { $0.id == providerID })
    }
}
