cask "agents-status-bar" do
  version "0.3.0"
  sha256 "21d28ca95f3a42123cb8bb9beba476f486cb377c91cc80e270786a6768f188cd"

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
