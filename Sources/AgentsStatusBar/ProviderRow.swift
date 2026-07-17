import AgentsStatusCore
import SwiftUI

struct ProviderRow: View {
    let snapshot: ProviderSnapshot

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
                            + Text("% left")
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
                    Text("tokens")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let detail = snapshot.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
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
}
