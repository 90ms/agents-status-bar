import Foundation

public struct ModelTokenPricing: Hashable, Sendable {
    public let inputPerMillion: Double
    public let cacheCreationPerMillion: Double?
    public let cacheCreation1hPerMillion: Double?
    public let cachedInputPerMillion: Double
    public let outputPerMillion: Double

    public init(
        inputPerMillion: Double,
        cacheCreationPerMillion: Double? = nil,
        cacheCreation1hPerMillion: Double? = nil,
        cachedInputPerMillion: Double,
        outputPerMillion: Double)
    {
        self.inputPerMillion = inputPerMillion
        self.cacheCreationPerMillion = cacheCreationPerMillion
        self.cacheCreation1hPerMillion = cacheCreation1hPerMillion
        self.cachedInputPerMillion = cachedInputPerMillion
        self.outputPerMillion = outputPerMillion
    }

    public func estimate(_ usage: TokenUsage) -> Double {
        let input = Double(usage.inputTokens ?? 0) * self.inputPerMillion
        let cacheCreation = Double(usage.cacheCreationInputTokens ?? 0)
            * (self.cacheCreationPerMillion ?? self.inputPerMillion)
        let cacheCreation1h = Double(usage.cacheCreation1hInputTokens ?? 0)
            * (self.cacheCreation1hPerMillion ?? self.cacheCreationPerMillion
                ?? self.inputPerMillion)
        let cached = Double(usage.cachedInputTokens ?? 0) * self.cachedInputPerMillion
        let output = Double((usage.outputTokens ?? 0) + (usage.reasoningTokens ?? 0))
            * self.outputPerMillion
        return (input + cacheCreation + cacheCreation1h + cached + output) / 1_000_000
    }
}

public enum TokenPricingCatalog {
    public static func pricing(
        providerID: ProviderID,
        modelID: String,
        at date: Date = .now) -> ModelTokenPricing?
    {
        let model = modelID.lowercased()
        switch providerID {
        case .codex:
            return self.openAIPricing(model: model)
        case .claude:
            return self.claudePricing(model: model, at: date)
        default:
            return nil
        }
    }

    public static func estimate(
        providerID: ProviderID,
        usage: TokenUsage,
        at date: Date = .now) -> TokenCostEstimate?
    {
        guard let modelID = usage.modelID,
              let pricing = self.pricing(providerID: providerID, modelID: modelID, at: date)
        else { return nil }
        return TokenCostEstimate(
            label: usage.label,
            amountUSD: pricing.estimate(usage),
            modelIDs: [modelID])
    }

    private static func openAIPricing(model: String) -> ModelTokenPricing? {
        if model.contains("gpt-5.6-sol") {
            return .init(inputPerMillion: 5, cachedInputPerMillion: 0.5, outputPerMillion: 30)
        }
        if model.contains("gpt-5.6-terra") {
            return .init(inputPerMillion: 2.5, cachedInputPerMillion: 0.25, outputPerMillion: 15)
        }
        if model.contains("gpt-5.6-luna") {
            return .init(inputPerMillion: 1, cachedInputPerMillion: 0.1, outputPerMillion: 6)
        }
        if model.contains("gpt-5-codex") || model == "gpt-5" {
            return .init(inputPerMillion: 1.25, cachedInputPerMillion: 0.125, outputPerMillion: 10)
        }
        return nil
    }

    private static func claudePricing(model: String, at date: Date) -> ModelTokenPricing? {
        if model.contains("sonnet-5") {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let promotionEnd = calendar.date(from: DateComponents(
                year: 2026,
                month: 9,
                day: 1))!
            if date < promotionEnd {
                return .init(
                    inputPerMillion: 2,
                    cacheCreationPerMillion: 2.5,
                    cacheCreation1hPerMillion: 4,
                    cachedInputPerMillion: 0.2,
                    outputPerMillion: 10)
            }
            return .init(
                inputPerMillion: 3,
                cacheCreationPerMillion: 3.75,
                cacheCreation1hPerMillion: 6,
                cachedInputPerMillion: 0.3,
                outputPerMillion: 15)
        }
        if model.contains("opus-4") {
            return .init(
                inputPerMillion: 5,
                cacheCreationPerMillion: 6.25,
                cacheCreation1hPerMillion: 10,
                cachedInputPerMillion: 0.5,
                outputPerMillion: 25)
        }
        if model.contains("sonnet-4") {
            return .init(
                inputPerMillion: 3,
                cacheCreationPerMillion: 3.75,
                cacheCreation1hPerMillion: 6,
                cachedInputPerMillion: 0.3,
                outputPerMillion: 15)
        }
        if model.contains("haiku-4") {
            return .init(
                inputPerMillion: 1,
                cacheCreationPerMillion: 1.25,
                cacheCreation1hPerMillion: 2,
                cachedInputPerMillion: 0.1,
                outputPerMillion: 5)
        }
        return nil
    }
}
