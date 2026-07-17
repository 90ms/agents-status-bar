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
