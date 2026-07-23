# Agents Status Bar

**English** | [한국어](README.ko.md)

A privacy-conscious macOS menu-bar app for checking AI coding-agent quotas, account or local token usage, and API-price-equivalent reference costs in one place.

<p align="center">
  <img src="docs/agents-status-bar.png" width="450" alt="Agents Status Bar showing Codex, Claude Code, and Gemini CLI usage" />
</p>

> The preview reflects the current `main` UI and uses sample values. It contains no account data.

## At a glance

| Area | What you can do |
| --- | --- |
| Quotas | See remaining percentage, reset time, provider status, model-specific limits, and Codex limit-reset credits |
| Tokens and cost | View Codex's latest available daily, current-month, and lifetime account activity alongside provider-local usage, with API-equivalent reference costs in USD or KRW |
| Menu bar | Show an icon, the lowest remaining quota, monthly estimated cost, or one selected provider; Claude can use its 5-hour, weekly, or Fable quota |
| Active sessions | See a fixed-width waveform pulse in the menu bar while a known local session file is being updated |
| History | Compare quota and accumulated estimated cost over 24 hours, 7 days, or 30 days |
| Alerts and budget | Configure provider-specific warning/critical thresholds and optional monthly budget alerts |
| Customization | Choose providers, language, compact mode, activity window, currency, and launch at login |
| Maintenance | Check GitHub Releases, refresh the model-price catalog, and copy privacy-safe diagnostics |

All quota percentages are displayed as **remaining values** (`% left`), not consumed values.

## Install

The latest packaged preview is `v0.5.1`. It requires macOS 14 or later and Apple silicon.

### Homebrew

```bash
brew tap 90ms/agents-status-bar https://github.com/90ms/agents-status-bar
brew install --cask 90ms/agents-status-bar/agents-status-bar
open -a "Agents Status Bar"
```

To uninstall:

```bash
brew uninstall --cask agents-status-bar
brew untap 90ms/agents-status-bar
```

### GitHub Release

