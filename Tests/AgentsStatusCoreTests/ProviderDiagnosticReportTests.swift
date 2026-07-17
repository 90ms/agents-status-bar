@testable import AgentsStatusCore
import Foundation
import Testing

struct ProviderDiagnosticReportTests {
    @Test
    func reportContainsOnlyAggregatedFieldsAndSanitizedIdentifiers() {
        let homePath = "/Users/alice/private/session.jsonl"
        let secret = "sk-private-auth-token"
        let prompt = "PROMPT-MUST-NOT-BE-COPIED"
        let response = "RESPONSE-MUST-NOT-BE-COPIED"
        let descriptor = ProviderDescriptor(
            id: ProviderID(rawValue: "custom/provider"),
            displayName: "\(prompt) \(homePath)",
            shortName: secret,
            systemImage: response,
            capabilities: .init(supportsQuotaWindows: true, supportsTokenUsage: true))
        let snapshot = ProviderSnapshot(
            descriptor: descriptor,
            availability: .failed,
            source: .localSessionLog,
            quotaWindows: [
                QuotaWindow(
                    id: secret,
                    kind: .weekly,
                    label: "\(prompt) \(homePath)",
                    usedPercent: 42,
                    durationMinutes: 10_080),
            ],
            tokenUsage: TokenUsage(
                label: response,
                modelID: "safe-model-1",
                inputTokens: 10,
                outputTokens: 2,
                totalTokens: 12),
            costEstimate: TokenCostEstimate(
                label: prompt,
                amountUSD: 99,
                modelIDs: ["safe-model-1"]),
            credits: CreditBalance(balance: secret, hasCredits: true, unlimited: false),
            detail: "Authorization: Bearer \(secret); cookie=value; \(prompt); \(response); \(homePath)",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000))

        let report = ProviderDiagnosticReportBuilder.text(
            appName: "Agents Status Bar",
            appVersion: "1.2.3",
            appBuild: "45",
            osVersion: "macOS 15.5",
            snapshots: [snapshot],
            generatedAt: Date(timeIntervalSince1970: 1_700_000_060))

        #expect(report.contains("id=custom_provider"))
        #expect(report.contains("availability=failed"))
        #expect(report.contains("quota_0_used_percent=42"))
        #expect(report.contains("token_model=safe-model-1"))
        #expect(report.contains("token_total=12"))
        #expect(report.contains("cost_models=safe-model-1"))
        #expect(report.contains("freshness_seconds=60"))
        #expect(!report.contains(homePath))
        #expect(!report.contains(secret))
        #expect(!report.contains(prompt))
        #expect(!report.contains(response))
        #expect(!report.localizedCaseInsensitiveContains("cookie=value"))
        #expect(!report.localizedCaseInsensitiveContains("authorization:"))
        #expect(!report.contains("99"))
    }

    @Test
    func sanitizerRejectsAbsolutePathsAndCredentialLikeValues() {
        #expect(DiagnosticSanitizer.scalar("/Users/alice/.config") == "redacted")
        #expect(DiagnosticSanitizer.scalar("Bearer abc123") == "redacted")
        #expect(DiagnosticSanitizer.scalar("model/with/slash") == "model_with_slash")
    }
}
