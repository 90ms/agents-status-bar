import AppKit
import SwiftUI

@main
struct AgentsStatusBarApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 0) {
                HStack {
                    Text("Agents Status")
                        .font(.headline)
                    Spacer()
                    if self.store.isRefreshing {
                        ProgressView().controlSize(.small)
                    }
                    Button {
                        Task { await self.store.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh")
                }
                .padding(.bottom, 8)

                if self.store.snapshots.isEmpty {
                    ContentUnavailableView(
                        "No providers enabled",
                        systemImage: "chart.bar",
                        description: Text("Enable a provider in Settings."))
                    .frame(height: 130)
                } else {
                    ForEach(Array(self.store.snapshots.enumerated()), id: \.element.id) { index, snapshot in
                        if index > 0 { Divider() }
                        ProviderRow(snapshot: snapshot)
                    }
                }

                Divider()
                    .padding(.vertical, 8)
                HStack {
                    SettingsLink { Text("Settings…") }
                    Spacer()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                }
            }
            .padding(12)
            .frame(width: 340)
            .onAppear { self.store.start() }
        } label: {
            if let remaining = self.store.menuBarRemainingPercent {
                Image(systemName: remaining < 10 ? "exclamationmark.triangle.fill" : "chart.bar.fill")
                Text("Agents \(Int(remaining.rounded()))%")
            } else {
                Image(systemName: "chart.bar.fill")
                Text("Agents")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: self.store)
        }
    }
}
