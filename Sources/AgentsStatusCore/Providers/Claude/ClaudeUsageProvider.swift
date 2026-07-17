import Foundation

public struct ClaudeUsageProvider: UsageProviding {
    public let descriptor = ProviderDescriptor(
        id: .claude,
        displayName: "Claude Code",
        shortName: "Claude",
        systemImage: "sparkles",
        capabilities: .init(supportsTokenUsage: true))

    private let projectsDirectory: URL
    private let calendar: Calendar
    private let credentialLoader: ClaudeOAuthCredentialLoader
    private let oauthClient: ClaudeOAuthUsageClient

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        calendar: Calendar = .current,
        allowKeychain: Bool = true)
    {
        self.projectsDirectory = homeDirectory.appending(path: ".claude/projects", directoryHint: .isDirectory)
        self.calendar = calendar
        self.credentialLoader = ClaudeOAuthCredentialLoader(
            homeDirectory: homeDirectory,
            allowKeychain: allowKeychain)
        self.oauthClient = ClaudeOAuthUsageClient()
    }

    public func fetchUsage() async -> ProviderSnapshot {
        let startOfDay = self.calendar.startOfDay(for: .now)
        let files = LocalFiles.newestFiles(
            below: self.projectsDirectory,
            extension: "jsonl",
            modifiedAfter: startOfDay,
            limit: 200)
        let usage = ClaudeLogParser.aggregate(files: files, since: startOfDay)
        let localTokenUsage = usage.totalTokens > 0
            ? usage
            : files.isEmpty ? nil : TokenUsage(label: "Today", totalTokens: 0)

        do {
            let credentials = try self.credentialLoader.load()
            let result = try await self.oauthClient.fetch(accessToken: credentials.accessToken)
            let oauthUsage = result.response
            let plan = credentials.subscriptionType ?? credentials.rateLimitTier
            let detail = [plan, "Claude Code OAuth"]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            return .init(
                descriptor: self.descriptor,
                availability: .available,
                source: .officialAPI,
                quotaWindows: oauthUsage.quotaWindows(),
                tokenUsage: localTokenUsage,
                detail: detail.isEmpty ? "Claude Code OAuth" : detail,
                updatedAt: result.fetchedAt)
        } catch {
            return self.localFallback(files: files, usage: usage, oauthError: error)
        }
    }

    private func localFallback(files: [URL], usage: TokenUsage, oauthError: Error) -> ProviderSnapshot {
        let errorMessage = (oauthError as? LocalizedError)?.errorDescription
        guard !files.isEmpty else {
            return .init(
                descriptor: self.descriptor,
                availability: .stale,
                source: .localSessionLog,
                detail: errorMessage ?? "Claude Code is installed, but no local session was updated today")
        }

        guard usage.totalTokens > 0 else {
            return .init(
                descriptor: self.descriptor,
                availability: .available,
                source: .localSessionLog,
                tokenUsage: TokenUsage(label: "Today", totalTokens: 0),
                detail: errorMessage.map { "Connected · \($0)" }
                    ?? "Connected · no token usage record in today's session yet")
        }

        return .init(
            descriptor: self.descriptor,
            availability: .available,
            source: .localSessionLog,
            tokenUsage: usage,
            detail: errorMessage.map { "Local usage fallback · \($0)" }
                ?? "Today across local Claude Code sessions")
    }
}

enum ClaudeLogParser {
    static func aggregate(files: [URL], since startDate: Date) -> TokenUsage {
        var seenMessageIDs: Set<String> = []
        var input: Int64 = 0
        var cached: Int64 = 0
        var output: Int64 = 0

        for file in files {
            for line in LocalFiles.lines(in: file) {
                guard let record = try? JSONDecoder().decode(ClaudeRecord.self, from: line),
                      let usage = record.message?.usage,
                      let timestamp = TimestampParser.parse(record.timestamp),
                      timestamp >= startDate
                else { continue }

                let identifier = record.message?.id ?? record.uuid ?? "\(file.path):\(record.timestamp ?? "")"
                guard seenMessageIDs.insert(identifier).inserted else { continue }
                input += usage.inputTokens + usage.cacheCreationInputTokens
                cached += usage.cacheReadInputTokens
                output += usage.outputTokens
            }
        }

        return TokenUsage(
            label: "Today",
            inputTokens: input,
            cachedInputTokens: cached,
            outputTokens: output,
            totalTokens: input + cached + output)
    }
}

private struct ClaudeRecord: Decodable {
    let uuid: String?
    let timestamp: String?
    let message: Message?

    struct Message: Decodable {
        let id: String?
        let usage: Usage?
    }

    struct Usage: Decodable {
        let inputTokens: Int64
        let cacheCreationInputTokens: Int64
        let cacheReadInputTokens: Int64
        let outputTokens: Int64

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
            case outputTokens = "output_tokens"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.inputTokens = try container.decodeIfPresent(Int64.self, forKey: .inputTokens) ?? 0
            self.cacheCreationInputTokens = try container.decodeIfPresent(
                Int64.self,
                forKey: .cacheCreationInputTokens) ?? 0
            self.cacheReadInputTokens = try container.decodeIfPresent(
                Int64.self,
                forKey: .cacheReadInputTokens) ?? 0
            self.outputTokens = try container.decodeIfPresent(Int64.self, forKey: .outputTokens) ?? 0
        }
    }
}
