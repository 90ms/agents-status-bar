import AgentsStatusCore
import Foundation

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var snapshots: [ProviderSnapshot]
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefresh: Date?
    @Published private(set) var enabledProviderIDs: Set<ProviderID>
    @Published private(set) var notificationsEnabled: Bool
    @Published private(set) var notificationSettingsMessage: String?
    @Published private(set) var warningThreshold: Int
    @Published private(set) var criticalThreshold: Int
    @Published private(set) var notificationProviderIDs: Set<ProviderID>
    @Published private(set) var showsRemainingInMenuBar: Bool
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published private(set) var launchAtLoginMessage: String?
    @Published private(set) var historyRecords: [UsageHistoryRecord]
    @Published private(set) var costDisplayCurrency: CostDisplayCurrency
    @Published private(set) var exchangeRateQuote: ExchangeRateQuote?
    @Published private(set) var appLanguage: AppLanguage

    private let providers: [any UsageProviding]
    private var refreshLoop: Task<Void, Never>?
    private let notificationController: UsageNotificationController
    private let launchAtLoginController: LaunchAtLoginController
    private let historyStore: UsageHistoryStore
    private let exchangeRateClient: DailyExchangeRateClient
    private static let enabledProvidersKey = "enabledProviderIDs"
    private static let showsRemainingInMenuBarKey = "showsRemainingInMenuBar"
    private static let warningThresholdKey = "usageNotificationWarningThreshold"
    private static let criticalThresholdKey = "usageNotificationCriticalThreshold"
    private static let notificationProviderIDsKey = "usageNotificationProviderIDs"
    private static let costDisplayCurrencyKey = "costDisplayCurrency"

    init(providers: [any UsageProviding] = ProviderRegistry.defaultProviders()) {
        self.providers = providers
        let notificationController = UsageNotificationController()
        let launchAtLoginController = LaunchAtLoginController()
        let historyStore = UsageHistoryStore()
        let exchangeRateClient = DailyExchangeRateClient()
        self.notificationController = notificationController
        self.launchAtLoginController = launchAtLoginController
        self.historyStore = historyStore
        self.exchangeRateClient = exchangeRateClient
        self.notificationsEnabled = notificationController.isEnabled
        self.notificationSettingsMessage = nil
        self.warningThreshold = UserDefaults.standard.object(forKey: Self.warningThresholdKey) as? Int ?? 30
        self.criticalThreshold = UserDefaults.standard.object(forKey: Self.criticalThresholdKey) as? Int ?? 10
        self.showsRemainingInMenuBar = UserDefaults.standard.object(
            forKey: Self.showsRemainingInMenuBarKey) as? Bool ?? true
        self.launchAtLoginEnabled = launchAtLoginController.isEnabled
        self.launchAtLoginMessage = launchAtLoginController.statusMessage
        self.historyRecords = []
        self.costDisplayCurrency = UserDefaults.standard.string(
            forKey: Self.costDisplayCurrencyKey)
            .flatMap(CostDisplayCurrency.init(rawValue:)) ?? .defaultValue
        self.exchangeRateQuote = nil
        self.appLanguage = .savedValue
        let knownIDs = Set(providers.map { $0.descriptor.id })
        let enabledIDs: Set<ProviderID>
        if let stored = UserDefaults.standard.stringArray(forKey: Self.enabledProvidersKey) {
            enabledIDs = Set(stored.map { ProviderID(rawValue: $0) }).intersection(knownIDs)
        } else {
            enabledIDs = knownIDs
        }
        self.enabledProviderIDs = enabledIDs
        if let stored = UserDefaults.standard.stringArray(forKey: Self.notificationProviderIDsKey) {
            self.notificationProviderIDs = Set(stored.map { ProviderID(rawValue: $0) }).intersection(knownIDs)
        } else {
            self.notificationProviderIDs = knownIDs
        }
        self.snapshots = providers
            .filter { enabledIDs.contains($0.descriptor.id) }
            .map { .loading($0.descriptor) }
        Task { [weak self] in
            guard let self else { return }
            self.historyRecords = (try? await self.historyStore.records()) ?? []
            await self.refreshExchangeRate()
        }
    }

    deinit {
        self.refreshLoop?.cancel()
    }

    func start() {
        guard self.refreshLoop == nil else { return }
        self.refreshLoop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    func refresh() async {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
        let activeProviders = self.providers.filter { self.enabledProviderIDs.contains($0.descriptor.id) }

        let results = await withTaskGroup(of: ProviderSnapshot.self, returning: [ProviderSnapshot].self) { group in
            for provider in activeProviders {
                group.addTask { await provider.fetchUsage() }
            }
            var collected: [ProviderSnapshot] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let order = Dictionary(uniqueKeysWithValues: activeProviders.enumerated().map { ($1.descriptor.id, $0) })
        self.snapshots = results.sorted { order[$0.id, default: .max] < order[$1.id, default: .max] }
        self.notificationController.process(
            self.snapshots,
            warningThreshold: self.warningThreshold,
            criticalThreshold: self.criticalThreshold,
            enabledProviderIDs: self.notificationProviderIDs)
        self.lastRefresh = .now
        do {
            try await self.historyStore.record(self.snapshots, at: self.lastRefresh ?? .now)
            self.historyRecords = try await self.historyStore.records()
        } catch {
            // History is an optional local enhancement and must not fail provider refreshes.
        }
        await self.refreshExchangeRate()
        self.isRefreshing = false
    }

    func isEnabled(_ id: ProviderID) -> Bool {
        self.enabledProviderIDs.contains(id)
    }

    func setEnabled(_ enabled: Bool, for id: ProviderID) {
        if enabled {
            self.enabledProviderIDs.insert(id)
        } else {
            self.enabledProviderIDs.remove(id)
        }
        UserDefaults.standard.set(
            self.enabledProviderIDs.map(\.rawValue).sorted(),
            forKey: Self.enabledProvidersKey)
        self.snapshots = self.providers
            .filter { self.enabledProviderIDs.contains($0.descriptor.id) }
            .map { provider in
                self.snapshots.first(where: { $0.id == provider.descriptor.id }) ?? .loading(provider.descriptor)
            }
        Task { await self.refresh() }
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        Task {
            let accepted = await self.notificationController.setEnabled(enabled)
            self.notificationsEnabled = accepted
            self.notificationSettingsMessage = enabled && !accepted
                ? AppLocalization.string("settings.notifications.denied")
                : nil
        }
    }

    func setWarningThreshold(_ threshold: Int) {
        self.warningThreshold = threshold
        UserDefaults.standard.set(threshold, forKey: Self.warningThresholdKey)
    }

    func setCriticalThreshold(_ threshold: Int) {
        self.criticalThreshold = threshold
        UserDefaults.standard.set(threshold, forKey: Self.criticalThresholdKey)
    }

    func isNotificationEnabled(for id: ProviderID) -> Bool {
        self.notificationProviderIDs.contains(id)
    }

    func setNotificationEnabled(_ enabled: Bool, for id: ProviderID) {
        if enabled {
            self.notificationProviderIDs.insert(id)
        } else {
            self.notificationProviderIDs.remove(id)
        }
        UserDefaults.standard.set(
            self.notificationProviderIDs.map(\.rawValue).sorted(),
            forKey: Self.notificationProviderIDsKey)
    }

    func sendTestNotification() {
        self.notificationController.sendTest()
    }

    func clearHistory() {
        Task {
            try? await self.historyStore.clear()
            self.historyRecords = []
        }
    }

    func setCostDisplayCurrency(_ currency: CostDisplayCurrency) {
        self.costDisplayCurrency = currency
        UserDefaults.standard.set(currency.rawValue, forKey: Self.costDisplayCurrencyKey)
        if currency == .krw, self.exchangeRateQuote == nil {
            Task { await self.refreshExchangeRate() }
        }
    }

    func setAppLanguage(_ language: AppLanguage) {
        self.appLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.defaultsKey)
        if self.notificationSettingsMessage != nil {
            self.notificationSettingsMessage = AppLocalization.string("settings.notifications.denied")
        }
    }

    func refreshExchangeRate() async {
        if let quote = try? await self.exchangeRateClient.quote() {
            self.exchangeRateQuote = quote
        }
    }

    func setShowsRemainingInMenuBar(_ enabled: Bool) {
        self.showsRemainingInMenuBar = enabled
        UserDefaults.standard.set(enabled, forKey: Self.showsRemainingInMenuBarKey)
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try self.launchAtLoginController.setEnabled(enabled)
            self.launchAtLoginEnabled = self.launchAtLoginController.isEnabled
            self.launchAtLoginMessage = self.launchAtLoginController.statusMessage
        } catch {
            self.launchAtLoginEnabled = self.launchAtLoginController.isEnabled
            self.launchAtLoginMessage = error.localizedDescription
        }
    }

    var menuBarRemainingPercent: Double? {
        guard self.showsRemainingInMenuBar else { return nil }
        return UsageSummary.minimumRemainingPercent(in: self.snapshots)
    }

    var descriptors: [ProviderDescriptor] {
        self.providers.map(\.descriptor)
    }
}
