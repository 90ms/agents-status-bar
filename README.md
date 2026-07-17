# Agents Status Bar

**English** | [한국어](README.ko.md)

A privacy-conscious macOS menu-bar app that shows how much usage remains across AI coding agents.

<p align="center">
  <img src="docs/agents-status-bar.png" width="400" alt="Agents Status Bar menu showing coding-agent usage" />
</p>

> The screenshot uses sample values and contains no account data.

## What it does

Agents Status Bar keeps the limits you care about in one small menu:

- remaining quota, reset time, and local token totals;
- API-price-equivalent token cost estimates in USD or KRW;
- observed cost history plus optional monthly budget progress and 50%, 80%, and 100% alerts;
- daily USD/KRW conversion with the applied ECB rate and rate date;
- 30-day local usage history with 1-day, 7-day, and 30-day charts;
- visible data source and last successful update time;
- configurable warning and critical alerts per provider;
- a customizable menu-bar label: icon only, lowest remaining, monthly estimated cost, or one provider's remaining usage;
- an optional compact popover that keeps quota essentials visible while hiding secondary detail rows;
- a six-hour GitHub Releases update check with a validated cache and stable-release link;
- Codex, Claude Code, Grok, Gemini CLI, and OpenCode support;
- one-minute refresh with a manual refresh button;
- optional launch at login;
- per-provider enable/disable settings;
- English and Korean UI with a System, English, or Korean language setting;
- tabbed settings for general options, alerts, usage, and privacy;
- a copyable provider diagnostics report that excludes prompts, responses, credentials, provider detail text, and file paths;
- a provider protocol that makes adding another agent independent from the UI.

All quota percentages are displayed as **remaining** values (`% left`). Account credentials are read only when a provider needs its official usage endpoint and are kept in memory. The app does not store prompts, responses, cookies, access tokens, or refresh tokens.

## Provider support

| Provider | Account quota | Local usage | Source |
| --- | --- | --- | --- |
| Codex | Weekly and model-specific limits | Latest session tokens | Existing Codex sign-in plus `~/.codex/sessions` |
| Claude Code | 5-hour, weekly, and model-scoped limits | Today's deduplicated tokens | Existing Claude Code Keychain sign-in plus `~/.claude/projects` |
| Grok | Not available yet | Current context usage | `~/.grok/sessions` |
| Gemini CLI | Not locally available | Latest session tokens | `~/.gemini/tmp/*/chats` |
| OpenCode | Not locally available | All-time aggregate tokens and recorded cost | Aggregate columns in `~/.local/share/opencode/opencode*.db` |

Provider CLI formats and usage endpoints are not public compatibility contracts and may change. When an account request fails, the app falls back to known local data instead of inventing a value.

## Cost estimates and exchange rates

Cost is an estimate of what the locally observed tokens would cost at published API prices. It is **not** the amount charged for a Codex, Claude, Grok, ChatGPT, or Claude subscription.

- Codex estimates cover the latest local session when its model can be identified.
- Claude estimates cover today's deduplicated local messages and account for input, 5-minute and 1-hour cache writes, cache reads, and output.
- Grok cost is not estimated yet because the local signal does not provide a billable input/output breakdown.
- Gemini CLI cost is not estimated yet; only its latest locally recorded token metadata is used.
- OpenCode displays the cost already aggregated in its local session database instead of repricing provider-specific models.
- Unknown models are left without a cost instead of being mapped to a guessed price.

Monthly totals are reconstructed from positive changes in the cumulative cost samples and scope resets. They include only usage observed while the app is running and recording history, so they remain estimates rather than billing records.

The versioned model-price catalog follows the official [OpenAI model pricing](https://developers.openai.com/api/docs/models) and [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) pages. The app checks this repository for a newer catalog once per day, rejects invalid schemas, downgrades, same-version changes, unsafe prices, and untrusted source domains, and retains bundled and validated-cache fallbacks. USD/KRW is checked once per Seoul calendar day through [Frankfurter](https://frankfurter.dev/) using its ECB provider. The settings screen shows the price-catalog version, applied exchange rate, and their effective dates; weekends and holidays may use the latest earlier ECB date.

App updates are discovered automatically through GitHub Releases, but downloading and installing a release remains manual. This keeps the ad-hoc signed build usable without a paid Apple Developer Program membership.

## Install

The `v0.3.1` preview requires macOS 14 or later and Apple silicon.

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

Download `AgentsStatusBar-0.3.1.zip` from [Releases](https://github.com/90ms/agents-status-bar/releases), unzip it, and move `Agents Status Bar.app` to `/Applications`.

This preview is ad-hoc signed because the project does not yet have an Apple Developer ID certificate. On first launch, macOS may require you to approve the app in **System Settings → Privacy & Security**. Developer ID signing and notarization are planned for a future release.

### Build from source

Requirements: macOS 14+, Swift 6.2+, and Apple Command Line Tools.

```bash
git clone https://github.com/90ms/agents-status-bar.git
cd agents-status-bar
./Scripts/test.sh
./Scripts/package_app.sh
open "dist/Agents Status Bar.app"
```

`Scripts/package_app.sh` uses ad-hoc signing by default. Set `APP_SIGN_IDENTITY` to use another local signing identity.

## Before opening the app

Sign in with the command-line agents you want to monitor:

```bash
codex
claude
grok
gemini
opencode
```

Only installed and signed-in providers can report usage. You can disable providers you do not use from Settings.

## Architecture

```text
ProviderRegistry
    ├── CodexUsageProvider  ── account usage + ~/.codex/sessions
    ├── ClaudeUsageProvider ── account usage + ~/.claude/projects
    ├── GrokUsageProvider   ── ~/.grok/sessions
    ├── GeminiUsageProvider ── ~/.gemini/tmp/*/chats
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

`ProviderID` is an open string-backed type rather than an enum. To add a platform, implement `UsageProviding`, keep its authentication and parsing inside a provider directory, add sanitized fixture tests, and register it with `ProviderRegistry`.

## Development

```bash
./Scripts/test.sh
swift build
./Scripts/package_app.sh
```

The project includes fixture-based parser tests and a macOS GitHub Actions build. See [AGENTS.md](AGENTS.md) for contribution conventions.

## Privacy and security

- No prompts or model responses are read for display or retained by the app.
- Authentication values are never logged or copied into app storage.
- Codex and Claude usage requests reuse their CLIs' existing sign-in sessions.
- Local parsing is restricted to known usage fields in agent session directories and OpenCode aggregate database columns.
- Usage history stores only aggregate percentages and token totals for 30 days in Application Support.
- The cached exchange-rate record contains only the public rate, publication date, and check time.
- The cached price catalog contains only public model identifiers, prices, effective dates, and official source links.
- The app has no analytics or telemetry.
- Diagnostics expose only sanitized app/OS metadata and aggregate provider status, quota, model, and token fields.

## License

[MIT](LICENSE)
