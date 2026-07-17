import AppKit
import SwiftUI

@main
struct AgentsStatusBarApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 0) {
                HStack {
                    Text(AppLocalization.string("app.title"))
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
                    .help(AppLocalization.string("action.refresh"))
                }
                .padding(.bottom, 8)

                if self.store.snapshots.isEmpty {
                    ContentUnavailableView(
                        AppLocalization.string("empty.title"),
                        systemImage: "chart.bar",
                        description: Text(AppLocalization.string("empty.description")))
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
                    SettingsLink { Text(AppLocalization.string("action.settings")) }
                    Spacer()
                    Button(AppLocalization.string("action.quit")) { NSApplication.shared.terminate(nil) }
                }
            }
            .padding(12)
            .frame(width: 340)
            .onAppear { self.store.start() }
        } label: {
            if let remaining = self.store.menuBarRemainingPercent {
                Image(systemName: remaining < 10 ? "exclamationmark.triangle.fill" : "chart.bar.fill")
                Text(AppLocalization.format("app.menuRemaining", Int(remaining.rounded())))
            } else {
                Image(systemName: "chart.bar.fill")
                Text(AppLocalization.string("app.menuName"))
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: self.store)
        }

        Window(AppLocalization.string("history.title"), id: "usage-history") {
            HistoryView(store: self.store)
        }
        .defaultSize(width: 720, height: 460)
    }
}
