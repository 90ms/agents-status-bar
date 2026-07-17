import AgentsStatusCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: UsageStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        TabView {
            self.generalTab
                .tabItem {
                    Label(
                        AppLocalization.string("settings.tab.general"),
                        systemImage: "gearshape")
                }

            self.notificationsTab
                .tabItem {
                    Label(
                        AppLocalization.string("settings.tab.notifications"),
                        systemImage: "bell")
                }

            self.usageTab
                .tabItem {
                    Label(
                        AppLocalization.string("settings.tab.usage"),
                        systemImage: "chart.xyaxis.line")
                }

            self.privacyTab
                .tabItem {
                    Label(
                        AppLocalization.string("settings.tab.privacy"),
                        systemImage: "hand.raised")
                }
        }
        .frame(width: 520, height: 470)
        .padding()
    }

    private var generalTab: some View {
        Form {
            Section(AppLocalization.string("settings.language")) {
                Picker(
                    AppLocalization.string("settings.language"),
                    selection: Binding(
                        get: { self.store.appLanguage },
                        set: { self.store.setAppLanguage($0) }))
                {
                    Text(AppLocalization.string("settings.language.system"))
                        .tag(AppLanguage.system)
                    Text(AppLocalization.string("settings.language.korean"))
                        .tag(AppLanguage.korean)
                    Text(AppLocalization.string("settings.language.english"))
                        .tag(AppLanguage.english)
                }
            }

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
        }
        .formStyle(.grouped)
    }

    private var notificationsTab: some View {
        Form {
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
                            Text(AppLocalization.format(
                                "settings.notifications.percentLeft",
                                value))
                                .tag(value)
                        }
                    }
                    Picker(
                        AppLocalization.string("settings.notifications.critical"),
                        selection: Binding(
                            get: { self.store.criticalThreshold },
                            set: { self.store.setCriticalThreshold($0) }))
                    {
                        ForEach([15, 10, 5], id: \.self) { value in
                            Text(AppLocalization.format(
                                "settings.notifications.percentLeft",
                                value))
                                .tag(value)
                        }
                    }
                }
            }

            if self.store.notificationsEnabled {
                Section(AppLocalization.string("settings.providers")) {
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
                }

                Section {
                    Button(AppLocalization.string("settings.notifications.test")) {
                        self.store.sendTestNotification()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var usageTab: some View {
        Form {
            Section(AppLocalization.string("settings.cost.title")) {
                Picker(
                    AppLocalization.string("settings.cost.currency"),
                    selection: Binding(
                        get: { self.store.costDisplayCurrency },
                        set: { self.store.setCostDisplayCurrency($0) }))
                {
                    Text(AppLocalization.string("settings.cost.usd"))
                        .tag(CostDisplayCurrency.usd)
                    Text(AppLocalization.string("settings.cost.krw"))
                        .tag(CostDisplayCurrency.krw)
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

                Divider()
                HStack {
                    Text(AppLocalization.format(
                        "settings.cost.catalog",
                        self.store.pricingCatalogMetadata.catalogVersion,
                        self.store.pricingCatalogMetadata.effectiveDate,
                        AppLocalization.string(
                            "settings.cost.catalogSource.\(self.store.pricingCatalogSource.rawValue)")))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(AppLocalization.string("settings.cost.catalogRefresh")) {
                        self.store.refreshPricingCatalog()
                    }
                }
                if let message = self.store.pricingUpdateMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section(AppLocalization.string("settings.budget.title")) {
                Toggle(isOn: Binding(
                    get: { self.store.monthlyBudgetEnabled },
                    set: { self.store.setMonthlyBudgetEnabled($0) }))
                {
                    Text(AppLocalization.string("settings.budget.enabled"))
                }
                if self.store.monthlyBudgetEnabled {
                    HStack {
                        TextField(
                            AppLocalization.string("settings.budget.amount"),
                            value: Binding(
                                get: { self.store.monthlyBudgetAmount },
                                set: { self.store.setMonthlyBudgetAmount($0) }),
                            format: .number.precision(.fractionLength(0...2)))
                            .frame(width: 140)
                        Picker(
                            AppLocalization.string("settings.cost.currency"),
                            selection: Binding(
                                get: { self.store.monthlyBudgetCurrency },
                                set: { self.store.setMonthlyBudgetCurrency($0) }))
                        {
                            Text("USD").tag(CostDisplayCurrency.usd)
                            Text("KRW").tag(CostDisplayCurrency.krw)
                        }
                        .pickerStyle(.segmented)
                    }

                    if let budgetUSD = self.store.monthlyBudgetUSD,
                       let spent = self.store.monthlyBudgetCurrency.formatted(
                           amountUSD: self.store.monthlyEstimatedSpendUSD,
                           exchangeRate: self.store.exchangeRateQuote),
                       let budget = self.store.monthlyBudgetCurrency.formatted(
                           amountUSD: budgetUSD,
                           exchangeRate: self.store.exchangeRateQuote)
                    {
                        ProgressView(
                            value: min(self.store.monthlyEstimatedSpendUSD, budgetUSD),
                            total: budgetUSD)
                        Text(AppLocalization.format("settings.budget.spent", spent, budget))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(AppLocalization.string("settings.budget.noRate"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(AppLocalization.string("settings.budget.description"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(AppLocalization.string("history.title")) {
                Button(AppLocalization.string("history.open")) {
                    self.openWindow(id: "usage-history")
                }
                Text(AppLocalization.string("history.privacy"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var privacyTab: some View {
        Form {
            Section(AppLocalization.string("settings.privacy")) {
                Text(AppLocalization.string("settings.privacy.description"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
