# Agents Status Bar

**English** | [한국어](README.ko.md)

A privacy-conscious macOS menu-bar app that shows how much usage remains across AI coding agents.

<p align="center">
  <img src="docs/agents-status-bar.png" width="400" alt="Agents Status Bar menu showing Codex, Claude Code, and Grok usage" />
</p>

> The screenshot uses sample values and contains no account data.

## What it does

Agents Status Bar keeps the limits you care about in one small menu:

- remaining quota, reset time, and local token totals;
- API-price-equivalent token cost estimates in USD or KRW;
- daily USD/KRW conversion with the applied ECB rate and rate date;
- 30-day local usage history with 1-day, 7-day, and 30-day charts;
- visible data source and last successful update time;
- configurable warning and critical alerts per provider;
- the lowest remaining value directly in the menu bar;
- Codex account, Claude Code, and Grok support;
- one-minute refresh with a manual refresh button;
- optional launch at login;
- per-provider enable/disable settings;
- English and Korean UI selected from the macOS language preference;
- a provider protocol that makes adding another agent independent from the UI.

All quota percentages are displayed as **remaining** values (`% left`). Account credentials are read only when a provider needs its official usage endpoint and are kept in memory. The app does not store prompts, responses, cookies, access tokens, or refresh tokens.

## Provider support

| Provider | Account quota | Local usage | Source |
| --- | --- | --- | --- |
| Codex | Weekly and model-specific limits | Latest session tokens | Existing Codex sign-in plus `~/.codex/sessions` |
| Claude Code | 5-hour, weekly, and model-scoped limits | Today's deduplicated tokens | Existing Claude Code Keychain sign-in plus `~/.claude/projects` |
| Grok | Not available yet | Current context usage | `~/.grok/sessions` |

Provider CLI formats and usage endpoints are not public compatibility contracts and may change. When an account request fails, the app falls back to known local data instead of inventing a value.

## Cost estimates and exchange rates

Cost is an estimate of what the locally observed tokens would cost at published API prices. It is **not** the amount charged for a Codex, Claude, Grok, ChatGPT, or Claude subscription.

- Codex estimates cover the latest local session when its model can be identified.
- Claude estimates cover today's deduplicated local messages and account for input, 5-minute and 1-hour cache writes, cache reads, and output.
- Grok cost is not estimated yet because the local signal does not provide a billable input/output breakdown.
- Unknown models are left without a cost instead of being mapped to a guessed price.

The bundled model prices follow the official [OpenAI model pricing](https://developers.openai.com/api/docs/models) and [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) pages. USD/KRW is checked once per Seoul calendar day through [Frankfurter](https://frankfurter.dev/) using its ECB provider. The settings screen shows both the applied rate and its publication date; weekends and holidays may therefore use the latest earlier ECB date.

## Install

The `v0.3.0` preview requires macOS 14 or later and Apple silicon.

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

Download `AgentsStatusBar-0.3.0.zip` from [Releases](https://github.com/90ms/agents-status-bar/releases), unzip it, and move `Agents Status Bar.app` to `/Applications`.

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
```

Only installed and signed-in providers can report usage. You can disable providers you do not use from Settings.

## Architecture

```text
ProviderRegistry
    ├── CodexUsageProvider  ── account usage + ~/.codex/sessions
    ├── ClaudeUsageProvider ── account usage + ~/.claude/projects
    └── GrokUsageProvider   ── ~/.grok/sessions
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
- Local parsing is restricted to known usage fields in agent session directories.
- Usage history stores only aggregate percentages and token totals for 30 days in Application Support.
- The cached exchange-rate record contains only the public rate, publication date, and check time.
- The app has no analytics or telemetry.

## License

[MIT](LICENSE)
