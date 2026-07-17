import AgentsStatusCore
import Foundation
@preconcurrency import UserNotifications

@MainActor
final class UsageNotificationController: NSObject, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults
    private var deliveredIdentifiers: [String]

    private static let enabledKey = "usageNotificationsEnabled"
    private static let deliveredIdentifiersKey = "usageNotificationDeliveredIdentifiers"

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard)
    {
        self.center = center
        self.defaults = defaults
        self.deliveredIdentifiers = defaults.stringArray(forKey: Self.deliveredIdentifiersKey) ?? []
        super.init()
        self.center.delegate = self
    }

    var isEnabled: Bool {
        self.defaults.bool(forKey: Self.enabledKey)
    }

    func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled else {
            self.defaults.set(false, forKey: Self.enabledKey)
            return false
        }

        do {
            let granted = try await self.center.requestAuthorization(options: [.alert, .sound])
            self.defaults.set(granted, forKey: Self.enabledKey)
            return granted
        } catch {
            self.defaults.set(false, forKey: Self.enabledKey)
            return false
        }
    }

    func process(_ snapshots: [ProviderSnapshot]) {
        guard self.isEnabled else { return }
        let alreadyDelivered = Set(self.deliveredIdentifiers)
        let candidates = UsageAlertEvaluator.candidates(in: snapshots)
            .filter { !alreadyDelivered.contains($0.identifier) }

        for candidate in candidates {
            let content = UNMutableNotificationContent()
            content.title = AppLocalization.format("notification.usageLow.title", candidate.providerName)
            content.body = AppLocalization.format(
                "notification.usageLow.body",
                candidate.windowLabel,
                Int(candidate.remainingPercent.rounded()))
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: candidate.identifier,
                content: content,
                trigger: nil)
            self.center.add(request)
            self.deliveredIdentifiers.append(candidate.identifier)
        }

        if self.deliveredIdentifiers.count > 200 {
            self.deliveredIdentifiers = Array(self.deliveredIdentifiers.suffix(200))
        }
        self.defaults.set(self.deliveredIdentifiers, forKey: Self.deliveredIdentifiersKey)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.banner, .sound])
    }
}
