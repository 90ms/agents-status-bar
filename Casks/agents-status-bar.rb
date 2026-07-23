cask "agents-status-bar" do
  version "0.5.0"
  sha256 "04f8ba1473d70b6241a1aaa4ee0a7a4f1b34101d2931c31a7bd47d8eb1a3b88a"

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
