import Foundation

public enum UsageCostSummary {
    public static func accumulatedUSD(
        in records: [UsageHistoryRecord],
        since startDate: Date,
        providerID: ProviderID? = nil) -> Double
    {
        let filtered = records.filter { record in
            record.timestamp >= startDate
                && providerID.map { $0 == record.providerID } != false
        }
        let grouped = Dictionary(grouping: filtered, by: \.providerID)
        return grouped.values.reduce(0) { total, providerRecords in
            total + self.accumulatedUSD(inSingleProvider: providerRecords)
        }
    }

    private static func accumulatedUSD(
        inSingleProvider records: [UsageHistoryRecord]) -> Double
    {
        var previous: Double?
        var total = 0.0
        for record in records.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let cost = record.costUSD, cost >= 0 else { continue }
            if let previous {
                total += cost >= previous ? cost - previous : cost
            } else {
                total += cost
            }
            previous = cost
        }
        return total
    }
}
