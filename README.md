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
- Codex account, Claude Code, and Grok support;
- one-minute refresh with a manual refresh button;
- per-provider enable/disable settings;
- a provider protocol that makes adding another agent independent from the UI.

All quota percentages are displayed as **remaining** values (`% left`). Account credentials are read only when a provider needs its official usage endpoint and are kept in memory. The app does not store prompts, responses, cookies, access tokens, or refresh tokens.

## Provider support

| Provider | Account quota | Local usage | Source |
| --- | --- | --- | --- |
| Codex | Weekly and model-specific limits | Latest session tokens | Existing Codex sign-in plus `~/.codex/sessions` |
| Claude Code | 5-hour, weekly, and model-scoped limits | Today's deduplicated tokens | Existing Claude Code Keychain sign-in plus `~/.claude/projects` |
| Grok | Not available yet | Current context usage | `~/.grok/sessions` |

Provider CLI formats and usage endpoints are not public compatibility contracts and may change. When an account request fails, the app falls back to known local data instead of inventing a value.

## Install

The `v0.1.0` preview requires macOS 14 or later and Apple silicon.

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

Download `AgentsStatusBar-0.1.0.zip` from [Releases](https://github.com/90ms/agents-status-bar/releases), unzip it, and move `Agents Status Bar.app` to `/Applications`.

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
- The app has no analytics or telemetry.

## License

[MIT](LICENSE)
