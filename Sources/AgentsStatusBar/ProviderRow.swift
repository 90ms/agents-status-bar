import AgentsStatusCore
import SwiftUI

struct ProviderRow: View {
    let snapshot: ProviderSnapshot
    let costCurrency: CostDisplayCurrency
    let exchangeRate: ExchangeRateQuote?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: self.snapshot.descriptor.systemImage)
                    .frame(width: 18)
                Text(self.snapshot.descriptor.displayName)
                    .font(.headline)
                Spacer()
                self.availabilityBadge
            }

            ForEach(self.snapshot.quotaWindows) { window in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(window.label)
                        Spacer()
                        Text(window.remainingPercent, format: .number.precision(.fractionLength(0)))
                            + Text(AppLocalization.string("usage.percentLeft"))
                        if let reset = window.resetsAt {
                            Text("·")
                            Text(reset, style: .relative)
                        }
                    }
                    .font(.caption)
                    ProgressView(value: window.remainingPercent, total: 100)
                        .tint(self.tint(forRemainingPercent: window.remainingPercent))
                }
            }

            if let tokenUsage = snapshot.tokenUsage {
                HStack {
                    Text(tokenUsage.label)
                    Spacer()
                    Text(tokenUsage.totalTokens.formatted(.number.notation(.compactName)))
                        .monospacedDigit()
                    Text(AppLocalization.string("usage.tokens"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let estimate = snapshot.costEstimate,
               let formattedCost = self.formattedCost(estimate.amountUSD)
            {
                HStack {
                    Text(AppLocalization.string("usage.apiCostEstimate"))
                    Spacer()
                    Text(formattedCost)
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .help(estimate.modelIDs.joined(separator: ", "))
            }

            if let detail = snapshot.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let source = snapshot.source {
                HStack(spacing: 4) {
                    Text(AppLocalization.sourceName(source))
                    Spacer()
                    Text(AppLocalization.string("usage.updated"))
                    Text(snapshot.updatedAt, style: .relative)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var availabilityBadge: some View {
        switch self.snapshot.availability {
        case .available:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .loading:
            ProgressView().controlSize(.small)
        case .stale:
            Image(systemName: "clock.badge.exclamationmark").foregroundStyle(.orange)
        case .unavailable:
            Image(systemName: "minus.circle").foregroundStyle(.secondary)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
        }
    }

    private func tint(forRemainingPercent percent: Double) -> Color {
        switch percent {
        case ..<10: .red
        case ..<30: .orange
        default: .accentColor
        }
    }

    private func formattedCost(_ amountUSD: Double) -> String? {
        switch self.costCurrency {
        case .usd:
            let digits = amountUSD < 0.01 ? 4 : 2
            return "$" + amountUSD.formatted(
                .number.precision(.fractionLength(digits)))
        case .krw:
            guard let exchangeRate else { return nil }
            let amountKRW = amountUSD * exchangeRate.rate
            let digits = amountKRW < 1 ? 2 : 0
            return "₩" + amountKRW.formatted(
                .number.precision(.fractionLength(digits)))
        }
    }
}