Download `AgentsStatusBar-0.5.1.zip` from [Releases](https://github.com/90ms/agents-status-bar/releases), unzip it, and move `Agents Status Bar.app` to `/Applications`.

The preview is ad-hoc signed because it does not yet use a Developer ID certificate. On first launch, macOS may require approval in **System Settings → Privacy & Security**.

### Build the current `main` branch

```bash
git clone https://github.com/90ms/agents-status-bar.git
cd agents-status-bar
./Scripts/test.sh
./Scripts/package_app.sh
open "dist/Agents Status Bar.app"
```

`Scripts/package_app.sh` uses ad-hoc signing by default. Set `APP_SIGN_IDENTITY` to use another local signing identity.

## Before the first launch

Sign in with each command-line agent you want to monitor:

```bash
codex
claude
grok
gemini
opencode
```

Only installed and signed-in providers can report data. Providers you do not use can be disabled in **Settings → General**.

Claude Code may keep its OAuth credentials in macOS Keychain. Use **Settings → General → Provider Connections → Claude Code → Connect** to approve access explicitly. Background refreshes suppress Keychain authentication UI, so locking and unlocking the Mac does not produce recurring approval dialogs. After approval, the credential remains only in app memory until it expires or the app exits.

## Provider support

| Provider | Account quota | Token usage and cost source |
| --- | --- | --- |
| Codex | Weekly and model-specific limits plus available limit-reset credits and expiration | Latest available daily, current-month, and lifetime account token activity through the experimental Codex app-server; API-equivalent reference estimates |
| Claude Code | 5-hour, weekly, and model-scoped limits | Today's deduplicated tokens from `~/.claude/projects`; cache-aware cost estimate |
| Grok | Account quota unavailable | Current context usage from `~/.grok/sessions`; no cost estimate yet |
| Gemini CLI | Account quota unavailable | Latest session tokens from `~/.gemini/tmp/*/chats`; no cost estimate yet |
| OpenCode | Account quota unavailable | Aggregate tokens and recorded cost from `~/.local/share/opencode/opencode*.db` |

Codex and Claude reuse their existing CLI sign-ins for account usage endpoints. Codex account token activity is requested through the experimental `codex app-server` `account/usage/read` method, so both Macs should show the same activity when they use the same Codex account and workspace. Claude Keychain access is user-initiated from Settings and cached only in memory. If an account request fails, the app shows a stale/unavailable state or falls back to verified local data instead of inventing a quota.

Provider CLI formats and usage endpoints are not public compatibility contracts and may change.

## Refresh and active-session behavior

- Quotas and usage refresh automatically once per minute.
- The refresh button bypasses provider caches where supported.
- Background refreshes never present a Keychain approval dialog.
- Codex account responses are cached for at most one minute and are invalidated as soon as a known reset time passes.
- Codex account token activity provides the latest available daily bucket, current-month buckets, and lifetime total independently of local session files when the installed CLI supports the experimental app-server method.
- The latest daily row includes its account-bucket date and remains visible after the local calendar day changes, so a delayed Codex bucket is not lost behind a perpetually pending “Today” row.
- Codex limit-reset credits are refreshed independently, cached for up to five minutes, and show the available count, title, and expiration returned by the account endpoint.
- Activity detection checks only known session-file modification times every three seconds.
- A session stays active for a configurable 10, 15, or 30 seconds after the latest write.
- The menu-bar waveform pulses once after each activity check; macOS Reduce Motion keeps it static.

Activity is a local file-change signal. It does not guarantee that a provider is currently generating a response.

## Cost, exchange rates, history, and budgets

Cost is a reference estimate of what available account or local token totals might cost at published API prices. It is **not** a Codex, Claude, Grok, ChatGPT, or Claude subscription charge or an API billing statement.

Codex account activity supplies aggregate token totals without the historical model, input/output, cache, or reasoning-token split needed for exact API pricing. Its latest-daily, month, and lifetime values therefore use a rough API-equivalent reference estimate; the token totals are the authoritative part of that section.

The current reference profile uses the validated `gpt-5-codex` catalog price and assumes an 80% uncached-input / 20% output mix. This versioned assumption is applied consistently on every Mac; it does not describe the account's actual historical model or token mix.

- Choose USD or KRW in Settings.
- USD/KRW is checked once per Seoul calendar day through [Frankfurter](https://frankfurter.dev/) using its ECB provider.
- The applied rate and rate date are visible in Settings; weekends and holidays may use the latest earlier ECB rate.
- The versioned price catalog checks this repository once per day and rejects invalid schemas, unsafe prices, untrusted sources, and downgrades.
- Usage history samples aggregate quota, token, and estimated-cost fields every 15 minutes and retains them locally for 30 days.
- The monthly menu and budget use Codex's current account-month reference plus locally observed cost changes from other providers.
- Optional budget notifications fire at 50%, 80%, and 100% when notifications are enabled.

Unknown models are left without a cost instead of being mapped to a guessed price. The bundled catalog follows the official [OpenAI model pricing](https://developers.openai.com/api/docs/models) and [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) pages.

## Settings

| Tab | Options |
| --- | --- |
| General | UI language, enabled providers, provider connections, menu-bar label, selected provider, Claude menu-bar quota (5-hour/weekly/Fable), compact mode, activity animation/window, launch at login, update check |
| Alerts | Low-usage notifications, warning and critical thresholds, provider selection, test notification |
| Usage | USD/KRW display, applied exchange rate, price-catalog update, monthly budget, usage-history window |
| Privacy | Local-data explanation and copyable provider diagnostics |

The UI language can follow the system or be set explicitly to English or Korean.

See the [usage display guide](docs/usage.md) for the exact Codex bucket and Claude menu-bar selection behavior.

## Updates

The app checks GitHub Releases every six hours and displays a link when a newer stable version is available. Download and installation remain manual while releases are ad-hoc signed. Automatic in-app installation can be added later with Developer ID signing, notarization, and a signed update feed.

## Privacy and security

- No prompts or model responses are displayed or retained.
- Authentication tokens, refresh tokens, and cookies are never logged or copied into app storage.
- Claude credentials obtained after explicit approval are cached only in memory until expiry or app exit.
- Local parsing is limited to known aggregate usage fields, activity-file metadata, and OpenCode aggregate database columns. Codex token statistics come from account activity rather than local session-token totals.
- Activity detection reads file metadata only, not prompt or response content.
- History contains only aggregate percentages, token totals, and estimated cost and is retained for 30 days.
- Exchange-rate and pricing caches contain only public data and validation metadata.
- Limit-reset credit history is not stored; the UI shows only the current account response.
- Diagnostics exclude prompts, responses, credentials, cookies, provider detail text, and file paths.
- The app has no analytics or telemetry.

## Architecture and provider extension

```text
ProviderRegistry
    ├── CodexUsageProvider    ── account quota + app-server token activity
    ├── ClaudeUsageProvider   ── account usage + ~/.claude/projects
    ├── GrokUsageProvider     ── ~/.grok/sessions
    ├── GeminiUsageProvider   ── ~/.gemini/tmp/*/chats
    └── OpenCodeUsageProvider ── aggregate SQLite columns
               │
               ▼
        ProviderSnapshot
               │
               ▼
           UsageStore
               │
               ▼
       SwiftUI MenuBarExtra
```

`ProviderID` is an open string-backed type. To add a platform, implement `UsageProviding`, keep authentication and parsing inside a provider directory, add sanitized fixture tests, and register the provider with `ProviderRegistry`.

## Development

```bash
./Scripts/test.sh
swift build
./Scripts/package_app.sh
```

The project includes fixture-backed parser tests and a macOS GitHub Actions build. See [AGENTS.md](AGENTS.md) for contribution conventions. The editable source for the README preview is [docs/agents-status-bar.svg](docs/agents-status-bar.svg).

## License

[MIT](LICENSE)
