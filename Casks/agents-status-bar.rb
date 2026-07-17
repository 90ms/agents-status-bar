cask "agents-status-bar" do
  version "0.1.0"
  sha256 "82b3fac9981841862380fbf007d9823af5779a186c00a3ea4573d266ac607b44"

  url "https://github.com/90ms/agents-status-bar/releases/download/v#{version}/AgentsStatusBar-#{version}.zip"
  name "Agents Status Bar"
  desc "Menu bar usage monitor for AI coding agents"
  homepage "https://github.com/90ms/agents-status-bar"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Agents Status Bar.app"

  zap trash: "~/Library/Preferences/dev.agentsstatusbar.app.plist"

  caveats <<~EOS
    This preview is ad-hoc signed. On first launch, macOS may require approval in
    System Settings > Privacy & Security.
  EOS
end
