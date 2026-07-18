# Agents Status Bar

**English** | [한국어](README.ko.md)

A privacy-conscious macOS menu-bar app for checking AI coding-agent quotas, local token usage, and API-price-equivalent costs in one place.

<p align="center">
  <img src="docs/agents-status-bar.png" width="450" alt="Agents Status Bar showing Codex, Claude Code, and Gemini CLI usage" />
</p>

> The preview reflects the current `main` UI and uses sample values. It contains no account data.

## At a glance

| Area | What you can do |
| --- | --- |
| Quotas | See remaining percentage, reset time, provider status, and model-specific limits |
| Tokens and cost | View locally observed tokens and their estimated API-price equivalent in USD or KRW |
| Menu bar | Show an icon, the lowest remaining quota, monthly estimated cost, or one selected provider |
| Active sessions | See a fixed-width waveform pulse in the menu bar while a known local session file is being updated |
| History | Compare quota and accumulated estimated cost over 24 hours, 7 days, or 30 days |
| Alerts and budget | Configure provider-specific warning/critical thresholds and optional monthly budget alerts |
| Customization | Choose providers, language, compact mode, activity window, currency, and launch at login |
| Maintenance | Check GitHub Releases, refresh the model-price catalog, and copy privacy-safe diagnostics |

All quota percentages are displayed as **remaining values** (`% left`), not consumed values.

## Install

The latest packaged preview is `v0.4.1`. It requires macOS 14 or later and Apple silicon.

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

Download `AgentsStatusBar-0.4.1.zip` from [Releases](https://github.com/90ms/agents-status-bar/releases), unzip it, and move `Agents Status Bar.app` to `/Applications`.

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

| Provider | Account quota | Local usage and cost source |
| --- | --- | --- |
| Codex | Weekly and model-specific limits | Latest session tokens from `~/.codex/sessions`; estimated with the detected model |
| Claude Code | 5-hour, weekly, and model-scoped limits | Today's deduplicated tokens from `~/.claude/projects`; cache-aware cost estimate |
| Grok | Account quota unavailable | Current context usage from `~/.grok/sessions`; no cost estimate yet |
| Gemini CLI | Account quota unavailable | Latest session tokens from `~/.gemini/tmp/*/chats`; no cost estimate yet |
| OpenCode | Account quota unavailable | Aggregate tokens and recorded cost from `~/.local/share/opencode/opencode*.db` |

Codex and Claude reuse their existing CLI sign-ins for account usage endpoints. Claude Keychain access is user-initiated from Settings and cached only in memory. If an account request fails, the app shows a stale/unavailable state or falls back to verified local data instead of inventing a quota.

Provider CLI formats and usage endpoints are not public compatibility contracts and may change.

## Refresh and active-session behavior

- Quotas and usage refresh automatically once per minute.
- The refresh button bypasses provider caches where supported.
- Background refreshes never present a Keychain approval dialog.
- Codex account responses are cached for at most one minute and are invalidated as soon as a known reset time passes.
- Activity detection checks only known session-file modification times every three seconds.
- A session stays active for a configurable 10, 15, or 30 seconds after the latest write.
- The menu-bar waveform pulses once after each activity check; macOS Reduce Motion keeps it static.

Activity is a local file-change signal. It does not guarantee that a provider is currently generating a response.

## Cost, exchange rates, history, and budgets

Cost is an estimate of what the observed tokens would cost at published API prices. It is **not** a Codex, Claude, Grok, ChatGPT, or Claude subscription charge.

- Choose USD or KRW in Settings.
- USD/KRW is checked once per Seoul calendar day through [Frankfurter](https://frankfurter.dev/) using its ECB provider.
- The applied rate and rate date are visible in Settings; weekends and holidays may use the latest earlier ECB rate.
- The versioned price catalog checks this repository once per day and rejects invalid schemas, unsafe prices, untrusted sources, and downgrades.
- Usage history samples aggregate quota, token, and estimated-cost fields every 15 minutes and retains them locally for 30 days.
- Monthly totals are reconstructed from observed cost changes, so they cover only periods recorded by the app.
- Optional budget notifications fire at 50%, 80%, and 100% when notifications are enabled.

Unknown models are left without a cost instead of being mapped to a guessed price. The bundled catalog follows the official [OpenAI model pricing](https://developers.openai.com/api/docs/models) and [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) pages.

## Settings

| Tab | Options |
| --- | --- |
| General | UI language, enabled providers, provider connections, menu-bar label, selected provider, compact mode, activity animation/window, launch at login, update check |
| Alerts | Low-usage notifications, warning and critical thresholds, provider selection, test notification |
| Usage | USD/KRW display, applied exchange rate, price-catalog update, monthly budget, usage-history window |
| Privacy | Local-data explanation and copyable provider diagnostics |

The UI language can follow the system or be set explicitly to English or Korean.

## Updates

The app checks GitHub Releases every six hours and displays a link when a newer stable version is available. Download and installation remain manual while releases are ad-hoc signed. Automatic in-app installation can be added later with Developer ID signing, notarization, and a signed update feed.

## Privacy and security

- No prompts or model responses are displayed or retained.
- Authentication tokens, refresh tokens, and cookies are never logged or copied into app storage.
- Claude credentials obtained after explicit approval are cached only in memory until expiry or app exit.
- Local parsing is limited to known aggregate usage fields and OpenCode aggregate database columns.
- Activity detection reads file metadata only, not prompt or response content.
- History contains only aggregate percentages, token totals, and estimated cost and is retained for 30 days.
- Exchange-rate and pricing caches contain only public data and validation metadata.
- Diagnostics exclude prompts, responses, credentials, cookies, provider detail text, and file paths.
- The app has no analytics or telemetry.

## Architecture and provider extension

```text
ProviderRegistry
    ├── CodexUsageProvider    ── account usage + ~/.codex/sessions
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
