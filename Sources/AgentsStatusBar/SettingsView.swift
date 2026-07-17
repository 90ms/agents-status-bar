import AgentsStatusCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: UsageStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Form {
            Section(AppLocalization.string("settings.providers")) {
                ForEach(self.store.descriptors) { descriptor in
                    Toggle(isOn: Binding(
                        get: { self.store.isEnabled(descriptor.id) },
                        set: { self.store.setEnabled($0, for: descriptor.id) }))
                    {
                        Label(descriptor.displayName, systemImage: descriptor.systemImage)
                    }
                }
            }

            Section(AppLocalization.string("settings.notifications")) {
                Toggle(isOn: Binding(
                    get: { self.store.notificationsEnabled },
                    set: { self.store.setNotificationsEnabled($0) }))
                {
                    Text(AppLocalization.string("settings.notifications.enabled"))
                }
                if let message = self.store.notificationSettingsMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if self.store.notificationsEnabled {
                    Picker(
                        AppLocalization.string("settings.notifications.warning"),
                        selection: Binding(
                            get: { self.store.warningThreshold },
                            set: { self.store.setWarningThreshold($0) }))
                    {
                        ForEach([50, 40, 30, 20], id: \.self) { value in
                            Text(AppLocalization.format("settings.notifications.percentLeft", value)).tag(value)
                        }
                    }
                    Picker(
                        AppLocalization.string("settings.notifications.critical"),
                        selection: Binding(
                            get: { self.store.criticalThreshold },
                            set: { self.store.setCriticalThreshold($0) }))
                    {
                        ForEach([15, 10, 5], id: \.self) { value in
                            Text(AppLocalization.format("settings.notifications.percentLeft", value)).tag(value)
                        }
                    }
                    ForEach(self.store.descriptors) { descriptor in
                        Toggle(isOn: Binding(
                            get: { self.store.isNotificationEnabled(for: descriptor.id) },
                            set: { self.store.setNotificationEnabled($0, for: descriptor.id) }))
                        {
                            Text(AppLocalization.format(
                                "settings.notifications.provider",
                                descriptor.displayName))
                        }
                    }
                    Button(AppLocalization.string("settings.notifications.test")) {
                        self.store.sendTestNotification()
                    }
                }
            }

            Section(AppLocalization.string("settings.menuBar")) {
                Toggle(isOn: Binding(
                    get: { self.store.showsRemainingInMenuBar },
                    set: { self.store.setShowsRemainingInMenuBar($0) }))
                {
                    Text(AppLocalization.string("settings.menuBar.lowest"))
                }
                Toggle(isOn: Binding(
                    get: { self.store.launchAtLoginEnabled },
                    set: { self.store.setLaunchAtLoginEnabled($0) }))
                {
                    Text(AppLocalization.string("settings.launchAtLogin"))
                }
                if let message = self.store.launchAtLoginMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(AppLocalization.string("settings.cost.title")) {
                Picker(
                    AppLocalization.string("settings.cost.currency"),
                    selection: Binding(
                        get: { self.store.costDisplayCurrency },
                        set: { self.store.setCostDisplayCurrency($0) }))
                {
                    Text(AppLocalization.string("settings.cost.usd")).tag(CostDisplayCurrency.usd)
                    Text(AppLocalization.string("settings.cost.krw")).tag(CostDisplayCurrency.krw)
                }
                .pickerStyle(.segmented)

                if let quote = self.store.exchangeRateQuote {
                    Text(AppLocalization.format(
                        "settings.cost.rate",
                        quote.rate.formatted(.number.precision(.fractionLength(2))),
                        quote.rateDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(AppLocalization.string("settings.cost.rateUnavailable"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(AppLocalization.string("settings.cost.disclaimer"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(AppLocalization.string("history.title")) {
                Button(AppLocalization.string("history.open")) {
                    self.openWindow(id: "usage-history")
                }
                Text(AppLocalization.string("history.privacy"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(AppLocalization.string("settings.privacy")) {
                Text(AppLocalization.string("settings.privacy.description"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 560)
        .padding()
    }
}
