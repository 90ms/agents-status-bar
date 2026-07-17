import AgentsStatusCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        Form {
            Section("Providers") {
                ForEach(self.store.descriptors) { descriptor in
                    Toggle(isOn: Binding(
                        get: { self.store.isEnabled(descriptor.id) },
                        set: { self.store.setEnabled($0, for: descriptor.id) }))
                    {
                        Label(descriptor.displayName, systemImage: descriptor.systemImage)
                    }
                }
            }

            Section("Notifications") {
                Toggle(isOn: Binding(
                    get: { self.store.notificationsEnabled },
                    set: { self.store.setNotificationsEnabled($0) }))
                {
                    Text("Warn when usage reaches 30% or 10% left")
                }
                if let message = self.store.notificationSettingsMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Menu Bar") {
                Toggle(isOn: Binding(
                    get: { self.store.showsRemainingInMenuBar },
                    set: { self.store.setShowsRemainingInMenuBar($0) }))
                {
                    Text("Show lowest remaining usage")
                }
                Toggle(isOn: Binding(
                    get: { self.store.launchAtLoginEnabled },
                    set: { self.store.setLaunchAtLoginEnabled($0) }))
                {
                    Text("Launch at login")
                }
                if let message = self.store.launchAtLoginMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy") {
                Text("Usage is read from known local CLI session files. Codex and Claude quotas reuse their existing CLI sign-ins with account usage endpoints. Prompts, responses, cookies, and authentication tokens are not stored by this app.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 300)
        .padding()
    }
}
