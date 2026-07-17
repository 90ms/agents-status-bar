import AgentsStatusCore
import Charts
import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: UsageStore
    @State private var selectedProviderID: ProviderID?
    @State private var rangeDays = 7

    private var availableProviders: [(id: ProviderID, name: String)] {
        var seen = Set<ProviderID>()
        return self.store.historyRecords.compactMap { record in
            guard seen.insert(record.providerID).inserted else { return nil }
            return (record.providerID, record.providerName)
        }
    }

    private var visibleRecords: [UsageHistoryRecord] {
        let providerID = self.selectedProviderID ?? self.availableProviders.first?.id
        let cutoff = Date.now.addingTimeInterval(TimeInterval(-self.rangeDays * 24 * 60 * 60))
        return self.store.historyRecords.filter {
            $0.providerID == providerID && $0.timestamp >= cutoff
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Picker(
                    AppLocalization.string("history.provider"),
                    selection: Binding(
                        get: { self.selectedProviderID ?? self.availableProviders.first?.id },
                        set: { self.selectedProviderID = $0 }))
                {
                    ForEach(self.availableProviders, id: \.id) { provider in
                        Text(provider.name).tag(Optional(provider.id))
                    }
                }
                .frame(width: 220)

                Picker(
                    AppLocalization.string("history.range"),
                    selection: self.$rangeDays)
                {
                    Text(AppLocalization.string("history.range.day")).tag(1)
                    Text(AppLocalization.string("history.range.week")).tag(7)
                    Text(AppLocalization.string("history.range.month")).tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
                Spacer()
            }

            if self.visibleRecords.flatMap(\.windows).isEmpty {
                ContentUnavailableView(
                    AppLocalization.string("history.empty.title"),
                    systemImage: "chart.xyaxis.line",
                    description: Text(AppLocalization.string("history.empty.description")))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(self.visibleRecords) { record in
                        ForEach(record.windows) { window in
                            LineMark(
                                x: .value(AppLocalization.string("history.time"), record.timestamp),
                                y: .value(AppLocalization.string("history.remaining"), window.remainingPercent))
                                .foregroundStyle(by: .value(
                                    AppLocalization.string("history.limit"),
                                    window.label))
                                .interpolationMethod(.monotone)
                            PointMark(
                                x: .value(AppLocalization.string("history.time"), record.timestamp),
                                y: .value(AppLocalization.string("history.remaining"), window.remainingPercent))
                                .foregroundStyle(by: .value(
                                    AppLocalization.string("history.limit"),
                                    window.label))
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxisLabel(AppLocalization.string("history.percentLeft"))
            }

            HStack {
                Text(AppLocalization.format("history.retention", 30))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(AppLocalization.string("history.clear"), role: .destructive) {
                    self.store.clearHistory()
                }
            }
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 420)
    }
}
