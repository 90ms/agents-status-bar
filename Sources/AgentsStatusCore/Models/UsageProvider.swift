import Foundation

public protocol UsageProviding: Sendable {
    var descriptor: ProviderDescriptor { get }
    func fetchUsage() async -> ProviderSnapshot
}

public enum ProviderRegistry {
    public static func defaultProviders(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser)
        -> [any UsageProviding]
    {
        [
            CodexUsageProvider(homeDirectory: homeDirectory),
            ClaudeUsageProvider(homeDirectory: homeDirectory),
            GrokUsageProvider(homeDirectory: homeDirectory),
        ]
    }
}
