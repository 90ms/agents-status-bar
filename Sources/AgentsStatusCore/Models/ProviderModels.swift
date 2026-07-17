import Foundation

public struct ProviderID: RawRepresentable, Codable, Hashable, Sendable, Identifiable,
    ExpressibleByStringLiteral
{
    public let rawValue: String
    public var id: String { self.rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let codex: Self = "codex"
    public static let claude: Self = "claude"
    public static let grok: Self = "grok"
}

public struct ProviderCapabilities: Hashable, Sendable {
    public let supportsQuotaWindows: Bool
    public let supportsTokenUsage: Bool
    public let supportsCredits: Bool
    public let supportsAccountIdentity: Bool

    public init(
        supportsQuotaWindows: Bool = false,
        supportsTokenUsage: Bool = false,
        supportsCredits: Bool = false,
        supportsAccountIdentity: Bool = false)
    {
        self.supportsQuotaWindows = supportsQuotaWindows
        self.supportsTokenUsage = supportsTokenUsage
        self.supportsCredits = supportsCredits
        self.supportsAccountIdentity = supportsAccountIdentity
    }
}

public struct ProviderDescriptor: Identifiable, Hashable, Sendable {
    public let id: ProviderID
    public let displayName: String
    public let shortName: String
    public let systemImage: String
    public let capabilities: ProviderCapabilities

    public init(
        id: ProviderID,
        displayName: String,
        shortName: String,
        systemImage: String,
        capabilities: ProviderCapabilities)
    {
        self.id = id
        self.displayName = displayName
        self.shortName = shortName
        self.systemImage = systemImage
        self.capabilities = capabilities
    }
}

public enum ProviderAvailability: String, Codable, Hashable, Sendable {
    case loading
    case available
    case stale
    case unavailable
    case failed
}

public enum UsageDataSource: String, Codable, Hashable, Sendable {
    case localSessionLog
    case localProtocol
    case officialAPI
    case estimated
}

public enum QuotaWindowKind: String, Codable, Hashable, Sendable {
    case session
    case weekly
    case monthly
    case context
    case custom
}

public struct QuotaWindow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: QuotaWindowKind
    public let label: String
    public let usedPercent: Double
    public let resetsAt: Date?
    public let durationMinutes: Int?

    public var remainingPercent: Double {
        100 - self.usedPercent
    }

    public init(
        id: String,
        kind: QuotaWindowKind,
        label: String,
        usedPercent: Double,
        resetsAt: Date? = nil,
        durationMinutes: Int? = nil)
    {
        self.id = id
        self.kind = kind
        self.label = label
        self.usedPercent = min(max(usedPercent, 0), 100)
        self.resetsAt = resetsAt
        self.durationMinutes = durationMinutes
    }
}

public struct TokenUsage: Codable, Hashable, Sendable {
    public let label: String
    public let inputTokens: Int64?
    public let cachedInputTokens: Int64?
    public let outputTokens: Int64?
    public let reasoningTokens: Int64?
    public let totalTokens: Int64

    public init(
        label: String,
        inputTokens: Int64? = nil,
        cachedInputTokens: Int64? = nil,
        outputTokens: Int64? = nil,
        reasoningTokens: Int64? = nil,
        totalTokens: Int64)
    {
        self.label = label
        self.inputTokens = inputTokens
        self.cachedInputTokens = cachedInputTokens
        self.outputTokens = outputTokens
        self.reasoningTokens = reasoningTokens
        self.totalTokens = totalTokens
    }
}

public struct CreditBalance: Codable, Hashable, Sendable {
    public let balance: String?
    public let hasCredits: Bool
    public let unlimited: Bool

    public init(balance: String?, hasCredits: Bool, unlimited: Bool) {
        self.balance = balance
        self.hasCredits = hasCredits
        self.unlimited = unlimited
    }
}

public struct ProviderSnapshot: Identifiable, Hashable, Sendable {
    public let descriptor: ProviderDescriptor
    public let availability: ProviderAvailability
    public let source: UsageDataSource?
    public let quotaWindows: [QuotaWindow]
    public let tokenUsage: TokenUsage?
    public let credits: CreditBalance?
    public let detail: String?
    public let updatedAt: Date

    public var id: ProviderID { self.descriptor.id }

    public init(
        descriptor: ProviderDescriptor,
        availability: ProviderAvailability,
        source: UsageDataSource?,
        quotaWindows: [QuotaWindow] = [],
        tokenUsage: TokenUsage? = nil,
        credits: CreditBalance? = nil,
        detail: String? = nil,
        updatedAt: Date = .now)
    {
        self.descriptor = descriptor
        self.availability = availability
        self.source = source
        self.quotaWindows = quotaWindows
        self.tokenUsage = tokenUsage
        self.credits = credits
        self.detail = detail
        self.updatedAt = updatedAt
    }

    public static func loading(_ descriptor: ProviderDescriptor) -> Self {
        .init(
            descriptor: descriptor,
            availability: .loading,
            source: nil,
            detail: "Refreshing usage…")
    }
}
