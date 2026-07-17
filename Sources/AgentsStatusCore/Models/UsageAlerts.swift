import Foundation

public struct UsageAlertCandidate: Hashable, Sendable {
    public let providerID: ProviderID
    public let providerName: String
    public let windowID: String
    public let windowLabel: String
    public let remainingPercent: Double
    public let threshold: Int
    public let resetsAt: Date?

    public var identifier: String {
        let resetKey = self.resetsAt.map { String(Int($0.timeIntervalSince1970)) } ?? "no-reset"
        return [
            self.providerID.rawValue,
            self.windowID,
            String(self.threshold),
            resetKey,
        ].joined(separator: ".")
    }
}

public enum UsageAlertEvaluator {
    public static func candidates(in snapshots: [ProviderSnapshot]) -> [UsageAlertCandidate] {
        snapshots.flatMap { snapshot -> [UsageAlertCandidate] in
            guard snapshot.availability == .available else { return [] }
            return snapshot.quotaWindows.compactMap { window in
                guard window.kind != .context else { return nil }
                let threshold: Int
                switch window.remainingPercent {
                case ...10: threshold = 10
                case ...30: threshold = 30
                default: return nil
                }
                return UsageAlertCandidate(
                    providerID: snapshot.id,
                    providerName: snapshot.descriptor.displayName,
                    windowID: window.id,
                    windowLabel: window.label,
                    remainingPercent: window.remainingPercent,
                    threshold: threshold,
                    resetsAt: window.resetsAt)
            }
        }
    }
}
