import AgentsStatusCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: UsageStore

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
                    Text(AppLocalization.string("settings.notifications.thresholds"))
                }
                if let message = self.store.notificationSettingsMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
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

            Section(AppLocalization.string("settings.privacy")) {
                Text(AppLocalization.string("settings.privacy.description"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 300)
        .padding()
    }
}
