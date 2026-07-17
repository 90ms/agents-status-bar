@testable import AgentsStatusCore
import Foundation
import Testing

struct ProviderParserTests {
    @Test
    func codexParsesQuotaAndTokenUsage() throws {
        let file = try #require(Bundle.module.url(
            forResource: "codex-token-count",
            withExtension: "jsonl",
            subdirectory: "Fixtures"))
        let parsed = try #require(CodexLogParser.latestUsage(in: file))

        #expect(parsed.tokenUsage.totalTokens == 1750)
        #expect(parsed.quotaWindows.count == 2)
        #expect(parsed.quotaWindows[0].usedPercent == 32)
        #expect(parsed.credits?.balance == "12.50")
    }

    @Test
    func codexAccountUsageMapsWeeklyAndModelLimits() throws {
        let file = try #require(Bundle.module.url(
            forResource: "codex-account-usage",
            withExtension: "json",
            subdirectory: "Fixtures"))
        let response = try JSONDecoder().decode(
            CodexAccountUsageResponse.self,
            from: Data(contentsOf: file))
        let windows = response.quotaWindows()

        #expect(response.planType == "prolite")
        #expect(windows.map(\.label) == ["Weekly", "GPT-5.3-Codex-Spark weekly"])
        #expect(windows.map(\.usedPercent) == [28, 3])
        #expect(windows.map(\.remainingPercent) == [72, 97])
        #expect(response.creditBalance?.balance == "0")
    }

    @Test
    func codexCredentialParserAcceptsSnakeAndCamelCaseWithoutExposingToken() throws {
        let snake = try CodexAccountCredentials.decode(Data(
            #"{"tokens":{"access_token":"fake-token","account_id":"account-1"}}"#.utf8))
        let camel = try CodexAccountCredentials.decode(Data(
            #"{"tokens":{"accessToken":"fake-token","accountId":"account-2"}}"#.utf8))

        #expect(snake.accountID == "account-1")
        #expect(camel.accountID == "account-2")
    }

    @Test
    func claudeDeduplicatesStreamingUsageRecords() throws {
        let file = try #require(Bundle.module.url(
            forResource: "claude-usage",
            withExtension: "jsonl",
            subdirectory: "Fixtures"))
        let usage = ClaudeLogParser.aggregate(files: [file], since: .distantPast)

        #expect(usage.inputTokens == 120)
        #expect(usage.cachedInputTokens == 80)
        #expect(usage.outputTokens == 30)
        #expect(usage.totalTokens == 230)
    }

    @Test
    func providerIDsAreOpenForExtension() {
        let custom = ProviderID(rawValue: "gemini")
        #expect(custom.rawValue == "gemini")
        #expect(custom != .codex)
    }

    @Test
    func claudeShowsConnectedWhenTodaySessionHasNoUsageYet() async throws {
        let temporaryHome = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let projects = temporaryHome.appending(path: ".claude/projects/test", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: projects, withIntermediateDirectories: true)
        let session = projects.appending(path: "session.jsonl")
        try Data("{\"timestamp\":\"2026-07-17T06:42:00Z\",\"type\":\"user\"}\n".utf8).write(to: session)
        defer { try? FileManager.default.removeItem(at: temporaryHome) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
        let snapshot = await ClaudeUsageProvider(
            homeDirectory: temporaryHome,
            calendar: calendar,
            allowKeychain: false).fetchUsage()

        #expect(snapshot.availability == .available)
        #expect(snapshot.tokenUsage?.totalTokens == 0)
    }

    @Test
    func claudeOAuthMapsSessionWeeklyAndScopedLimits() throws {
        let file = try #require(Bundle.module.url(
            forResource: "claude-oauth-usage",
            withExtension: "json",
            subdirectory: "Fixtures"))
        let data = try Data(contentsOf: file)
        let response = try JSONDecoder().decode(ClaudeOAuthUsageResponse.self, from: data)
        let windows = response.quotaWindows()

        #expect(windows.map(\.label) == ["5-hour", "Weekly", "Fable weekly"])
        #expect(windows.map(\.usedPercent) == [12, 34, 25])
        #expect(windows.allSatisfy { $0.resetsAt != nil })
    }

    @Test
    func claudeCredentialParserNeverNeedsToExposeToken() throws {
        let data = Data(#"{"claudeAiOauth":{"accessToken":"fake-access-token","expiresAt":4102444800000,"rateLimitTier":"default_claude_max_5x","subscriptionType":"max"}}"#.utf8)
        let credentials = try ClaudeOAuthCredentials.decode(data)

        #expect(credentials.subscriptionType == "max")
        #expect(credentials.rateLimitTier == "default_claude_max_5x")
        #expect(!credentials.isExpired)
    }
}
