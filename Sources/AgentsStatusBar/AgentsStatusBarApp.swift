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
                        ProviderRow(
                            snapshot: snapshot,
                            costCurrency: self.store.costDisplayCurrency,
                            exchangeRate: self.store.exchangeRateQuote,
                            compact: self.store.compactModeEnabled)
                    }
                }

                if let result = self.store.appUpdateResult, result.isUpdateAvailable {
                    Divider()
                        .padding(.vertical, 6)
                    Link(destination: result.latestRelease.pageURL) {
                        Label(
                            AppLocalization.format(
                                "updates.menuAvailable",
                                result.latestRelease.version.description),
                            systemImage: "arrow.down.circle")
                    }
                    .font(.caption)
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
            .frame(width: self.store.compactModeEnabled ? 300 : 340)
            .onAppear { self.store.start() }
        } label: {
            self.menuBarLabel
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: self.store)
        }

        Window(AppLocalization.string("history.title"), id: "usage-history") {
            HistoryView(store: self.store)
        }
        .defaultSize(width: 720, height: 460)

        Window(AppLocalization.string("diagnostics.title"), id: "provider-diagnostics") {
            DiagnosticsView(store: self.store)
        }
        .defaultSize(width: 680, height: 480)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        switch self.store.menuBarDisplayMode {
        case .iconOnly:
            Image(systemName: "chart.bar.fill")
        case .lowestRemaining:
            let remaining = self.store.menuBarRemainingPercent
            Image(systemName: self.menuBarIcon(for: remaining))
            if let remaining {
                Text(AppLocalization.format("app.menuRemaining", Int(remaining.rounded())))
            } else {
                Text(AppLocalization.string("app.menuName"))
            }
        case .monthlyCost:
            Image(systemName: "dollarsign.circle.fill")
            if let cost = self.store.menuBarMonthlyCost {
                Text(AppLocalization.format("app.menuMonthlyCost", cost))
            } else {
                Text(AppLocalization.string("app.menuName"))
            }
        case .selectedProvider:
            let remaining = self.store.selectedMenuBarProviderRemainingPercent
            Image(systemName: self.menuBarIcon(for: remaining))
            if let provider = self.store.selectedMenuBarProvider, let remaining {
                Text(AppLocalization.format(
                    "app.menuProviderRemaining",
                    provider.shortName,
                    Int(remaining.rounded())))
            } else if let provider = self.store.selectedMenuBarProvider {
                Text(AppLocalization.format("app.menuProviderUnavailable", provider.shortName))
            } else {
                Text(AppLocalization.string("app.menuName"))
            }
        }
    }

    private func menuBarIcon(for remaining: Double?) -> String {
        guard let remaining else { return "chart.bar.fill" }
        return remaining < 10 ? "exclamationmark.triangle.fill" : "chart.bar.fill"
    }
}
